#!/bin/bash
# freshness-hook.sh - модуль 13, UserPromptSubmit-хук Claude Code.
# Полностью автоматический триггер /arch-viz: при каждом промпте пользователя
# быстро (два git log) сверяет, не устарели ли данные визуализации, и если
# устарели - впрыскивает агенту указание обновить их В ЭТОМ же ходе.
# Владелец ничего не говорит и не замечает: сессия чинит свежесть сама.
#
# Анти-шум: нудж не чаще раза в сутки на проект (маркер в приватной зоне).
# Без git-репо / без arch-data.json - молча выходит. Всегда exit 0.
#
# Подключение (в .claude/settings.json проекта, hooks.UserPromptSubmit):
#   ARCHVIZ_SRC_PATHS="src/" bash tools/prompt-kit/arch-viz/freshness-hook.sh
# ARCHVIZ_SRC_PATHS - какие пути считать исходниками (те же, что в workflow).

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
DATA="$ROOT/docs/arch/arch-data.json"
[ -f "$DATA" ] || exit 0

SRC_PATHS="${ARCHVIZ_SRC_PATHS:-src/}"

data_t="$(git -C "$ROOT" log -1 --format=%ct -- docs/arch/arch-data.json 2>/dev/null || echo 0)"
# shellcheck disable=SC2086
src_t="$(git -C "$ROOT" log -1 --format=%ct -- $SRC_PATHS 2>/dev/null || echo 0)"
[ "${src_t:-0}" -gt "${data_t:-0}" ] || exit 0

# дебаунс: раз в сутки
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
_enc="$(printf '%s' "$ROOT" | sed 's#/#-#g')"
MARKER_DIR="$CLAUDE_DIR/projects/$_enc"
MARKER="$MARKER_DIR/.arch-viz-nudged"
TODAY="$(date '+%Y-%m-%d')"
[ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$TODAY" ] && exit 0
mkdir -p "$MARKER_DIR" && printf '%s' "$TODAY" > "$MARKER" 2>/dev/null || true

cat <<'MSG'
ARCH-VIZ STALE: исходники проекта менялись позже docs/arch/arch-data.json -
архитектурная визуализация устарела. В ЭТОМ ходе, закончив ответ на текущий
запрос пользователя, выполни команду /arch-viz (обнови данные инкрементально,
собери HTML билдером) и закоммить docs/arch/ отдельным коммитом
"chore(arch-viz): refresh". Если изменения исходников архитектуру не меняли -
достаточно обновить meta.updated/meta.commit в данных и пересобрать. Отдельного
разрешения пользователя на это не нужно (стандартный автоматический шаг),
но в одну строку упомяни, что визуализация обновлена.
MSG
exit 0
