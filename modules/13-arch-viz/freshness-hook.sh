#!/bin/bash
# freshness-hook.sh - module 13, a Claude Code UserPromptSubmit hook.
# A fully automatic /arch-viz trigger: on every user prompt it cheaply (two git
# log calls) checks whether the visualization data went stale, and if it did, it
# injects an instruction for the agent to refresh it IN THAT SAME turn.
# The owner says nothing and notices nothing: the session fixes freshness itself.
#
# Noise control: at most one nudge per project per day (marker in the private
# zone). With no git repo or no arch-data.json it exits silently. Always exit 0.
#
# Wiring (in the project's .claude/settings.json, hooks.UserPromptSubmit):
#   ARCHVIZ_SRC_PATHS="src/" bash tools/prompt-kit/arch-viz/freshness-hook.sh
# ARCHVIZ_SRC_PATHS - which paths count as sources (the same as in the workflow).

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
DATA="$ROOT/docs/arch/arch-data.json"
[ -f "$DATA" ] || exit 0

SRC_PATHS="${ARCHVIZ_SRC_PATHS:-src/}"

data_t="$(git -C "$ROOT" log -1 --format=%ct -- docs/arch/arch-data.json 2>/dev/null || echo 0)"
# shellcheck disable=SC2086
src_t="$(git -C "$ROOT" log -1 --format=%ct -- $SRC_PATHS 2>/dev/null || echo 0)"
[ "${src_t:-0}" -gt "${data_t:-0}" ] || exit 0

# debounce: once a day
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
_enc="$(printf '%s' "$ROOT" | sed 's#/#-#g')"
MARKER_DIR="$CLAUDE_DIR/projects/$_enc"
MARKER="$MARKER_DIR/.arch-viz-nudged"
TODAY="$(date '+%Y-%m-%d')"
[ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$TODAY" ] && exit 0
mkdir -p "$MARKER_DIR" && printf '%s' "$TODAY" > "$MARKER" 2>/dev/null || true

cat <<'MSG'
ARCH-VIZ STALE: the project's sources changed later than
docs/arch/arch-data.json, so the architecture visualization is out of date. In
THIS turn, after finishing your answer to the user's current request, run the
/arch-viz command (update the data incrementally, build the HTML with the
builder) and commit docs/arch/ as a separate commit, "chore(arch-viz):
refresh". If the source changes did not actually change the architecture, it is
enough to update meta.updated / meta.commit in the data and rebuild. This is a
standard automatic step and needs no separate permission from the user, but do
mention in one line that the visualization was refreshed.
MSG
exit 0
