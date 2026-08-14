#!/bin/bash
# Usage digest: what was actually used over the week in Claude Code sessions.
# Source of truth - the transcripts (~/.claude/projects/*/*.jsonl):
#   slash commands   <command-name>/name
#   skills           "skill":"name"          (Claude invokes these itself)
#   subagents        "subagent_type":"name"  (Task)
# It measures command usage, not token spend.
#
# Prints to stdout by default. If TG_BOT_TOKEN and TG_CHAT_ID are set in the
# environment, it also sends the report to Telegram. Secrets are NOT stored in
# this file (a kit rule): they arrive through the environment from a wrapper
# kept outside the repository.

set -euo pipefail

# Shared transcript reader (see lib-transcripts.sh). Keeps the history-reading
# logic in one place for modules 09/11/12.
source "$(dirname "${BASH_SOURCE[0]}")/lib-transcripts.sh"

DAYS="${DIGEST_DAYS:-7}"

# The prompt library's commands: whatever sits in commands/ next door, so the
# list cannot rot when a command is added or renamed. An empty directory just
# means everything reports under "other".
LIB_COMMANDS=""
for _f in "$(dirname "${BASH_SOURCE[0]}")"/../commands/*.md; do
  [ -f "$_f" ] && LIB_COMMANDS="$LIB_COMMANDS $(basename "$_f" .md)"
done

DATE="$(date '+%Y-%m-%d')"

mapfile -t FILES < <(lt_find_files "$DAYS")

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "Prompt Library Usage - $DATE
No active sessions found in the last $DAYS day(s)."
  exit 0
fi

# --- collecting the counters ---
CMD_COUNTS="$(lt_cmd_counts "${FILES[@]}")"
SKILL_COUNTS="$(lt_skill_counts "${FILES[@]}")"
AGENT_COUNTS="$(lt_agent_counts "${FILES[@]}")"

is_lib() { for c in $LIB_COMMANDS; do [ "$1" = "$c" ] && return 0; done; return 1; }

LIB_BLOCK=""; LIB_TOTAL=0
for c in $LIB_COMMANDS; do
  n="$(printf '%s\n' "$CMD_COUNTS" | awk -v cmd="$c" '$2==cmd {print $1}')"; n="${n:-0}"
  LIB_TOTAL=$((LIB_TOTAL + n))
  LIB_BLOCK="${LIB_BLOCK}$(printf '  /%-15s %s' "$c" "$n")"$'\n'
done

OTHER_BLOCK=""
while read -r n name; do
  [ -z "${name:-}" ] && continue
  is_lib "$name" && continue
  OTHER_BLOCK="${OTHER_BLOCK}$(printf '  /%-15s %s' "$name" "$n")"$'\n'
done <<< "$CMD_COUNTS"

fmt() { # prints a block of counters, or "(none)"
  if [ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ]; then echo "  (none)"; else
    printf '%s' "$1" | awk '{printf "  %-18s %s\n",$2,$1}'; fi
}

REPORT="Prompt Library Usage - $DATE
Window: last $DAYS day(s), sessions: ${#FILES[@]}

== Library commands (module 09), total: $LIB_TOTAL ==
${LIB_BLOCK}
== Other slash commands (built-in + your own) ==
$([ -n "$(printf '%s' "$OTHER_BLOCK" | tr -d '[:space:]')" ] && printf '%s' "$OTHER_BLOCK" || echo '  (none)')
== Skills (invoked by Claude itself) ==
$(fmt "$SKILL_COUNTS")
== Subagents (Task) ==
$(fmt "$AGENT_COUNTS")
--
Zero for a library command means bad naming or no need. Frequent ones are hook
candidates. A frequently invoked skill or subagent is a candidate for becoming
a command of its own."

echo "$REPORT"

if [ -n "${TG_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ]; then
  curl -s -X POST \
    "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=${REPORT}" \
    > /dev/null 2>&1 && echo "(sent to Telegram)"
fi
