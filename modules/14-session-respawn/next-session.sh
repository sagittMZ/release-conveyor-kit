#!/bin/bash
# next-session.sh - clear a bridged agent session and hand it its kickoff line.
#
# The routine after a handoff is always the same: wait for the session to
# finish, type /clear, wait again, type "read <rules file> and <session
# prompt>". From a chat that is three messages and two waits per session. This
# script does the routine for one window: it waits until the agent is idle,
# clears the conversation, types the window's kickoff line from the manifest
# and makes sure the bridge follows the new session.
#
# A session cannot clear itself, so the script is meant to be started DETACHED
# by the session as the last action of its turn (for example with
# `systemd-run --user --collect`), or by hand for any window.
#
# Usage: next-session.sh (--window NAME | --cwd DIR) [--kickoff TEXT]
#                        [--dry-run]
#   --window NAME   the tmux window (= manifest entry) to reset
#   --cwd DIR       find the window by its project directory instead
#   --kickoff TEXT  use this line instead of the manifest's "kickoff"
#   --dry-run       print the plan, press nothing
#
# Safety: one run per window at a time (flock); text is always typed before
# Enter, never a bare Enter; refuses to start when the window has no agent
# running, has no kickoff line, or stays busy past the timeout.
set -euo pipefail

CCGRAM_DIR="${CCGRAM_DIR:-$HOME/.ccgram}"
MANIFEST="${RESPAWN_MANIFEST:-$CCGRAM_DIR/respawn-manifest.json}"
SESSION_MAP="$CCGRAM_DIR/session_map.json"
LOG="${NEXT_SESSION_LOG:-$CCGRAM_DIR/next-session.log}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# What the TUI shows near the input box while a turn is running: the spinner
# line ("<glyph> <Verb>… (<time> ..."), or the older "esc to interrupt" hint.
BUSY_RX='^[^[:alnum:][:space:]] [[:alpha:]]+… \(|esc to interrupt'
BUSY_LINES=12                # look only this close to the bottom of the pane
IDLE_CHECKS=3                # consecutive idle looks, 2s apart, to call it idle
IDLE_TIMEOUT=900             # seconds to wait for the turn to end
DELIVER_WAIT=15              # seconds for the bridge to deliver the last reply
CLEAR_WAIT=5                 # seconds for the TUI to redraw after /clear
MAP_WAIT=30                  # seconds for the new transcript to appear

WINDOW=""; CWD=""; KICKOFF=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --window) WINDOW="${2:?--window needs a name}"; shift 2 ;;
    --cwd) CWD="${2:?--cwd needs a directory}"; shift 2 ;;
    --kickoff) KICKOFF="${2:?--kickoff needs a line}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$WINDOW" ] || [ -n "$CWD" ] || { echo "give --window or --cwd" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "no manifest: $MANIFEST" >&2; exit 1; }

log() { echo "[$(date '+%F %T')] ${WINDOW:-?}: $*" | tee -a "$LOG"; }

# The manifest entry: tmux session, window name, cwd, config dir, kickoff.
entry="$(python3 - "$MANIFEST" "$WINDOW" "$CWD" <<'PY'
import json, os, sys
m = json.load(open(sys.argv[1])); name, cwd = sys.argv[2], sys.argv[3]
real = lambda p: os.path.realpath(os.path.expanduser(p))
hit = None
for w in m.get("windows", []):
    if (name and w.get("name") == name) or (not name and cwd and real(w.get("cwd", "")) == real(cwd)):
        hit = w; break
if hit is None:
    sys.exit(1)
print(m.get("tmux_session") or "ccgram")
print(hit["name"])
print(real(hit["cwd"]))
print(real(hit.get("config_dir") or "~/.claude"))
print(hit.get("kickoff", ""))
PY
)" || { echo "no manifest entry for window='${WINDOW}' cwd='${CWD}'" >&2; exit 1; }
{ read -r SESSION; read -r WINDOW; read -r W_CWD; read -r W_CFG; read -r M_KICK || true; } <<<"$entry"
KICKOFF="${KICKOFF:-$M_KICK}"
[ -n "$KICKOFF" ] || { echo "window $WINDOW has no \"kickoff\" line in the manifest (or pass --kickoff)" >&2; exit 1; }

ID="$(tmux list-windows -t "$SESSION" -F '#{window_id}	#{window_name}' 2>/dev/null | awk -F'\t' -v n="$WINDOW" '$2 == n { print $1; exit }')"
[ -n "$ID" ] || { echo "no tmux window named $WINDOW in session $SESSION" >&2; exit 1; }
T="$SESSION:$ID"

pane() { tmux capture-pane -p -t "$T"; }
agent_running() { [ "$(tmux display-message -p -t "$T" '#{pane_current_command}')" != "bash" ] && pane | grep -q '^❯'; }
busy() {
  pane | awk '{ l[NR] = $0 } /[^[:space:]]/ { last = NR } END { for (i = 1; i <= last; i++) print l[i] }' \
    | tail -n "$BUSY_LINES" | grep -qiE "$BUSY_RX"
}
wait_idle() {  # wait_idle <timeout seconds> -> 0 when idle for IDLE_CHECKS looks in a row
  local deadline=$(( $(date +%s) + $1 )) calm=0
  while [ "$(date +%s)" -lt "$deadline" ]; do
    if busy; then calm=0; else calm=$((calm + 1)); fi
    [ "$calm" -ge "$IDLE_CHECKS" ] && return 0
    sleep 2
  done
  return 1
}
type_line() { tmux send-keys -t "$T" C-u; tmux send-keys -t "$T" -l -- "$1"; sleep 0.5; tmux send-keys -t "$T" Enter; }
newest_transcript() {  # newest top-level transcript of the window's project, with its mtime
  local dir
  dir="$W_CFG/projects/$(printf '%s' "$W_CWD" | sed 's|/|-|g')"
  find "$dir" -maxdepth 1 -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n 1
}

if [ "$DRY" = 1 ]; then
  echo "plan $WINDOW ($T, cwd $W_CWD):"
  echo "  1. wait until idle (up to ${IDLE_TIMEOUT}s), then ${DELIVER_WAIT}s for the last reply to be delivered"
  echo "  2. type: /clear"
  echo "  3. type: $KICKOFF"
  echo "  4. point the bridge's session map at the new transcript if it did not follow"
  agent_running && echo "  agent: running, $(busy && echo busy || echo idle)" || echo "  agent: NOT running - a real run would refuse"
  exit 0
fi

exec 9>"$CCGRAM_DIR/next-session.$WINDOW.lock"
flock -n 9 || { echo "another next-session run is active for $WINDOW" >&2; exit 1; }

log "=== requested (kickoff: $KICKOFF)"
agent_running || { log "refused: no agent prompt in the window"; exit 1; }
sleep 5   # the calling turn is still printing its last line
wait_idle "$IDLE_TIMEOUT" || { log "refused: still busy after ${IDLE_TIMEOUT}s"; exit 1; }
sleep "$DELIVER_WAIT"
wait_idle 120 || { log "refused: busy again after the delivery wait"; exit 1; }

# a card on screen would swallow nothing but hide the result; fold it away first
[ -x "$HERE/dismiss-cards.sh" ] && "$HERE/dismiss-cards.sh" --only "$WINDOW" >>"$LOG" 2>&1 || true

before="$(newest_transcript | cut -d' ' -f2-)"
stamp="$(date +%s)"
type_line "/clear"
sleep "$CLEAR_WAIT"
wait_idle 60 || { log "stopped: the window is busy after /clear, kickoff NOT typed"; exit 1; }
log "cleared"
type_line "$KICKOFF"
log "kickoff typed"

# The bridge follows a new session through the agent's hooks. When the hook is
# lost, replies stop reaching the chat: point the session map at the new
# transcript by hand, the way the bridge would have.
new=""
for ((i = 0; i < MAP_WAIT; i += 2)); do
  read -r mtime path < <(newest_transcript) || true
  if [ -n "${path:-}" ] && [ "$path" != "$before" ] && [ "${mtime%.*}" -ge "$stamp" ]; then new="$path"; break; fi
  sleep 2
done
if [ -z "$new" ]; then
  log "WARN: no new transcript within ${MAP_WAIT}s - check that the session answers in the chat"
  exit 0
fi
sleep 3   # give the hook its chance first
fix="$(flock "$CCGRAM_DIR/session_map.lock" python3 - "$SESSION_MAP" "$SESSION:$ID" "$new" <<'PY'
import json, os, sys
p, key, path = sys.argv[1:4]
sid = os.path.basename(path)[:-len(".jsonl")]
try:
    m = json.load(open(p))
except Exception:
    print("session map unreadable"); sys.exit(0)
e = m.get(key)
if not isinstance(e, dict):
    print("no entry for " + key); sys.exit(0)
if e.get("session_id") == sid:
    print("followed by the hook"); sys.exit(0)
e["session_id"], e["transcript_path"] = sid, path
tmp = p + ".tmp"
json.dump(m, open(tmp, "w"), indent=2); os.replace(tmp, p)
print("repaired -> " + sid[:8])
PY
)"
log "session map: $fix"
log "done"
