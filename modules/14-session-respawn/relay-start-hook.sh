#!/bin/bash
# relay-start-hook.sh - the SessionStart hook that carries a relay run across a
# reset.
#
# A hand-over ends with /clear: the new conversation knows nothing of the plan
# until the kickoff line has it read the handoff. This hook closes that gap.
# When the agent starts a conversation after /clear and a relay run is on for
# the project, the hook adds the run to the new conversation's context: the
# plan, the rules of a relay turn, the limits and where the open reviews and
# the background work that survived the reset are written down. The kickoff
# line stays what it was; it only starts the first turn.
#
# It also counts the hand-over. next-session.sh marks one as started before it
# types /clear (relay.sh reset --stage start); the hook sees the mark, counts
# the hand-over and takes the mark away. A /clear typed by a person carries no
# mark: it is not counted, and the new conversation is told the run is still
# on, so it can be switched off if that was the point.
#
#   source is not "clear"     -> says nothing
#   no run for this project   -> says nothing
#   the hand-over mark is set -> counts it, adds the run to the context
#   no mark                   -> adds the run to the context, counts nothing
#
# It reads its input and the run's state, writes the state and prints one JSON
# object. It presses nothing and sends nothing.
#
# Install as a SessionStart hook of the agent, next to any hook already there:
#   "SessionStart": [{"matcher": "clear",
#                     "hooks": [{"type": "command", "command": "relay-start-hook.sh"}]}]
set -u

RELAY_DIR="${RELAY_DIR:-${CCGRAM_DIR:-$HOME/.ccgram}/relay}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The common case - no run is on anywhere - must cost nothing.
grep -qs '"on": true' "$RELAY_DIR"/*.json 2>/dev/null || exit 0

input="$(cat)"
exec 9>"$RELAY_DIR/.lock"
flock -w 5 9 || exit 0

printf '%s' "$input" | RELAY_DIR="$RELAY_DIR" RELAY_SH="$HERE/relay.sh" python3 -c '
import glob, json, os, sys, tempfile, time

E = os.environ
d = E["RELAY_DIR"]
now = int(time.time())
PENDING_MAX = 1200     # seconds a started hand-over is trusted to finish (as in the Stop hook)

try:
    inp = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
if not isinstance(inp, dict) or inp.get("source") != "clear":
    sys.exit(0)

# The run of this session: the state whose project holds the session cwd.
real = os.path.realpath
here = real(os.environ.get("CLAUDE_PROJECT_DIR") or inp.get("cwd") or os.getcwd())
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
    if here == root or here.startswith(root.rstrip("/") + "/"):
        if s is None or len(root) > len(s["cwd"]):
            path, s = p, x
if s is None:
    sys.exit(0)

pending = s.get("reset_pending_since")
handover = bool(pending) and now - int(pending) < PENDING_MAX
if handover:
    s["resets"] = s.get("resets", 0) + 1
s["reset_pending_since"] = None

fd, tmp = tempfile.mkstemp(dir=d, prefix=".relay-")
with os.fdopen(fd, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
with open(os.open(os.path.join(d, "relay.log"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600), "w") as f:
    f.write("[{}] {}: start hook: {}\n".format(
        time.strftime("%F %T"), os.path.basename(s["cwd"]),
        "new conversation after hand-over {} of {}".format(s["resets"], s.get("max_resets"))
        if handover else "conversation cleared outside a hand-over, not counted"))

relay_sh = E["RELAY_SH"]
if handover:
    lead = ("Relay: this conversation continues a relay run for {} after hand-over {} of {}."
            .format(s["cwd"], s["resets"], s.get("max_resets")))
else:
    lead = ("Relay: a relay run is on for {} and this conversation was cleared outside a "
            "hand-over. If that was meant to stop the run, run `{} off --reason \"cleared by "
            "the user\"` and say so.".format(s["cwd"], relay_sh))
text = (lead + " The plan is {plan}. First do what the kickoff line asks, if one comes, and "
        "read the handoff it leads to: reviews still open and background work still running are written there - "
        "carry them on, and do not start the background work again, it survived the reset. "
        "Then work through the plan: one task per turn - its check, a commit, a mark in the "
        "plan. Nothing goes outward under relay: a push, a publication or a message still needs "
        "the user\x27s word. At the end of every turn a hook says what comes next: from {soft}% of the "
        "context start no new task, at {hard}% hand over with {handover}. To ask the user "
        "something, run `{sh} wait --reason \"<what you asked>\"`, ask, and end your turn. "
        "When the plan is finished, run `{sh} off --reason \"plan finished\"` and say so.").format(
            plan=s.get("plan"), soft=s.get("soft_pct", 35), hard=s.get("hard_pct", 45),
            handover=s.get("handover") or "/next", sh=relay_sh)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": text}}))
' 2>>"$RELAY_DIR/relay-hook.err"
exit 0
