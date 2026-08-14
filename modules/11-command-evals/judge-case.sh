#!/bin/bash
# judge-case.sh - run one judge over one prepared answer, headless.
#
# The judging half of layer 2, the mirror of run-case.sh. A judge gets the judge
# prompt, the rubric and a bundle assembled by the caller (command text, case
# input, the answer, expect/avoid), and returns SCORE/PASS/NOTES.
#
# Each judge runs in its own session, so "a fresh context" is a fact of how it
# was invoked rather than a promise in a prompt: a judge cannot see the other
# judge's score, the executor's reasoning, or the session that orchestrates the
# run. The model comes from models.json by role, never from a name in a prompt.
#
# Usage:
#   judge-case.sh --bundle <file> [--role JUDGE_A] [--model <model>]
#                 [--out <file>] [--meta <file>] [--timeout <seconds>]
#
# The bundle is the case-specific half of the prompt, in the order the judge
# prompt expects: THE COMMAND TEXT, THE CASE INPUT, THE ANSWER, THE CASE
# EXPECTATIONS. Everything general - the anchors, the rubric, the output format
# - is added here, identically for both judges.
#
# Exit codes: 0 ok, 2 bad usage, 3 the session failed, 4 the answer carried no
# SCORE/PASS lines, 5 timed out.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS="$HERE/models.json"
JUDGE_PROMPT="$HERE/judge/judge-prompt.md"
RUBRIC="$HERE/RUBRIC.md"

BUNDLE=""; ROLE="JUDGE_A"; MODEL=""; OUT=""; META=""
TIMEOUT="${EVAL_JUDGE_TIMEOUT:-600}"

die() { echo "!! $1" >&2; exit "${2:-2}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --bundle)  BUNDLE="${2:-}"; shift 2 ;;
    --role)    ROLE="${2:-}"; shift 2 ;;
    --model)   MODEL="${2:-}"; shift 2 ;;
    --out)     OUT="${2:-}"; shift 2 ;;
    --meta)    META="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown flag: $1" ;;
  esac
done

[ -n "$BUNDLE" ] || die "--bundle is required"
[ -f "$BUNDLE" ] || die "no bundle file at $BUNDLE"
[ -f "$JUDGE_PROMPT" ] || die "no judge prompt at $JUDGE_PROMPT"
[ -f "$RUBRIC" ] || die "no rubric at $RUBRIC"
command -v claude >/dev/null 2>&1 || die "the claude CLI is not on PATH" 3

if [ -z "$MODEL" ]; then
  [ -f "$MODELS" ] || die "models.json not found at $MODELS"
  MODEL="$(sed -n "s/^[[:space:]]*\"$ROLE\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$MODELS" | head -1)"
  [ -n "$MODEL" ] || die "role $ROLE has no model in $MODELS"
fi

prompt="$(mktemp)"; raw="$(mktemp)"; err="$(mktemp)"
# A judge session gets no repository: it is scored material, not a project. An
# empty directory means a judge that wanders off to read files finds nothing,
# which is the intended blindness rather than an accident.
work="$(mktemp -d)"
cleanup() { rm -f "$prompt" "$raw" "$err"; rm -rf "$work"; }
trap cleanup EXIT

{
  cat "$JUDGE_PROMPT"
  printf '\n\n# RUBRIC.md (the anchor referred to above)\n\n'
  cat "$RUBRIC"
  printf '\n\n# The material to judge\n\n'
  cat "$BUNDLE"
} > "$prompt"

if command -v python3 >/dev/null 2>&1; then FMT=json; else FMT=text; fi

echo "-- judge: role=$ROLE model=$MODEL bundle=$(basename "$BUNDLE")" >&2
started="$(date +%s)"
rc=0
(
  cd "$work"
  timeout "$TIMEOUT" claude -p "$(cat "$prompt")" \
    --model "$MODEL" \
    --strict-mcp-config \
    --no-session-persistence \
    --output-format "$FMT" < /dev/null
) > "$raw" 2> "$err" || rc=$?
elapsed=$(( $(date +%s) - started ))

[ "$rc" -eq 124 ] && die "the judge timed out after ${TIMEOUT}s" 5
if [ "$rc" -ne 0 ]; then
  echo "!! the judge session failed with exit code $rc" >&2
  tail -20 "$err" >&2; exit 3
fi

cost="unknown"
if [ "$FMT" = "json" ]; then
  verdict="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
sys.stdout.write(d.get("result") or "")' "$raw" 2>/dev/null || true)"
  cost="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
c=d.get("total_cost_usd")
u=d.get("usage") or {}
print("usd=%s in=%s out=%s" % (c, u.get("input_tokens"), u.get("output_tokens")))' "$raw" 2>/dev/null || echo "unknown")"
  [ -n "$verdict" ] || verdict="$(cat "$raw")"
else
  verdict="$(cat "$raw")"
fi

# A verdict without a score is not a lenient verdict, it is a failed judge run.
# Scoring it as anything would put a number in the scorecard that nobody gave.
if ! printf '%s' "$verdict" | grep -qE '^SCORE:[[:space:]]*[0-5]' \
   || ! printf '%s' "$verdict" | grep -qiE '^PASS:[[:space:]]*(yes|no)'; then
  echo "!! the judge returned no SCORE/PASS lines" >&2
  printf '%s\n' "$verdict" | head -5 >&2
  exit 4
fi

meta_line="role=$ROLE model=$MODEL bundle=$(basename "$BUNDLE") seconds=$elapsed $cost"
echo "-- done: $meta_line" >&2
[ -n "$META" ] && printf '%s\n' "$meta_line" > "$META"

if [ -n "$OUT" ]; then printf '%s\n' "$verdict" > "$OUT"; echo "-- verdict: $OUT" >&2
else printf '%s\n' "$verdict"; fi
