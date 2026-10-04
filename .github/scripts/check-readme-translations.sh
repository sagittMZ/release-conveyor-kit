#!/bin/bash
# check-readme-translations.sh - keep the translated READMEs in step with the
# English one (ARCHITECTURE.md, record 21).
#
# Every translation starts with a stamp:
#   <!-- translated-from: README.md sha256:<first 12 hex of the hash> -->
# The check fails when the stamp does not match the current README.md, which
# means the English text changed and the translation was not redone.
#
# Usage:
#   check-readme-translations.sh           verify, non-zero exit on a stale stamp
#   check-readme-translations.sh --stamp   write the current hash into the stamps
#                                          (only after the translation is redone)

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
TRANSLATIONS="README.ru.md README.es.md"
want="$(sha256sum README.md | cut -c1-12)"

if [ "${1:-}" = "--stamp" ]; then
  for f in $TRANSLATIONS; do
    sed -i "1s/^<!-- translated-from: README.md sha256:[^ ]* -->\$/<!-- translated-from: README.md sha256:$want -->/" "$f"
  done
fi

rc=0
for f in $TRANSLATIONS; do
  if [ ! -f "$f" ]; then echo "!! $f is missing"; rc=1; continue; fi
  have="$(sed -n '1s/^<!-- translated-from: README.md sha256:\([0-9a-f]*\) -->$/\1/p' "$f")"
  if [ "$have" = "$want" ]; then
    echo "ok   $f matches README.md ($want)"
  else
    echo "!! $f is stale: stamped ${have:-nothing}, README.md is $want"
    rc=1
  fi
done
exit "$rc"
