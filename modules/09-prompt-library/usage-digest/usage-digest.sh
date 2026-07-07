#!/bin/bash
# Usage digest: сколько раз за неделю вызывались слэш-команды библиотеки промптов.
# Источник правды - транскрипты Claude Code (~/.claude/projects/*/*.jsonl),
# где каждый вызов пишется как <command-name>/имя. Параллель к rtk gain --history,
# только меряет не токены, а использование команд/промптов.
#
# По умолчанию печатает отчёт в stdout. Если заданы TG_BOT_TOKEN и TG_CHAT_ID
# (env), дополнительно шлёт его в Telegram - как rtk-telegram-report.sh.
# Секреты НЕ хранятся в этом файле (правило кита): передавай их окружением
# или из cron-обёртки, лежащей вне репозитория.

set -euo pipefail

PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
DAYS="${DIGEST_DAYS:-7}"

# Команды библиотеки промптов (модуль 09). Дополняй по мере роста набора.
LIB_COMMANDS="spec precommit session-wrap release-notes security-scan edge-cases"

DATE="$(date '+%Y-%m-%d')"

# Транскрипты, тронутые за последние N дней.
mapfile -t FILES < <(find "$PROJECTS_DIR" -name '*.jsonl' -mtime "-${DAYS}" 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
  REPORT="Prompt Library Usage - $DATE
За последние $DAYS дн. активных сессий не найдено."
  echo "$REPORT"
  exit 0
fi

# Все вызовы слэш-команд за период (включая встроенные - для контекста).
ALL_CALLS="$(grep -oh '<command-name>/[a-z0-9-]*' "${FILES[@]}" 2>/dev/null \
  | sed 's#<command-name>/##' | sort | uniq -c | sort -rn || true)"

# Считаем только команды библиотеки.
LIB_LINES=""
LIB_TOTAL=0
for c in $LIB_COMMANDS; do
  n="$(printf '%s\n' "$ALL_CALLS" | awk -v cmd="$c" '$2==cmd {print $1}')"
  n="${n:-0}"
  LIB_TOTAL=$((LIB_TOTAL + n))
  LIB_LINES="${LIB_LINES}$(printf '  /%-16s %s\n' "$c" "$n")"$'\n'
done

REPORT="Prompt Library Usage - $DATE
Окно: последние $DAYS дн., сессий: ${#FILES[@]}

Команды библиотеки (модуль 09), всего вызовов: $LIB_TOTAL
${LIB_LINES}
Не вызывались за период - кандидаты на удаление или лучший нейминг.
Часто вызываемые - кандидаты на хук (следующая ступень лестницы закрепления)."

echo "$REPORT"

# Опциональная доставка в Telegram (только если заданы секреты в окружении).
if [ -n "${TG_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ]; then
  curl -s -X POST \
    "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=${REPORT}" \
    > /dev/null 2>&1 && echo "(отправлено в Telegram)"
fi
