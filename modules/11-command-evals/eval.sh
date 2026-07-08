#!/bin/bash
# eval.sh - command-evals, слой 1 (структурные проверки), модуль 11.
# Детерминированно, без стоимости: проверяет исходники команд модуля 09 против
# expectations.tsv. Слой 2 (LLM-судья) - отдельно, в v2.
#
# Использование:
#   eval.sh [--all|<имя>] [--baseline] [--strict]
#     --all        эвалить все команды (по умолчанию)
#     <имя>        эвалить одну команду
#     --baseline   сохранить текущий результат как базлайн для будущих дельт
#     --strict     ненулевой код выхода, если есть проваленные проверки
#
# Вывод: карточка баллов в stdout + docs/evals/scorecard.{md,tsv} (gitignored).
# Базлайн: docs/evals/baseline.tsv (локальный, не коммитится). Дельта считается
# против него. Ранжирование: сначала реально используемые команды (по digest).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
CMD_DIR="$REPO_ROOT/modules/09-prompt-library/commands"
EXPECT="$HERE/expectations.tsv"
LIB="$REPO_ROOT/modules/09-prompt-library/usage-digest/lib-transcripts.sh"
OUT_DIR="${EVAL_OUT_DIR:-$REPO_ROOT/docs/evals}"
USAGE_DAYS="${EVAL_USAGE_DAYS:-30}"

TARGET="--all"; DO_BASELINE=0; STRICT=0
for a in "$@"; do
  case "$a" in
    --baseline) DO_BASELINE=1 ;;
    --strict)   STRICT=1 ;;
    --all)      TARGET="--all" ;;
    -*)         echo "неизвестный флаг: $a" >&2; exit 2 ;;
    *)          TARGET="$a" ;;
  esac
done

# --- ожидания ---
declare -A EXP_ARG EXP_ANALYZER EXP_ROLE
while IFS=$'\t' read -r name arg analyzer role; do
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue ;; esac
  EXP_ARG["$name"]="$arg"
  EXP_ANALYZER["$name"]="$analyzer"
  EXP_ROLE["$name"]="$role"
done < "$EXPECT"

# --- использование (ранжирование): имя -> число вызовов ---
declare -A USE
if [ -f "$LIB" ]; then
  # shellcheck source=/dev/null
  source "$LIB"
  mapfile -t _F < <(lt_find_files "$USAGE_DAYS")
  if [ "${#_F[@]}" -gt 0 ]; then
    while read -r n cname; do
      [ -n "${cname:-}" ] && USE["$cname"]="$n"
    done < <(lt_cmd_counts "${_F[@]}")
  fi
fi

FAILFILE="$(mktemp)"
trap 'rm -f "$FAILFILE"' EXIT

# --- проверки одной команды: печатает "passed total"; детали фейлов -> FAILFILE ---
eval_one() {
  local name="$1" f="$CMD_DIR/$1.md"
  local passed=0 total=0 body role ok
  if [ ! -f "$f" ]; then
    echo "  [$name] нет файла команды" >> "$FAILFILE"; echo "0 1"; return
  fi
  if [ -z "${EXP_ARG[$name]:-}" ]; then
    echo "  [$name] нет строки в expectations.tsv" >> "$FAILFILE"; echo "0 1"; return
  fi
  body="$(cat "$f")"

  check() { # check <ok?0=pass> <msg>
    total=$((total+1))
    if [ "$1" -eq 0 ]; then passed=$((passed+1)); else
      echo "  [$name] $2" >> "$FAILFILE"; fi
  }
  has()  { printf '%s' "$body" | grep -qE "$1"; }   # регистрозависимо (структура)
  hasi() { printf '%s' "$body" | grep -qiE "$1"; }  # регистронезависимо (текст)

  # U1 frontmatter: --- ... description: ... ---
  if printf '%s' "$body" | head -1 | grep -q '^---$' \
     && has '^description:' \
     && [ "$(printf '%s' "$body" | grep -c '^---$')" -ge 2 ]; then
    check 0 ""; else check 1 "битый frontmatter (--- / description:)"; fi

  # U2 без em-dash как пунктуации (" -- " или слово--слово). Фенсы frontmatter
  # (---) и CLI-флаги (--sort) не считаем.
  if printf '%s' "$body" | grep -v '^---$' | grep -qE ' -- |[[:alnum:]]--[[:alnum:]]'; then
    check 1 "найден em-dash (--)"; else check 0 ""; fi

  # U3 ссылка на ролевой файл .ai/ДОЛЖНА быть условной ("если ...")
  if has '\.ai/[A-Z]'; then
    if hasi 'если.*\.ai/|\.ai/.*(есть|нет)|если в проекте'; then
      check 0 ""; else check 1 ".ai/ роль упомянута без условия (если ...)"; fi
  fi

  # C1 аргумент: needs_arg=y -> есть $ARGUMENTS/$1, argument-hint, fallback
  if [ "${EXP_ARG[$name]}" = "y" ]; then
    ok=0
    has '\$ARGUMENTS|\$1' || ok=1
    grep -q '^argument-hint:' "$f" || ok=1
    hasi 'иначе|спроси|если задан|если задана|если задано|если.*не задан|если.*нет|не задан' || ok=1
    check "$ok" "аргумент объявлен, но нет argument-hint / \$ARGUMENTS / fallback"
  fi

  # C2 analyzer=y -> guard
  if [ "${EXP_ANALYZER[$name]}" = "y" ]; then
    if hasi 'не пиши код|ничего не коммить|ничего не меняй|не начинай|пока не пиши|реализацию не начинай'; then
      check 0 ""; else check 1 "analyzer без guard (не пиши код / ничего не меняй / не начинай)"; fi
  fi

  # C3 ai_role
  role="${EXP_ROLE[$name]}"
  if [ "$role" = "MULTI" ]; then
    if has 'PATTERNS\.md'; then check 0 ""; else
      check 1 "мульти-ролевая, но нет ссылки на карту PATTERNS.md"; fi
  elif [ "$role" != "-" ] && [ -n "$role" ]; then
    if has "\\.ai/$role"; then check 0 ""; else
      check 1 "нет условной ссылки на .ai/$role"; fi
  fi

  echo "$passed $total"
}

# --- какие команды эвалим ---
mapfile -t NAMES < <(
  if [ "$TARGET" = "--all" ]; then
    for f in "$CMD_DIR"/*.md; do basename "$f" .md; done
  else printf '%s\n' "$TARGET"; fi
)

# ранжируем: используемые - раньше (по USE, потом по имени)
mapfile -t NAMES < <(
  for n in "${NAMES[@]}"; do printf '%s\t%s\n' "${USE[$n]:-0}" "$n"; done \
    | sort -k1,1rn -k2,2 | cut -f2
)

# --- базлайн для дельт ---
declare -A BASE
BASELINE_F="$OUT_DIR/baseline.tsv"
if [ -f "$BASELINE_F" ]; then
  while IFS=$'\t' read -r n p t; do [ -n "${n:-}" ] && BASE["$n"]="$p"; done < "$BASELINE_F"
fi

mkdir -p "$OUT_DIR"
DATE="$(date '+%Y-%m-%d')"
SCORE_TSV="$OUT_DIR/scorecard.tsv"; : > "$SCORE_TSV"

TOTAL_P=0; TOTAL_T=0; ROWS=""
for n in "${NAMES[@]}"; do
  read -r p t < <(eval_one "$n")
  TOTAL_P=$((TOTAL_P+p)); TOTAL_T=$((TOTAL_T+t))
  printf '%s\t%s\t%s\n' "$n" "$p" "$t" >> "$SCORE_TSV"
  pct=$(( t>0 ? 100*p/t : 0 ))
  if [ -n "${BASE[$n]:-}" ]; then
    bp="${BASE[$n]}"
    if   [ "$p" -gt "$bp" ]; then delta="+$((p-bp))"
    elif [ "$p" -lt "$bp" ]; then delta="$((p-bp))"
    else delta="="; fi
  else delta="new"; fi
  ROWS="${ROWS}$(printf '  %-14s use=%-3s %d/%d (%d%%) d:%s' "$n" "${USE[$n]:-0}" "$p" "$t" "$pct" "$delta")"$'\n'
done

OVERALL=$(( TOTAL_T>0 ? 100*TOTAL_P/TOTAL_T : 0 ))
REPORT="Command Evals (слой 1) - $DATE
Команд: ${#NAMES[@]}, проверок пройдено: $TOTAL_P/$TOTAL_T (${OVERALL}%)

${ROWS}"
if [ -s "$FAILFILE" ]; then
  REPORT="${REPORT}
Проваленные проверки:
$(cat "$FAILFILE")"
fi

echo "$REPORT"
{ echo "# Command Evals scorecard - $DATE"; echo; echo '```'; echo "$REPORT"; echo '```'; } > "$OUT_DIR/scorecard.md"

if [ "$DO_BASELINE" -eq 1 ]; then
  cp "$SCORE_TSV" "$BASELINE_F"
  echo "(базлайн сохранён: $BASELINE_F)"
fi

if [ "$STRICT" -eq 1 ] && [ "$TOTAL_P" -lt "$TOTAL_T" ]; then exit 1; fi
exit 0
