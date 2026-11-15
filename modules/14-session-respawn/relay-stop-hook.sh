#!/bin/bash
# relay-stop-hook.sh - the Stop hook that keeps a relay run moving.
#
# The agent calls a Stop hook at the end of every turn and lets it refuse the
# stop with a reason, which the session then reads as its next instruction.
# This hook uses that for a session working through a plan (see relay.sh):
#
#   run is off                      -> says nothing, the turn ends as usual
#   a hand-over is already running  -> lets the turn end
#   the session declared a wait     -> lets this one turn end
#   a limit is used up              -> turns the run off, tells the session to
#                                      report it in one line
#   context below the soft limit    -> "take the next task of the plan"
#   between soft and hard           -> once: "finish the task, start no new
#                                      one"; then waits while background work
#                                      runs, and asks for the hand-over when
#                                      none is left
#   at or above the hard limit      -> "hand over now", without waiting
#
# It only reads its input and two small files and prints one JSON object. It
# presses nothing, starts nothing and sends nothing: a limit that fires is
# reported by the session itself, in its own chat.
#
# Install as a Stop hook of the agent, next to any hook already there:
#   "Stop": [{"hooks": [{"type": "command", "command": "relay-stop-hook.sh"}]}]
# It needs context-meter.sh as the status line command: the hook input says
# nothing about the context, the meter's file does.
#
# Limits it enforces (set by `relay.sh on`): hand-overs per run, pushes in a
# row without progress (neither a new commit nor a change in the plan file),
# the 5-hour and 7-day usage ceilings, and three requests to hand over that were not
# followed. A reading of the context that is missing or older than
# METER_MAX_AGE seconds stops the run too: without the number it cannot
# decide.
set -u

RELAY_DIR="${RELAY_DIR:-${CCGRAM_DIR:-$HOME/.ccgram}/relay}"
METER_DIR="${CONTEXT_METER_DIR:-${CCGRAM_DIR:-$HOME/.ccgram}/context}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The common case - no run is on anywhere - must cost nothing.
grep -qs '"on": true' "$RELAY_DIR"/*.json 2>/dev/null || exit 0

input="$(cat)"
exec 9>"$RELAY_DIR/.lock"
flock -w 5 9 || exit 0

printf '%s' "$input" | RELAY_DIR="$RELAY_DIR" METER_DIR="$METER_DIR" \
  RELAY_SH="$HERE/relay.sh" METER_MAX_AGE="${METER_MAX_AGE:-900}" \
  METER_TRIES="${METER_TRIES:-8}" python3 -c '
import glob, hashlib, json, os, subprocess, sys, tempfile, time

E = os.environ
d = E["RELAY_DIR"]
now = int(time.time())
MAX_NAGS = 3           # requests to hand over that may go unanswered
PENDING_MAX = 1200     # seconds a started hand-over is trusted to finish

try:
    inp = json.load(sys.stdin)
except ValueError:
    sys.exit(0)

# The run of this session: the state whose project holds the session cwd.
real = os.path.realpath
here = real(os.environ.get("CLAUDE_PROJECT_DIR") or inp.get("cwd") or os.getcwd())
# A session inside a repository of its own, nested under the run directory
# (a workspace that holds several projects), is not part of that run.
top = []
def nested(root):
    if not top:
        try:
            r = subprocess.run(["git", "-C", here, "rev-parse", "--show-toplevel"],
                               capture_output=True, text=True, timeout=5)
            top.append(real(r.stdout.strip()) if r.returncode == 0 and r.stdout.strip() else None)
        except (OSError, subprocess.SubprocessError):
            top.append(None)
    t = top[0]
    return bool(t) and t.startswith(root.rstrip("/") + "/")

path = s = None
for p in glob.glob(os.path.join(d, "*.json")):
    try:
        with open(p) as f:
            x = json.load(f)
    except (OSError, ValueError):
        continue
    root = x.get("cwd") if isinstance(x, dict) else None
    if not root or not x.get("on"):
        continue
    if here == root or (here.startswith(root.rstrip("/") + "/") and not nested(root)):
        if s is None or len(root) > len(s["cwd"]):
            path, s = p, x
if s is None:
    sys.exit(0)

def save():
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".relay-")
    with os.fdopen(fd, "w") as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)

def log(text):
    with open(os.open(os.path.join(d, "relay.log"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600), "w") as f:
        f.write("[{}] {}: hook: {}\n".format(time.strftime("%F %T"), os.path.basename(s["cwd"]), text))

def allow(why):
    save(); log("let the turn end - " + why)
    sys.exit(0)

def block(why, text):
    save(); log(why)
    print(json.dumps({"decision": "block", "reason": text}))
    sys.exit(0)

def stop_run(why):
    s.update(on=False, stopped_at=now, stopped_reason=why, wait=False,
             wait_reason=None, bg_wait_since=None)
    block("run stopped - " + why,
          "Relay: the run is stopped - {}. Tell the user that in one line and end "
          "your turn. Do not continue the plan.".format(why))

relay_sh = E["RELAY_SH"]
plan = s.get("plan")
handover = s.get("handover") or "/next"

# 1. A hand-over is on its way: nothing to add until the conversation is new.
pending = s.get("reset_pending_since")
if pending and now - int(pending) < PENDING_MAX:
    allow("a hand-over is running")
s["reset_pending_since"] = None

# 2. The reading of the context and of the usage limits.
sid = str(inp.get("session_id") or "")
def reading():
    if not sid or not all(c.isalnum() or c in "_-" for c in sid):
        return None
    try:
        with open(os.path.join(E["METER_DIR"], sid + ".json")) as f:
            m = json.load(f)
    except (OSError, ValueError):
        return None
    if not isinstance(m, dict) or now - int(m.get("ts") or 0) > int(E["METER_MAX_AGE"]):
        return None
    return m if m.get("used_percentage") is not None else None

# The status line is redrawn a moment after the reply: on a one-reply turn the
# hook can run first, so a missing reading gets a few seconds to appear.
meter = reading()
for _ in range(int(E["METER_TRIES"])):
    if meter is not None:
        break
    time.sleep(0.5)
    meter = reading()
pct = meter.get("used_percentage") if meter else None
rate = meter.get("rate_5h") if meter else None
week = meter.get("rate_7d") if meter else None

if rate is not None and float(rate) > s.get("rate_5h_max", 85):
    stop_run("the 5-hour usage is at {:.0f}%, above the limit of {}%".format(float(rate), s.get("rate_5h_max")))
# A run started before the weekly ceiling existed has none.
if week is not None and s.get("rate_7d_max") is not None and float(week) > s["rate_7d_max"]:
    stop_run("the 7-day usage is at {:.0f}%, above the limit of {}%".format(float(week), s["rate_7d_max"]))

# 3. The session asked something and waits: one turn passes without a push.
if s.get("wait"):
    s.update(wait=False, wait_reason=None)
    allow("the session is waiting for an answer")

if pct is None:
    stop_run("the context usage is unknown (no fresh reading - is context-meter.sh the status line command?)")
pct = float(pct)

running = [t for t in (inp.get("background_tasks") or []) if isinstance(t, dict) and t.get("status", "running") == "running"]
crons = [c for c in (inp.get("session_crons") or []) if isinstance(c, dict)]

def survivors():
    items = ["background {}: {}".format(t.get("type") or "task", t.get("description") or t.get("command") or t.get("id")) for t in running]
    items += ["scheduled {}: {}".format(c.get("schedule") or "", (c.get("prompt") or "")[:80]) for c in crons]
    if not items:
        return ""
    return (" Still running and surviving the reset - list them in the handoff, the next "
            "conversation must not start them again: " + "; ".join(items) + ".")

def ask_handover(lead):
    if s.get("resets", 0) >= s.get("max_resets", 6):
        stop_run("the context is at {:.0f}% and all {} hand-overs of this run are used".format(pct, s.get("max_resets")))
    if s.get("nags", 0) >= MAX_NAGS:
        stop_run("the hand-over was asked for {} times and did not start".format(MAX_NAGS))
    s["nags"] = s.get("nags", 0) + 1
    block("asked for the hand-over at {:.0f}%".format(pct),
          "Relay: {} Hand over now: run {} with a note that the relay run continues from "
          "the plan {}.{}".format(lead, handover, plan, survivors()))

# 4. At or above the hard limit: hand over, whatever is running.
if pct >= s.get("hard_pct", 45):
    ask_handover("the context is at {:.0f}% (hard limit {}%), do not wait for anything.".format(pct, s.get("hard_pct")))

# 5. Between the limits: finish, wait for background work, hand over.
if pct >= s.get("soft_pct", 35):
    if not s.get("soft_told"):
        s["soft_told"] = True
        block("soft limit reached at {:.0f}%".format(pct),
              "Relay: the context is at {:.0f}% (soft limit {}%). Do not start a new task. If the "
              "current task is unfinished, finish it now: its check, a commit, a mark in the plan. "
              "Then end your turn.".format(pct, s.get("soft_pct")))
    if running:
        if not s.get("bg_wait_since"):
            s["bg_wait_since"] = now
        waited = (now - int(s["bg_wait_since"])) // 60
        if waited >= s.get("bg_wait_min", 30):
            ask_handover("background work has been running for {} min, past the limit of {} min.".format(waited, s.get("bg_wait_min")))
        allow("waiting for background work ({} running, {} min)".format(len(running), waited))
    s["bg_wait_since"] = None
    ask_handover("the context is at {:.0f}% and no background work is left.".format(pct))

# 6. Below the soft limit: the next task, unless the run is spinning.
s.update(bg_wait_since=None, soft_told=False, nags=0)
head = ""
try:
    head = subprocess.run(["git", "-C", s["cwd"], "rev-parse", "HEAD"], capture_output=True, text=True, timeout=5).stdout.strip()
except (OSError, subprocess.SubprocessError):
    pass
try:
    with open(plan, "rb") as f:
        plan_sig = hashlib.sha1(f.read()).hexdigest()
except (OSError, TypeError):
    stop_run("the plan file {} cannot be read".format(plan))
progress = head + ":" + plan_sig
if s.get("progress") is None or s.get("progress") != progress:
    s.update(progress=progress, stalls=0)
else:
    s["stalls"] = s.get("stalls", 0) + 1
    if s["stalls"] >= s.get("max_stalls", 2):
        stop_run("{} pushes in a row changed neither the commit nor the plan file".format(s["stalls"]))

block("pushed to the next task at {:.0f}%".format(pct),
      "Relay: the run is on, plan {}. Take the next unfinished task of the plan and do it in "
      "this turn: one task, its check, a commit, a mark in the plan. If the plan is finished, "
      "run `{} off --reason \"plan finished\"` and say so. If you need an answer from the user, "
      "run `{} wait --reason \"<what you asked>\"`, ask, and end your turn. Do not wait in the "
      "background for a CI run or another long outside job to finish: put its id in the plan "
      "and check it at a later task. Scheduled checks are fine.".format(plan, relay_sh, relay_sh))
' 2>>"$RELAY_DIR/relay-hook.err"
exit 0
