#!/bin/bash
# consolidate.sh - модуль 12, детерминированный СБОР сырья для консолидации памяти.
# Сам НЕ дистиллирует (это делает /consolidate-memory внутри сессии). Только
# собирает разрозненные источники в один ревьюабельный файл.
#
# Источники: снапшоты docs/.session-current.md (текущий + история из git),
# индекс памяти MEMORY.md, инвентарь .ai/, сводка использования (команды/скиллы/
# субагенты за окно), опционально выборка печатанных промптов.
#
# Использование:
#   consolidate.sh [--days N] [--with-prompts]
# Вывод: ~/.claude/projects/<encoded-root>/consolidation/material-<дата>.md -
# ВНЕ рабочего дерева репозитория (по образцу MEMORY_DIR): сырьё содержит
# приватные снапшоты/промпты (в медицинских проектах - PHI-риск), git-дерево
# ему не дом. gitignore на docs/consolidation/ остаётся страховкой на случай
# CONSOLIDATE_OUT_DIR-override внутрь дерева.
#
# Env:
#   MEMORY_DIR  каталог памяти проекта (по умолчанию выводится из PWD)
#   CONSOLIDATE_OUT_DIR  куда писать сырьё (по умолчанию приватная зона выше)
#   CONSOLIDATE_DAYS  окно в днях (по умолчанию 7; флаг --days важнее)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Корень проекта: git-топлевел, иначе текущий каталог (переносимо: кит и
# вендоренный tools/prompt-kit/memory-consolidation/).
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# lib-transcripts: override, иначе рядом с харнессом (вендоринг), иначе в ките.
LIB=""
for _c in "${CONSOLIDATE_LIB:-}" "$HERE/../lib-transcripts.sh" "$PROJECT_ROOT/modules/09-prompt-library/usage-digest/lib-transcripts.sh"; do
  [ -n "$_c" ] && [ -f "$_c" ] && { LIB="$_c"; break; }
done
# ЕДИНОЕ ПРАВИЛО ХРАНЕНИЯ СЫРЬЯ (все проекты, все платформы): рядом с памятью
# проекта - <claude-config>/projects/<enc>/consolidation/. База берётся как у
# самого Claude Code: CLAUDE_CONFIG_DIR, иначе ~/.claude - одинаково работает
# на Linux/macOS/Windows(git-bash/WSL). Сырьё РЕГЕНЕРИРУЕМО (собирается из
# транскриптов заново), поэтому переезд на другую платформу/путь ничего
# ценного не теряет: долговечное - только принятый владельцем дистиллят в
# MEMORY.md/.ai/, а он живёт в самом проекте.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
_enc="$(printf '%s' "$PROJECT_ROOT" | sed 's#/#-#g')"
OUT_DIR="${CONSOLIDATE_OUT_DIR:-$CLAUDE_DIR/projects/$_enc/consolidation}"

DAYS="${CONSOLIDATE_DAYS:-7}"; WITH_PROMPTS=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-7}"; shift 2 ;;
    --with-prompts) WITH_PROMPTS=1; shift ;;
    *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
  esac
done

# каталог памяти проекта: ~/.claude/projects/<encoded-PWD>/memory
if [ -z "${MEMORY_DIR:-}" ]; then
  MEMORY_DIR="$CLAUDE_DIR/projects/$_enc/memory"
fi

mkdir -p "$OUT_DIR"
DATE="$(date '+%Y-%m-%d')"
OUT="$OUT_DIR/material-$DATE.md"

{
  echo "# Материал для консолидации памяти - $DATE"
  echo
  echo "Окно: последние $DAYS дн. Собрано consolidate.sh (детерминированно)."
  echo "Это СЫРЬЁ для /consolidate-memory, не дистиллят. Не редактируй вручную."
  if [ "$WITH_PROMPTS" -eq 1 ]; then
    echo
    echo "> ВНИМАНИЕ (приватность/PHI): файл содержит выборку печатанных промптов"
    echo "> из транскриптов. Не переноси его в git-дерево и не цитируй в коммитах."
  fi
  echo

  echo "## 1. Снапшоты сессий (docs/.session-current.md)"
  echo
  SNAP="$PROJECT_ROOT/docs/.session-current.md"
  if [ -f "$SNAP" ]; then
    echo "### Текущий"; echo '```'; cat "$SNAP"; echo '```'; echo
    echo "### История коммитов снапшота (последние 8)"
    git -C "$PROJECT_ROOT" log -8 --format='- %ad %h %s' --date=short -- docs/.session-current.md 2>/dev/null || echo "(git недоступен)"
  else
    echo "(снапшота нет)"
  fi
  echo

  echo "## 2. Индекс памяти (MEMORY.md)"
  echo
  if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    echo '```'; cat "$MEMORY_DIR/MEMORY.md"; echo '```'; echo
    echo "Файлы памяти: $(find "$MEMORY_DIR" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l) шт."
  else
    echo "(MEMORY.md не найден: $MEMORY_DIR)"
  fi
  echo

  echo "## 3. Инвентарь .ai/"
  echo
  if [ -d "$PROJECT_ROOT/.ai" ]; then
    find "$PROJECT_ROOT/.ai" -maxdepth 1 -name '*.md' -printf '- %f\n' 2>/dev/null
  else
    echo "(в этом проекте .ai/ нет - у кита роли в AGENTS.md модуля 08)"
  fi
  echo

  echo "## 4. Сводка использования за окно"
  echo
  if [ -f "$LIB" ]; then
    # shellcheck source=/dev/null
    source "$LIB"
    mapfile -t F < <(lt_find_files "$DAYS")
    echo "Сессий в окне: ${#F[@]}"
    if [ "${#F[@]}" -gt 0 ]; then
      echo; echo "Команды:"; lt_cmd_counts "${F[@]}" | awk '{printf "  %s %s\n",$2,$1}' | head -20
      echo; echo "Скиллы:"; lt_skill_counts "${F[@]}" | awk '{printf "  %s %s\n",$2,$1}' | head -20
      echo; echo "Субагенты:"; lt_agent_counts "${F[@]}" | awk '{printf "  %s %s\n",$2,$1}' | head -20
      if [ "$WITH_PROMPTS" -eq 1 ]; then
        echo; echo "## 5. Выборка печатанных промптов (до 200 строк, окно $DAYS дн.)"
        echo '```'; lt_typed_prompts "${F[@]}" | grep -v '^$' | head -200; echo '```'
      fi
    fi
  else
    echo "(lib-transcripts.sh недоступен)"
  fi
} > "$OUT"

echo "Сырьё собрано: $OUT"
echo "Дальше: в сессии вызови /consolidate-memory - он дистиллирует в DRAFT (в том же каталоге) на твоё ревью."
