#!/bin/bash
# check-provenance.sh - reconcile the vendored prompt-kit artifacts with the kit.
# Runs inside the TARGET project (the rollout vendors it into tools/prompt-kit/).
#
# What it does: collects the `release-conveyor-kit@<sha>` stamps from
#   - .claude/commands/*.md            (frontmatter: provenance: ...)
#   - docs/prompt-kit-guide.md,
#     docs/prompts/library/**.md       (comment <!-- provenance: ... -->)
#   - tools/prompt-kit/PROVENANCE      (vendored from ... + kit path)
# and, when the kit is reachable (env KIT, or the "kit path:" line in
# PROVENANCE), reports how far each stamp lags behind the kit's HEAD and which
# kit sources changed since.
#
# Usage: check-provenance.sh [--strict]
#   --strict  non-zero exit when artifacts are unstamped or drifted.
#
# ponytail: plain grep + git rev-list, no manifests; generalize only if a third
# stamp format ever shows up.

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT"

if [ -d "$PROJECT_ROOT/modules/09-prompt-library" ]; then
  echo "This is the kit itself - nothing is vendored, provenance does not apply."
  exit 0
fi

STRICT=0; [ "${1:-}" = "--strict" ] && STRICT=1
RX='release-conveyor-kit@[0-9a-f]{7,40}'
PROV_FILE="tools/prompt-kit/PROVENANCE"

# The kit: env KIT wins, otherwise "kit path:" from PROVENANCE.
KIT="${KIT:-}"
if [ -z "$KIT" ] && [ -f "$PROV_FILE" ]; then
  KIT="$(sed -n 's/^kit path:[[:space:]]*//p' "$PROV_FILE" | head -1)"
fi

MISSING=0
declare -A SHAS  # sha -> how many artifacts sit on it

stamp_of() { grep -hoE "$RX" "$1" 2>/dev/null | head -1 | cut -d@ -f2; }

report_one() { # <file> <stamp|empty>
  local f="$1" sha="$2"
  if [ -n "$sha" ]; then
    SHAS["$sha"]=$(( ${SHAS[$sha]:-0} + 1 ))
    printf '  %-55s %s\n' "$f" "$sha"
  else
    printf '  %-55s NO STAMP\n' "$f"
    MISSING=$((MISSING+1))
  fi
}

echo "Provenance of vendored artifacts ($PROJECT_ROOT)"
echo
echo "Commands (.claude/commands):"
found_any=0
for f in .claude/commands/*.md; do
  [ -f "$f" ] || continue
  # the project's own commands (no stamp, no trace of the kit) are not vendored
  if grep -qE "^provenance:.*$RX" "$f"; then
    report_one "$f" "$(stamp_of "$f")"; found_any=1
  fi
done
[ "$found_any" -eq 0 ] && echo "  (no stamped commands found)" && MISSING=$((MISSING+1))

echo
echo "Guide and menu:"
for f in docs/prompt-kit-guide.md docs/prompts/library/PATTERNS.md; do
  [ -f "$f" ] && report_one "$f" "$(stamp_of "$f")"
done
while IFS= read -r f; do
  report_one "$f" "$(stamp_of "$f")"
done < <(find docs/prompts/library -name '*.md' ! -name 'PATTERNS.md' 2>/dev/null | sort)

echo
echo "Tooling:"
if [ -f "$PROV_FILE" ]; then
  report_one "$PROV_FILE" "$(stamp_of "$PROV_FILE")"
else
  echo "  $PROV_FILE IS MISSING"; MISSING=$((MISSING+1))
fi

DRIFT=0
echo
if [ -n "$KIT" ] && git -C "$KIT" rev-parse HEAD >/dev/null 2>&1; then
  HEAD_SHA="$(git -C "$KIT" rev-parse --short HEAD)"
  echo "Kit: $KIT @ $HEAD_SHA"
  for sha in "${!SHAS[@]}"; do
    if ! git -C "$KIT" rev-parse --verify -q "$sha" >/dev/null; then
      echo "  $sha (${SHAS[$sha]} artifacts): commit not found in the kit - broken stamp?"
      DRIFT=1; continue
    fi
    behind="$(git -C "$KIT" rev-list --count "$sha..HEAD")"
    if [ "$behind" -eq 0 ]; then
      echo "  $sha (${SHAS[$sha]} artifacts): current (= the kit's HEAD)"
    else
      DRIFT=1
      echo "  $sha (${SHAS[$sha]} artifacts): $behind commit(s) behind. Kit sources that changed:"
      git -C "$KIT" diff --name-only "$sha..HEAD" -- \
        modules/09-prompt-library modules/11-command-evals \
        modules/12-memory-consolidation modules/13-arch-viz \
        docs/prompt-kit-guide.md \
        | sed 's/^/    /'
    fi
  done
else
  echo "Kit not reachable (no env KIT and no kit path in PROVENANCE) - HEAD comparison skipped."
fi

echo
if [ "$MISSING" -gt 0 ]; then echo "Unstamped artifacts: $MISSING."; fi
if [ "$DRIFT" -gt 0 ]; then echo "Drift detected - port the changes you want and update the stamps (vendoring: the project owns its copy)."; fi
[ "$MISSING" -eq 0 ] && [ "$DRIFT" -eq 0 ] && echo "Everything stamped, no drift."

if [ "$STRICT" -eq 1 ] && { [ "$MISSING" -gt 0 ] || [ "$DRIFT" -gt 0 ]; }; then exit 1; fi
exit 0
