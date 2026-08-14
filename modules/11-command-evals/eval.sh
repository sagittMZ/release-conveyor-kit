#!/bin/bash
# eval.sh - command-evals, layer 1 (structural checks), module 11.
# Deterministic and free: checks the module 09 command sources against
# expectations.tsv. Layer 2 (LLM judge) is separate, driven by /eval-command.
#
# Usage:
#   eval.sh [--all|<name>] [--baseline] [--strict]
#     --all        evaluate every command (default)
#     <name>       evaluate a single command
#     --baseline   record the current result as the baseline for future deltas
#     --strict     non-zero exit code when any check failed
#
# Output: a scorecard on stdout + docs/evals/scorecard.{md,tsv} (gitignored).
# Baseline: docs/evals/baseline.tsv (local, never committed). Deltas are
# measured against it. Ranking: actually used commands first (per the digest).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root: the git toplevel, otherwise the current directory. Independent
# of how deep the harness sits - works both in the kit (modules/11-...) and in
# a vendored layout (tools/prompt-kit/command-evals/).
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Command directory: explicit override, otherwise .claude/commands (after
# rollout into a project), otherwise the module 09 sources (inside the kit).
if [ -n "${EVAL_CMD_DIR:-}" ]; then CMD_DIR="$EVAL_CMD_DIR"
elif [ -d "$PROJECT_ROOT/.claude/commands" ]; then CMD_DIR="$PROJECT_ROOT/.claude/commands"
else CMD_DIR="$PROJECT_ROOT/modules/09-prompt-library/commands"; fi
EXPECT="$HERE/expectations.tsv"
OUT_DIR="${EVAL_OUT_DIR:-$PROJECT_ROOT/docs/evals}"
USAGE_DAYS="${EVAL_USAGE_DAYS:-30}"
# lib-transcripts: override, otherwise next to the harness (vendored), otherwise in the kit.
LIB=""
for _c in "${EVAL_LIB:-}" "$HERE/../lib-transcripts.sh" "$PROJECT_ROOT/modules/09-prompt-library/usage-digest/lib-transcripts.sh"; do
  [ -n "$_c" ] && [ -f "$_c" ] && { LIB="$_c"; break; }
done

TARGET="--all"; DO_BASELINE=0; STRICT=0
for a in "$@"; do
  case "$a" in
    --baseline) DO_BASELINE=1 ;;
    --strict)   STRICT=1 ;;
    --all)      TARGET="--all" ;;
    -*)         echo "unknown flag: $a" >&2; exit 2 ;;
    *)          TARGET="$a" ;;
  esac
done

# --- expectations ---
declare -A EXP_ARG EXP_ANALYZER EXP_ROLE
while IFS=$'\t' read -r name arg analyzer role; do
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue ;; esac
  EXP_ARG["$name"]="$arg"
  EXP_ANALYZER["$name"]="$analyzer"
  EXP_ROLE["$name"]="$role"
done < "$EXPECT"

# --- usage (for ranking): name -> number of invocations ---
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

FAILFILE="$(mktemp)"; SKIPFILE="$(mktemp)"
trap 'rm -f "$FAILFILE" "$SKIPFILE"' EXIT
# Inside the kit (module sources present) the requirements are stricter than in a vendored project.
IN_KIT=0; [ -d "$PROJECT_ROOT/modules/09-prompt-library" ] && IN_KIT=1

# --- checks for one command: prints "passed total"; failure details -> FAILFILE ---
eval_one() {
  local name="$1" f="$CMD_DIR/$1.md"
  local passed=0 total=0 body role ok
  if [ ! -f "$f" ]; then
    echo "  [$name] command file missing" >> "$FAILFILE"; echo "0 1"; return
  fi
  if [ -z "${EXP_ARG[$name]:-}" ]; then
    # Inside the kit a new command with no expectations row is a failure: intent
    # has to be declared deliberately. In someone else's project their own
    # commands are out of our jurisdiction - they go to a separate "outside
    # expectations" list rather than counting as failures, so the metric stays
    # honest.
    if [ "$IN_KIT" -eq 1 ]; then
      echo "  [$name] no row in expectations.tsv" >> "$FAILFILE"; echo "0 1"
    else
      echo "$name" >> "$SKIPFILE"; echo "skip"
    fi
    return
  fi
  body="$(cat "$f")"

  check() { # check <ok?0=pass> <msg>
    total=$((total+1))
    if [ "$1" -eq 0 ]; then passed=$((passed+1)); else
      echo "  [$name] $2" >> "$FAILFILE"; fi
  }
  has()  { printf '%s' "$body" | grep -qE "$1"; }   # case-sensitive (structure)
  hasi() { printf '%s' "$body" | grep -qiE "$1"; }  # case-insensitive (prose)

  # U1 frontmatter: --- ... description: ... ---
  # The first line is taken by parameter expansion, not "| head -1": under
  # pipefail head closes the pipe early, printf takes SIGPIPE, and the whole
  # condition fails for a long command file - a FAIL that is not real.
  if [ "${body%%$'\n'*}" = "---" ] \
     && has '^description:' \
     && [ "$(printf '%s' "$body" | grep -c '^---$')" -ge 2 ]; then
    check 0 ""; else check 1 "broken frontmatter (--- / description:)"; fi

  # U2 no em dash used as punctuation (" -- " or word--word). Frontmatter fences
  # (---) and CLI flags (--sort) do not count.
  if printf '%s' "$body" | grep -v '^---$' | grep -qE ' -- |[[:alnum:]]--[[:alnum:]]'; then
    check 1 "em dash found (--)"; else check 0 ""; fi

  # U3 a reference to an .ai/ role file MUST be conditional ("if the project has ...").
  # Commands are written in English; the Russian alternatives are here so that a
  # command written in the owner's language is still judged on its guarantee.
  if has '\.ai/[A-Z]'; then
    if hasi 'if .*\.ai/|\.ai/.*(exists|is present)|if the project has|если.*\.ai/|\.ai/.*(есть|нет)|если в проекте'; then
      check 0 ""; else check 1 ".ai/ role referenced unconditionally (needs \"if ...\")"; fi
  fi

  # C1 argument: needs_arg=y -> has $ARGUMENTS/$1, argument-hint, and a fallback
  if [ "${EXP_ARG[$name]}" = "y" ]; then
    ok=0
    has '\$ARGUMENTS|\$1' || ok=1
    grep -q '^argument-hint:' "$f" || ok=1
    hasi 'otherwise|ask|if .*(is )?(not )?given|if none|if no |иначе|спроси|если задан|если задана|если задано|если.*не задан|если.*нет|не задан' || ok=1
    check "$ok" "argument declared, but argument-hint / \$ARGUMENTS / fallback is missing"
  fi

  # C2 analyzer=y -> guard
  if [ "${EXP_ANALYZER[$name]}" = "y" ]; then
    if hasi 'do not write code|do not commit|do not change|do not start|do not run it yourself|не пиши код|ничего не коммить|ничего не меняй|не начинай|пока не пиши|реализацию не начинай'; then
      check 0 ""; else check 1 "analyzer without a guard (do not write code / do not change / do not start)"; fi
  fi

  # C3 ai_role
  role="${EXP_ROLE[$name]}"
  if [ "$role" = "MULTI" ]; then
    if has 'PATTERNS\.md'; then check 0 ""; else
      check 1 "multi-role, but no reference to the PATTERNS.md map"; fi
  elif [ "$role" != "-" ] && [ -n "$role" ]; then
    if has "\\.ai/$role"; then check 0 ""; else
      check 1 "no conditional reference to .ai/$role"; fi
  fi

  echo "$passed $total"
}

# --- which commands to evaluate ---
mapfile -t NAMES < <(
  if [ "$TARGET" = "--all" ]; then
    for f in "$CMD_DIR"/*.md; do basename "$f" .md; done
  else printf '%s\n' "$TARGET"; fi
)

# rank: used commands first (by USE, then by name)
mapfile -t NAMES < <(
  for n in "${NAMES[@]}"; do printf '%s\t%s\n' "${USE[$n]:-0}" "$n"; done \
    | sort -k1,1rn -k2,2 | cut -f2
)

# --- baseline for deltas ---
declare -A BASE
BASELINE_F="$OUT_DIR/baseline.tsv"
if [ -f "$BASELINE_F" ]; then
  while IFS=$'\t' read -r n p t; do [ -n "${n:-}" ] && BASE["$n"]="$p"; done < "$BASELINE_F"
fi

mkdir -p "$OUT_DIR"
DATE="$(date '+%Y-%m-%d')"
SCORE_TSV="$OUT_DIR/scorecard.tsv"; : > "$SCORE_TSV"

TOTAL_P=0; TOTAL_T=0; ROWS=""; SCORED=0
for n in "${NAMES[@]}"; do
  read -r p t < <(eval_one "$n")
  [ "$p" = "skip" ] && continue
  SCORED=$((SCORED+1))
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

# Layer 2 (behavior): coverage reported honestly. The layer 1 metric is about
# the structure of the sources, NOT about behavior; how many commands were
# actually judged is read from the most recent judge report.
#
# A report (see judge/scorecard-template.md) states its own coverage in a
# machine-readable line: "layer2-summary: commands=<n> cases=<m> agreement=<p>".
# A report without that line is treated as not run - the line is part of the
# format's contract, not an optional nicety.
JUDGE_LINE="layer 2 (behavior, LLM judge): not run - use /eval-command --judge"
JUDGE_F="$(ls -1 "$OUT_DIR"/judge-*.md 2>/dev/null | sort | tail -1 || true)"
if [ -n "${JUDGE_F:-}" ]; then
  J_SUM="$(grep -m1 '^layer2-summary:' "$JUDGE_F" || true)"
  if [ -n "$J_SUM" ]; then
    J_N="$(printf '%s' "$J_SUM" | sed -n 's/.*commands=\([0-9][0-9]*\).*/\1/p')"
    J_C="$(printf '%s' "$J_SUM" | sed -n 's/.*cases=\([0-9][0-9]*\).*/\1/p')"
    J_A="$(printf '%s' "$J_SUM" | sed -n 's/.*agreement=\([0-9][0-9]*\).*/\1/p')"
    JUDGE_LINE="layer 2 (behavior, two judges): ${J_N:-?} of $SCORED commands, ${J_C:-?} cases, judges agree on ${J_A:-?}% ($(basename "$JUDGE_F"))"
  fi
fi

REPORT="Command Evals - $DATE
layer 1 (source structure): $SCORED commands, checks passed: $TOTAL_P/$TOTAL_T (${OVERALL}%)
$JUDGE_LINE

${ROWS}"
if [ -s "$SKIPFILE" ]; then
  REPORT="${REPORT}
Outside expectations (the project's own commands, not scored - add rows to expectations.tsv to include them):
$(sed 's/^/  /' "$SKIPFILE")"
fi
if [ -s "$FAILFILE" ]; then
  REPORT="${REPORT}
Failed checks:
$(cat "$FAILFILE")"
fi

echo "$REPORT"
{ echo "# Command Evals scorecard - $DATE"; echo; echo '```'; echo "$REPORT"; echo '```'; } > "$OUT_DIR/scorecard.md"

if [ "$DO_BASELINE" -eq 1 ]; then
  cp "$SCORE_TSV" "$BASELINE_F"
  echo "(baseline saved: $BASELINE_F)"
fi

if [ "$STRICT" -eq 1 ] && [ "$TOTAL_P" -lt "$TOTAL_T" ]; then exit 1; fi
exit 0
