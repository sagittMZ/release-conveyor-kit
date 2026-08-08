#!/bin/bash
# consolidate.sh - module 12, deterministic COLLECTION of raw material for
# memory consolidation. It does NOT distill (that is /consolidate-memory, inside
# a session). It only gathers the scattered sources into one reviewable file.
#
# Sources: the docs/.session-current.md snapshots (the current one plus history
# from git), the MEMORY.md index, an inventory of .ai/, a usage summary
# (commands / skills / subagents over the window) and, optionally, a sample of
# the prompts the user typed.
#
# Usage:
#   consolidate.sh [--days N] [--with-prompts]
# Output: ~/.claude/projects/<encoded-root>/consolidation/material-<date>.md -
# OUTSIDE the repository working tree (following MEMORY_DIR): the raw material
# holds private snapshots and prompts (in medical projects, a PHI risk), and the
# git tree is no home for it. The docs/consolidation/ gitignore entry remains as
# insurance against a CONSOLIDATE_OUT_DIR override pointing inside the tree.
#
# Env:
#   MEMORY_DIR  the project's memory directory (derived from PWD by default)
#   CONSOLIDATE_OUT_DIR  where to write the raw material (the private zone above by default)
#   CONSOLIDATE_DAYS  the window in days (7 by default; the --days flag wins)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root: the git toplevel, otherwise the current directory (portable
# across the kit and a vendored tools/prompt-kit/memory-consolidation/).
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# lib-transcripts: override, otherwise next to the harness (vendored), otherwise in the kit.
LIB=""
for _c in "${CONSOLIDATE_LIB:-}" "$HERE/../lib-transcripts.sh" "$PROJECT_ROOT/modules/09-prompt-library/usage-digest/lib-transcripts.sh"; do
  [ -n "$_c" ] && [ -f "$_c" ] && { LIB="$_c"; break; }
done
# ONE STORAGE RULE FOR THE RAW MATERIAL (every project, every platform): next
# to the project's memory, at <claude-config>/projects/<enc>/consolidation/. The
# base is taken the same way Claude Code takes it: CLAUDE_CONFIG_DIR, otherwise
# ~/.claude - which works identically on Linux, macOS and Windows (git-bash or
# WSL). The raw material is REPRODUCIBLE (regathered from the transcripts), so
# moving to another platform or path loses nothing of value: the only durable
# thing is the distillate the owner accepted into MEMORY.md / .ai/, and that
# lives in the project itself.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
_enc="$(printf '%s' "$PROJECT_ROOT" | sed 's#/#-#g')"
OUT_DIR="${CONSOLIDATE_OUT_DIR:-$CLAUDE_DIR/projects/$_enc/consolidation}"

DAYS="${CONSOLIDATE_DAYS:-7}"; WITH_PROMPTS=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-7}"; shift 2 ;;
    --with-prompts) WITH_PROMPTS=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# the project's memory directory: ~/.claude/projects/<encoded-PWD>/memory
if [ -z "${MEMORY_DIR:-}" ]; then
  MEMORY_DIR="$CLAUDE_DIR/projects/$_enc/memory"
fi

mkdir -p "$OUT_DIR"
DATE="$(date '+%Y-%m-%d')"
OUT="$OUT_DIR/material-$DATE.md"

{
  echo "# Memory consolidation material - $DATE"
  echo
  echo "Window: the last $DAYS day(s). Gathered by consolidate.sh, deterministically."
  echo "This is RAW MATERIAL for /consolidate-memory, not a distillate. Do not edit by hand."
  if [ "$WITH_PROMPTS" -eq 1 ]; then
    echo
    echo "> WARNING (privacy/PHI): this file contains a sample of typed prompts"
    echo "> from the transcripts. Do not move it into the git tree or quote it in commits."
  fi
  echo

  echo "## 1. Session snapshots (docs/.session-current.md)"
  echo
  SNAP="$PROJECT_ROOT/docs/.session-current.md"
  if [ -f "$SNAP" ]; then
    echo "### Current"; echo '```'; cat "$SNAP"; echo '```'; echo
    echo "### Snapshot commit history (last 8)"
    git -C "$PROJECT_ROOT" log -8 --format='- %ad %h %s' --date=short -- docs/.session-current.md 2>/dev/null || echo "(git unavailable)"
  else
    echo "(no snapshot)"
  fi
  echo

  echo "## 2. Memory index (MEMORY.md)"
  echo
  if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    echo '```'; cat "$MEMORY_DIR/MEMORY.md"; echo '```'; echo
    echo "Memory files: $(find "$MEMORY_DIR" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)"
  else
    echo "(MEMORY.md not found: $MEMORY_DIR)"
  fi
  echo

  echo "## 3. Inventory of .ai/"
  echo
  if [ -d "$PROJECT_ROOT/.ai" ]; then
    find "$PROJECT_ROOT/.ai" -maxdepth 1 -name '*.md' -printf '- %f\n' 2>/dev/null
  else
    echo "(this project has no .ai/ - in the kit the roles live in module 08 AGENTS.md)"
  fi
  echo

  echo "## 4. Usage summary over the window"
  echo
  if [ -f "$LIB" ]; then
    # shellcheck source=/dev/null
    source "$LIB"
    mapfile -t F < <(lt_find_files "$DAYS")
    echo "Sessions in the window: ${#F[@]}"
    if [ "${#F[@]}" -gt 0 ]; then
      echo; echo "Commands:"; lt_cmd_counts "${F[@]}" | awk '{printf "  %s %s\n",$2,$1}' | head -20
      echo; echo "Skills:"; lt_skill_counts "${F[@]}" | awk '{printf "  %s %s\n",$2,$1}' | head -20
      echo; echo "Subagents:"; lt_agent_counts "${F[@]}" | awk '{printf "  %s %s\n",$2,$1}' | head -20
      if [ "$WITH_PROMPTS" -eq 1 ]; then
        echo; echo "## 5. Sample of typed prompts (up to 200 lines, $DAYS day window)"
        echo '```'; lt_typed_prompts "${F[@]}" | grep -v '^$' | head -200; echo '```'
      fi
    fi
  else
    echo "(lib-transcripts.sh unavailable)"
  fi
} > "$OUT"

echo "Raw material collected: $OUT"
echo "Next: run /consolidate-memory in a session - it distills this into a DRAFT (same directory) for your review."
