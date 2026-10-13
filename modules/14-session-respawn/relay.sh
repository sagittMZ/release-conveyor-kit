#!/bin/bash
# relay.sh - the switch and the state of a relay run for one project.
#
# A relay run is a session working through a plan of several tasks on its own:
# at the end of every turn a hook either pushes it to the next task or, when
# the context has filled up, makes it hand over and start clean. This script
# is the part a person (or the session, when it needs an answer) talks to: it
# turns a run on and off and shows where it stands. It presses nothing and
# talks to no session; the hooks read the file it keeps.
#
# Usage: relay.sh on --plan FILE [options]
#        relay.sh off [--reason TEXT]
#        relay.sh wait [--reason TEXT]
#        relay.sh status [--all] [--json]
#   on      start a run for the project. Refuses when one is already on:
#           the counters of a run are never reset from inside it.
#   off     stop the run. The state stays on disk for `status`.
#   wait    the session has asked something and waits for the answer: the
#           next end of turn is let through without a push, once.
#   status  the run of this project, or of every project with --all.
#
# Options for every subcommand:
#   --cwd DIR         the project (default: the git top level, else the
#                     current directory). One run per project directory.
# Options for `on`:
#   --plan FILE       the plan the session works through (required)
#   --soft N          context %, from which no new task is started: the
#                     session finishes, waits for background work, hands over
#                     (default 35)
#   --hard N          context %, from which it hands over without waiting
#                     (default 45)
#   --max-resets N    hand-overs allowed in one run, 1-50 (default 6)
#   --max-stalls N    pushes in a row without a new commit before the run
#                     stops, 1-10 (default 2)
#   --rate-max N      5-hour usage %, above which the run stops (default 85)
#   --bg-wait MIN     minutes to wait for background work before asking a
#                     person, 1-1440 (default 30)
#
# State: $RELAY_DIR/<project>-<hash>.json (default ~/.ccgram/relay/), mode
# 600, replaced atomically under a lock. Log: $RELAY_DIR/relay.log.
#
# Safety: a ceiling on hand-overs is always set and cannot be zero; `on` does
# not replace a run that is already on.
set -euo pipefail

RELAY_DIR="${RELAY_DIR:-${CCGRAM_DIR:-$HOME/.ccgram}/relay}"

usage() { sed -n '2,43p' "$0" | sed 's/^# \{0,1\}//'; }

CMD="${1:-}"
case "$CMD" in
  on|off|wait|status) shift ;;
  -h|--help|"") usage; [ -n "$CMD" ] && exit 0 || exit 2 ;;
  *) echo "unknown command: $CMD (on, off, wait, status)" >&2; exit 2 ;;
esac

CWD=""; PLAN=""; REASON=""; ALL=0; JSON=0
SOFT=35; HARD=45; MAX_RESETS=6; MAX_STALLS=2; RATE_MAX=85; BG_WAIT=30
only() {  # only <option> <subcommand>... - the option belongs to these subcommands
  local opt="$1" c; shift
  for c in "$@"; do [ "$c" = "$CMD" ] && return 0; done
  echo "$opt does not go with '$CMD'" >&2; exit 2
}
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) CWD="${2:?--cwd needs a directory}"; shift 2 ;;
    --plan) only "$1" on; PLAN="${2:?--plan needs a file}"; shift 2 ;;
    --soft) only "$1" on; SOFT="${2:?--soft needs a number}"; shift 2 ;;
    --hard) only "$1" on; HARD="${2:?--hard needs a number}"; shift 2 ;;
    --max-resets) only "$1" on; MAX_RESETS="${2:?--max-resets needs a number}"; shift 2 ;;
    --max-stalls) only "$1" on; MAX_STALLS="${2:?--max-stalls needs a number}"; shift 2 ;;
    --rate-max) only "$1" on; RATE_MAX="${2:?--rate-max needs a number}"; shift 2 ;;
    --bg-wait) only "$1" on; BG_WAIT="${2:?--bg-wait needs a number}"; shift 2 ;;
    --reason) only "$1" off wait; REASON="${2:?--reason needs a text}"; shift 2 ;;
    --all) only "$1" status; ALL=1; shift ;;
    --json) only "$1" status; JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$CWD" ]; then
  CWD="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
[ -d "$CWD" ] || { echo "no such directory: $CWD" >&2; exit 1; }
CWD="$(cd "$CWD" && pwd -P)"

num() {  # num <name> <value> <min> <max>
  case "$2" in ''|*[!0-9]*) echo "$1 must be a whole number, got '$2'" >&2; exit 2 ;; esac
  if [ "$2" -lt "$3" ] || [ "$2" -gt "$4" ]; then
    echo "$1 must be between $3 and $4, got $2" >&2; exit 2
  fi
}
HEAD_SHA=""
if [ "$CMD" = on ]; then
  [ -n "$PLAN" ] || { echo "on needs --plan FILE" >&2; exit 2; }
  [ -f "$PLAN" ] || { echo "no such plan file: $PLAN" >&2; exit 1; }
  PLAN="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
  num --soft "$SOFT" 1 98
  num --hard "$HARD" 2 99
  [ "$SOFT" -lt "$HARD" ] || { echo "--soft ($SOFT) must be below --hard ($HARD)" >&2; exit 2; }
  num --max-resets "$MAX_RESETS" 1 50
  num --max-stalls "$MAX_STALLS" 1 10
  num --rate-max "$RATE_MAX" 1 100
  num --bg-wait "$BG_WAIT" 1 1440
  HEAD_SHA="$(git -C "$CWD" rev-parse HEAD 2>/dev/null || true)"
fi

( umask 077; mkdir -p "$RELAY_DIR" )
exec 9>"$RELAY_DIR/.lock"
flock -w 10 9 || { echo "the relay state is locked by another run" >&2; exit 1; }

RELAY_DIR="$RELAY_DIR" CMD="$CMD" CWD="$CWD" PLAN="$PLAN" REASON="$REASON" \
ALL="$ALL" JSON="$JSON" SOFT="$SOFT" HARD="$HARD" MAX_RESETS="$MAX_RESETS" \
MAX_STALLS="$MAX_STALLS" RATE_MAX="$RATE_MAX" BG_WAIT="$BG_WAIT" \
HEAD_SHA="$HEAD_SHA" python3 - <<'PY'
import glob, hashlib, json, os, sys, tempfile, time

E = os.environ
d, cmd, cwd = E["RELAY_DIR"], E["CMD"], E["CWD"]
name = "{}-{}.json".format(
    "".join(c if c.isalnum() or c in "._-" else "_" for c in os.path.basename(cwd)) or "root",
    hashlib.sha1(cwd.encode()).hexdigest()[:8])
path = os.path.join(d, name)
now = int(time.time())

def load(p):
    try:
        with open(p) as f:
            s = json.load(f)
        return s if isinstance(s, dict) else None
    except (OSError, ValueError):
        return None

def save(s):
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".relay-")
    with os.fdopen(fd, "w") as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)

def log(text):
    with open(os.open(os.path.join(d, "relay.log"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600), "w") as f:
        f.write("[{}] {}: {}\n".format(time.strftime("%F %T"), os.path.basename(cwd), text))

def show(s):
    if not s:
        print("relay: never run for {}".format(cwd)); return
    if s.get("on"):
        head = "relay: ON for {}".format(s["cwd"])
    else:
        head = "relay: off for {} ({})".format(s["cwd"], s.get("stopped_reason") or "no reason recorded")
    print(head)
    print("  plan: {}".format(s.get("plan")))
    print("  hand over from {}% of the context (soft), without waiting from {}% (hard)".format(s.get("soft_pct"), s.get("hard_pct")))
    print("  hand-overs: {} of {}".format(s.get("resets", 0), s.get("max_resets")))
    print("  pushes without a new commit: {} of {}".format(s.get("stalls", 0), s.get("max_stalls")))
    print("  stops above {}% of the 5-hour limit; waits for background work up to {} min".format(s.get("rate_5h_max"), s.get("bg_wait_min")))
    if s.get("on") and s.get("wait"):
        print("  waiting for an answer: the next end of turn is not pushed ({})".format(s.get("wait_reason") or "no reason given"))
    if s.get("on") and s.get("bg_wait_since"):
        print("  waiting for background work for {} min".format((now - int(s["bg_wait_since"])) // 60))

s = load(path)

if cmd == "status":
    if E["ALL"] == "1":
        states = [x for x in (load(p) for p in sorted(glob.glob(os.path.join(d, "*.json")))) if x]
        if E["JSON"] == "1":
            print(json.dumps(states, indent=2, ensure_ascii=False))
        elif not states:
            print("relay: no runs recorded in {}".format(d))
        else:
            for x in states:
                show(x)
    elif E["JSON"] == "1":
        print(json.dumps(s or {}, indent=2, ensure_ascii=False))
    else:
        show(s)
    sys.exit(0)

if cmd == "on":
    if s and s.get("on"):
        sys.stderr.write("relay is already on for {} (plan {}). Turn it off first: the counters of a run are not reset from inside it.\n".format(cwd, s.get("plan")))
        sys.exit(1)
    s = {
        "on": True, "cwd": cwd, "plan": E["PLAN"],
        "soft_pct": int(E["SOFT"]), "hard_pct": int(E["HARD"]),
        "max_resets": int(E["MAX_RESETS"]), "resets": 0,
        "max_stalls": int(E["MAX_STALLS"]), "stalls": 0,
        "last_head": E["HEAD_SHA"] or None,
        "rate_5h_max": int(E["RATE_MAX"]),
        "bg_wait_min": int(E["BG_WAIT"]), "bg_wait_since": None,
        "wait": False, "wait_reason": None,
        "started_at": now, "stopped_at": None, "stopped_reason": None,
    }
    save(s); log("on, plan {}, soft {}% hard {}%, max resets {}".format(s["plan"], s["soft_pct"], s["hard_pct"], s["max_resets"]))
    show(s); sys.exit(0)

if not s or not s.get("on"):
    print("relay is not on for {}".format(cwd))
    sys.exit(0 if cmd == "off" else 1)

if cmd == "off":
    s.update(on=False, stopped_at=now, stopped_reason=E["REASON"] or "switched off",
             wait=False, wait_reason=None, bg_wait_since=None)
    save(s); log("off: {}".format(s["stopped_reason"]))
    show(s)
elif cmd == "wait":
    s.update(wait=True, wait_reason=E["REASON"] or None)
    save(s); log("wait: {}".format(s["wait_reason"] or "no reason given"))
    show(s)
PY
