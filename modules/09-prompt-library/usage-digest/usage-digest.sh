#!/bin/bash
# Usage digest: что реально использовалось за неделю в сессиях Claude Code.
# Источник правды - транскрипты (~/.claude/projects/*/*.jsonl):
#   слэш-команды        <command-name>/имя
#   скиллы (из запасника) "skill":"имя"   (Claude дёргает сам через Skill)
#   субагенты            "subagent_type":"имя"  (Task)
# Параллель к rtk gain --history, только меряет использование, а не токены.
#
# По умолчанию печатает в stdout. Если заданы TG_BOT_TOKEN и TG_CHAT_ID (env) -
# дополнительно шлёт в Telegram (как rtk-telegram-report.sh). Секреты НЕ хранятся
# в этом файле (правило кита): передаются окружением из обёртки вне репозитория.

set -euo pipefail

# Общий чтец транскриптов (см. lib-transcripts.sh). Держит логику чтения истории
# в одном месте для модулей 09/11/12.
source "$(dirname "${BASH_SOURCE[0]}")/lib-transcripts.sh"

DAYS="${DIGEST_DAYS:-7}"

# Команды библиотеки промптов (модуль 09). Дополняй по мере роста набора.
LIB_COMMANDS="spec precommit session-wrap release-notes security-scan edge-cases backlog scope-triage handoff impl-plan audit"

DATE="$(date '+%Y-%m-%d')"

mapfile -t FILES < <(lt_find_files "$DAYS")

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "Prompt Library Usage - $DATE
За последние $DAYS дн. активных сессий не найдено."
  exit 0
fi

# --- сбор счётчиков ---
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

fmt() { # печатает блок счётчиков или "-"
  if [ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ]; then echo "  (нет)"; else
    printf '%s' "$1" | awk '{printf "  %-18s %s\n",$2,$1}'; fi
}

REPORT="Prompt Library Usage - $DATE
Окно: последние $DAYS дн., сессий: ${#FILES[@]}

== Команды библиотеки (модуль 09), всего: $LIB_TOTAL ==
${LIB_BLOCK}
== Прочие слэш-команды (встроенные + твои) ==
$([ -n "$(printf '%s' "$OTHER_BLOCK" | tr -d '[:space:]')" ] && printf '%s' "$OTHER_BLOCK" || echo '  (нет)')
== Скиллы (Claude дёргает из запасника) ==
$(fmt "$SKILL_COUNTS")
== Субагенты (Task) ==
$(fmt "$AGENT_COUNTS")
--
Ноль у команды библиотеки - плохой нейминг/не нужна. Частые - кандидат в хук.
Часто дёргаемый скилл/субагент - кандидат оформить своей командой."

echo "$REPORT"

if [ -n "${TG_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ]; then
  curl -s -X POST \
    "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=${REPORT}" \
    > /dev/null 2>&1 && echo "(отправлено в Telegram)"
fi
