#!/bin/bash
# context-meter.sh - write a session's context usage where a hook can read it.
#
# The agent tells its status line how full the context window is, and tells
# nothing of the kind to its hooks. A hook that has to decide "is it time to
# hand over and start clean" therefore has no number to decide on. This script
# sits in front of the status line command: it reads the JSON the agent pipes
# in, saves the few numbers a hook needs to one small file per session, and
# then runs the real status line with the same input.
#
# Usage, as the status line command of the agent:
#   context-meter.sh [<status line command> [args...]]
# With no command it only writes the file and prints nothing.
#
# The file is $CONTEXT_METER_DIR/<session_id>.json (default
# ~/.ccgram/context/), mode 600, replaced atomically:
#   {"ts": <unix time>, "session_id": "...", "used_percentage": 18,
#    "tokens": 180000, "window_size": 1000000, "rate_5h": 7}
# A value the agent did not send is null. Before the first reply of a
# conversation used_percentage is null: read that as "unknown", never as
# "empty".
#
# Safety: it never fails the status line. A missing python3, an unwritable
# directory or input that is not JSON leave the file as it was and the status
# line still runs.
set -u

DIR="${CONTEXT_METER_DIR:-${CCGRAM_DIR:-$HOME/.ccgram}/context}"

input="$(cat)"

printf '%s' "$input" | python3 -c '
import json, os, re, sys, tempfile, time

data = json.load(sys.stdin)
sid = str(data.get("session_id") or "")
if not re.fullmatch(r"[A-Za-z0-9_-]{1,128}", sid):
    sys.exit(0)

ctx = data.get("context_window") or {}
pct = ctx.get("used_percentage")
size = ctx.get("context_window_size")

tokens = None
cur = ctx.get("current_usage")
if isinstance(cur, dict):
    total = sum(int(cur.get(k) or 0) for k in (
        "input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
    tokens = total or None
if tokens is None and pct is not None and size:
    tokens = int(float(pct) * int(size) / 100.0)

five = (data.get("rate_limits") or {}).get("five_hour") or {}

record = {
    "ts": int(time.time()),
    "session_id": sid,
    "used_percentage": pct,
    "tokens": tokens,
    "window_size": size,
    "rate_5h": five.get("used_percentage"),
}

out_dir = sys.argv[1]
os.makedirs(out_dir, mode=0o700, exist_ok=True)
fd, tmp = tempfile.mkstemp(dir=out_dir, prefix=".meter-")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(record, f)
        f.write("\n")
    os.replace(tmp, os.path.join(out_dir, sid + ".json"))
except BaseException:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
' "$DIR" >/dev/null 2>&1 || true

[ "$#" -gt 0 ] || exit 0
printf '%s' "$input" | "$@"
