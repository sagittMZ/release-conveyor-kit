#!/bin/bash
# dismiss-cards.sh - close the cards an agent TUI raises that can only be
# answered from the keyboard.
#
# A session driven through a chat bridge has nobody at its keyboard. When the
# TUI shows a card that waits for a key press, the card stays there and covers
# the status line. This script looks at every window of the bridge's tmux
# session, recognises such a card by its frame and sends the key that dismisses
# it. Dismissing never sends anything anywhere.
#
# Usage: dismiss-cards.sh [--dry-run] [--only NAME]...
#   --dry-run    report what would be dismissed, press nothing
#   --only NAME  look at this window only (repeatable)
#
# Safety: presses one key per card and never Enter; a card is recognised only
# by its framed lines near the bottom of the pane, so the same words quoted in
# a conversation do not match; if the key lands in the input line instead of
# the card, it is erased again.
set -euo pipefail

CCGRAM_DIR="${CCGRAM_DIR:-$HOME/.ccgram}"
MANIFEST="${RESPAWN_MANIFEST:-$CCGRAM_DIR/respawn-manifest.json}"
TAIL_LINES=14   # a card sits right above the input box; look no further up
SETTLE=1        # seconds for the TUI to redraw after the key

# Known cards: name | regex of the framed title line | regex of the framed key
# line | the key that dismisses. Add a row only for a card seen for real.
CARDS=(
  'feedback-draft|^│ .*[Dd]rafted: |^│ 1 to review · 2 to send · 0 to dismiss *│?$|0'
)

DRY=0; ONLY=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --only) ONLY+=("${2:?--only needs a window name}"); shift 2 ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

SESSION="${TMUX_SESSION_NAME:-}"
if [ -z "$SESSION" ] && [ -f "$MANIFEST" ]; then
  SESSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("tmux_session",""))' "$MANIFEST" 2>/dev/null || true)"
fi
SESSION="${SESSION:-ccgram}"
tmux has-session -t "$SESSION" 2>/dev/null || { echo "no tmux session: $SESSION" >&2; exit 1; }

selected() {  # selected <name> -> 0 when the window is to be looked at
  [ ${#ONLY[@]} -eq 0 ] && return 0
  local n; for n in "${ONLY[@]}"; do [ "$n" = "$1" ] && return 0; done
  return 1
}
pane_tail() {  # the last lines that carry text; a pane that is not full ends in blanks
  tmux capture-pane -p -t "$SESSION:$1" \
    | awk '{ l[NR] = $0 } /[^[:space:]]/ { last = NR } END { for (i = 1; i <= last; i++) print l[i] }' \
    | tail -n "$TAIL_LINES"
}
input_line() { pane_tail "$1" | grep -E '^❯' | tail -n 1 || true; }
card_in() {  # card_in <pane text> <title regex> <key-line regex>
  printf '%s\n' "$1" | grep -qE "$2" && printf '%s\n' "$1" | grep -qE "$3"
}

found=0; dismissed=0; stuck=0
while IFS=$'\t' read -r id name; do
  selected "$name" || continue
  text="$(pane_tail "$id")"
  hit=""
  for row in "${CARDS[@]}"; do
    IFS='|' read -r card title keyline key <<<"$row"
    if card_in "$text" "$title" "$keyline"; then hit="$card"; break; fi
  done
  if [ -z "$hit" ]; then echo "--   $name: nothing to dismiss"; continue; fi
  found=$((found + 1))
  if [ "$DRY" = 1 ]; then echo "plan $name: would dismiss $hit (key $key)"; continue; fi

  before="$(input_line "$id")"
  tmux send-keys -t "$SESSION:$id" "$key"
  sleep "$SETTLE"
  after="$(input_line "$id")"
  # tmux trims trailing blanks, so compare the lines without spaces
  if [ "${after// /}" = "${before// /}${key}" ]; then
    # the card did not take the key; it was typed into the input line
    tmux send-keys -t "$SESSION:$id" BSpace
    sleep "$SETTLE"
  fi
  if card_in "$(pane_tail "$id")" "$title" "$keyline"; then
    echo "!!   $name: $hit is still on screen"; stuck=$((stuck + 1))
  else
    echo "ok   $name: dismissed $hit"; dismissed=$((dismissed + 1))
  fi
done < <(tmux list-windows -t "$SESSION" -F '#{window_id}	#{window_name}')

if [ "$DRY" = 1 ]; then
  echo "dry-run: $found card(s) found, nothing pressed"
else
  echo "cards: $found found, $dismissed dismissed, $stuck still on screen"
fi
[ "$stuck" -eq 0 ]
