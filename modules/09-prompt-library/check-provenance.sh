#!/bin/bash
# check-provenance.sh - сверка вендоренных артефактов prompt-kit с китом.
# Запускается в ЦЕЛЕВОМ проекте (вендорится в tools/prompt-kit/ раскаткой).
#
# Что делает: собирает штампы `release-conveyor-kit@<sha>` из
#   - .claude/commands/*.md            (frontmatter: provenance: ...)
#   - docs/prompt-kit-guide.md,
#     docs/prompts/library/**.md       (комментарий <!-- provenance: ... -->)
#   - tools/prompt-kit/PROVENANCE      (vendored from ... + kit path)
# и, если кит доступен (env KIT или строка "kit path:" в PROVENANCE),
# показывает отставание каждого штампа от HEAD кита и какие исходники
# кита изменились с тех пор.
#
# Использование: check-provenance.sh [--strict]
#   --strict  ненулевой выход при артефактах без штампа или при дрейфе.
#
# ponytail: plain grep + git rev-list, без манифестов; если появится третий
# формат штампа - тогда и обобщать.

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT"

if [ -d "$PROJECT_ROOT/modules/09-prompt-library" ]; then
  echo "Это сам кит - вендоринга нет, провенанс не требуется."
  exit 0
fi

STRICT=0; [ "${1:-}" = "--strict" ] && STRICT=1
RX='release-conveyor-kit@[0-9a-f]{7,40}'
PROV_FILE="tools/prompt-kit/PROVENANCE"

# Кит: env KIT важнее, иначе "kit path:" из PROVENANCE.
KIT="${KIT:-}"
if [ -z "$KIT" ] && [ -f "$PROV_FILE" ]; then
  KIT="$(sed -n 's/^kit path:[[:space:]]*//p' "$PROV_FILE" | head -1)"
fi

MISSING=0
declare -A SHAS  # sha -> сколько артефактов на нём

stamp_of() { grep -hoE "$RX" "$1" 2>/dev/null | head -1 | cut -d@ -f2; }

report_one() { # <файл> <штамп|пусто>
  local f="$1" sha="$2"
  if [ -n "$sha" ]; then
    SHAS["$sha"]=$(( ${SHAS[$sha]:-0} + 1 ))
    printf '  %-55s %s\n' "$f" "$sha"
  else
    printf '  %-55s БЕЗ ШТАМПА\n' "$f"
    MISSING=$((MISSING+1))
  fi
}

echo "Провенанс вендоренных артефактов ($PROJECT_ROOT)"
echo
echo "Команды (.claude/commands):"
found_any=0
for f in .claude/commands/*.md; do
  [ -f "$f" ] || continue
  # чужие команды проекта (без штампа и без следа кита) не считаем вендоренными
  if grep -qE "^provenance:.*$RX" "$f"; then
    report_one "$f" "$(stamp_of "$f")"; found_any=1
  fi
done
[ "$found_any" -eq 0 ] && echo "  (команд со штампом не найдено)" && MISSING=$((MISSING+1))

echo
echo "Гайд и меню:"
for f in docs/prompt-kit-guide.md docs/prompts/library/PATTERNS.md; do
  [ -f "$f" ] && report_one "$f" "$(stamp_of "$f")"
done
while IFS= read -r f; do
  report_one "$f" "$(stamp_of "$f")"
done < <(find docs/prompts/library -name '*.md' ! -name 'PATTERNS.md' 2>/dev/null | sort)

echo
echo "Тулинг:"
if [ -f "$PROV_FILE" ]; then
  report_one "$PROV_FILE" "$(stamp_of "$PROV_FILE")"
else
  echo "  $PROV_FILE ОТСУТСТВУЕТ"; MISSING=$((MISSING+1))
fi

DRIFT=0
echo
if [ -n "$KIT" ] && git -C "$KIT" rev-parse HEAD >/dev/null 2>&1; then
  HEAD_SHA="$(git -C "$KIT" rev-parse --short HEAD)"
  echo "Кит: $KIT @ $HEAD_SHA"
  for sha in "${!SHAS[@]}"; do
    if ! git -C "$KIT" rev-parse --verify -q "$sha" >/dev/null; then
      echo "  $sha (${SHAS[$sha]} шт.): коммит не найден в ките - штамп битый?"
      DRIFT=1; continue
    fi
    behind="$(git -C "$KIT" rev-list --count "$sha..HEAD")"
    if [ "$behind" -eq 0 ]; then
      echo "  $sha (${SHAS[$sha]} шт.): актуален (= HEAD кита)"
    else
      DRIFT=1
      echo "  $sha (${SHAS[$sha]} шт.): отстаёт на $behind коммит(ов). Изменившиеся исходники кита:"
      git -C "$KIT" diff --name-only "$sha..HEAD" -- \
        modules/09-prompt-library modules/11-command-evals \
        modules/12-memory-consolidation docs/prompt-kit-guide.md \
        | sed 's/^/    /'
    fi
  done
else
  echo "Кит недоступен (нет env KIT и kit path в PROVENANCE) - сверка с HEAD пропущена."
fi

echo
if [ "$MISSING" -gt 0 ]; then echo "Артефактов без штампа: $MISSING."; fi
if [ "$DRIFT" -gt 0 ]; then echo "Есть дрейф - перенеси нужные правки и обнови штампы (вендоринг: проект владеет копией)."; fi
[ "$MISSING" -eq 0 ] && [ "$DRIFT" -eq 0 ] && echo "Всё со штампами, дрейфа нет."

if [ "$STRICT" -eq 1 ] && { [ "$MISSING" -gt 0 ] || [ "$DRIFT" -gt 0 ]; }; then exit 1; fi
exit 0
