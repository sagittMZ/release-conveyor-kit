#!/bin/bash
# run-case.sh - dispatch a real slash command against a generated fixture.
#
# This is the executor half of layer 2. It runs the actual command - frontmatter,
# $ARGUMENTS, tool access and all - in a headless Claude Code session whose
# working directory is a throwaway repository built by fixtures/mkfixture.sh.
# Asking a model what a command "would answer" is not the same experiment: the
# states that matter most (empty git, a diff too large to read, a binary file,
# no tags) only exist in a real repository.
#
# SAFETY. The session runs with permissions bypassed, because a command that has
# to ask for every git invocation cannot be measured. That is only acceptable
# because of the guards below: the target must be a directory stamped
# .git/eval-fixture by the generator, must be its own git root, must have no
# remote, and must not sit inside the repository this script was invoked from.
# Any of those failing is a hard stop, never a warning.
#
# WHAT THE ANSWER INCLUDES. By default the dispatched session is the operator's
# own: their global CLAUDE.md, their hooks and their plugins all apply, and they
# change what comes back. That was measured, not assumed - see fixtures/README.md
# - so the environment is recorded in the meta line instead of being pretended
# away. --isolated runs against an empty config directory instead, which needs an
# auth method that does not live in the operator's config (ANTHROPIC_API_KEY or
# an apiKeyHelper); this script never reads or copies credentials itself.
#
# Usage:
#   run-case.sh --fixture <dir> --command <name> [--arg <text>]
#               [--role EXECUTOR] [--model <model>] [--out <file>]
#               [--meta <file>] [--timeout <seconds>] [--isolated]
#
# Exit codes: 0 ok, 2 bad usage or a refused target, 3 the session failed,
# 4 the session returned an empty answer, 5 timed out.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS="$HERE/models.json"

FIXTURE=""; COMMAND=""; ARG=""; ROLE="EXECUTOR"; MODEL=""
OUT=""; META=""; TIMEOUT="${EVAL_TIMEOUT:-600}"; ISOLATED=0
PERM="${EVAL_PERMISSION_MODE:-bypassPermissions}"

die() { echo "!! $1" >&2; exit "${2:-2}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --fixture) FIXTURE="${2:-}"; shift 2 ;;
    --command) COMMAND="${2:-}"; shift 2 ;;
    --arg)     ARG="${2:-}"; shift 2 ;;
    --role)    ROLE="${2:-}"; shift 2 ;;
    --model)   MODEL="${2:-}"; shift 2 ;;
    --out)     OUT="${2:-}"; shift 2 ;;
    --meta)    META="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    --isolated) ISOLATED=1; shift ;;
    -h|--help) sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown flag: $1" ;;
  esac
done

[ -n "$FIXTURE" ] || die "--fixture is required"
[ -n "$COMMAND" ] || die "--command is required"
command -v claude >/dev/null 2>&1 || die "the claude CLI is not on PATH" 3

# --- guards: refuse anything that is not a generated fixture ---------------

[ -d "$FIXTURE" ] || die "fixture directory not found: $FIXTURE"
FIXTURE="$(cd "$FIXTURE" && pwd -P)"

[ -f "$FIXTURE/.git/eval-fixture" ] \
  || die "$FIXTURE carries no .git/eval-fixture stamp - only generated fixtures may be dispatched into"

top="$(git -C "$FIXTURE" rev-parse --show-toplevel 2>/dev/null || true)"
[ "$top" = "$FIXTURE" ] \
  || die "$FIXTURE is not its own git root (git says: ${top:-none}) - it may be nested in a real repository"

[ -z "$(git -C "$FIXTURE" remote 2>/dev/null)" ] \
  || die "$FIXTURE has a git remote - a fixture never does, so this looks like a real repository"

# The repository this script was invoked from is the most likely thing to
# destroy by accident, so the fixture is not allowed to live inside it.
here_top="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$here_top" ]; then
  here_top="$(cd "$here_top" && pwd -P)"
  case "$FIXTURE/" in
    "$here_top"/*) die "$FIXTURE is inside the working repository $here_top - refusing to dispatch" ;;
  esac
fi

# --- model: an alias from models.json, never a name written into a prompt ---

if [ -z "$MODEL" ]; then
  [ -f "$MODELS" ] || die "models.json not found at $MODELS"
  MODEL="$(sed -n "s/^[[:space:]]*\"$ROLE\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$MODELS" | head -1)"
  [ -n "$MODEL" ] || die "role $ROLE has no model in $MODELS"
fi

# --- dispatch --------------------------------------------------------------

PROMPT="/$COMMAND"
if [ -n "$ARG" ]; then PROMPT="/$COMMAND $ARG"; fi

# The JSON output carries what the run cost, which the scorecard has to report.
# Without python3 the run still happens, it just cannot state its own price.
if command -v python3 >/dev/null 2>&1; then FMT=json; else FMT=text; fi

err="$(mktemp)"; raw="$(mktemp)"
CONF=""
if [ "$ISOLATED" -eq 1 ]; then
  # An empty config directory: no global CLAUDE.md, no hooks, no plugins. The
  # session has to authenticate on its own, and fails loudly if it cannot.
  CONF="$(mktemp -d)"
fi
cleanup() { rm -f "$err" "$raw"; if [ -n "$CONF" ]; then rm -rf "$CONF"; fi; }
trap cleanup EXIT

echo "-- dispatch: /$COMMAND ${ARG:+\"$ARG\"} | model=$MODEL role=$ROLE | fixture=$FIXTURE" >&2
started="$(date +%s)"
rc=0
env_note="operator-config"
if [ "$ISOLATED" -eq 1 ]; then env_note="isolated-config"; fi
(
  cd "$FIXTURE"
  if [ -n "$CONF" ]; then export CLAUDE_CONFIG_DIR="$CONF"; fi
  timeout "$TIMEOUT" claude -p "$PROMPT" \
    --model "$MODEL" \
    --permission-mode "$PERM" \
    --strict-mcp-config \
    --no-session-persistence \
    --output-format "$FMT" < /dev/null
) > "$raw" 2> "$err" || rc=$?
elapsed=$(( $(date +%s) - started ))

if [ "$rc" -eq 124 ]; then
  die "the session timed out after ${TIMEOUT}s (/$COMMAND on $FIXTURE)" 5
fi
if [ "$rc" -ne 0 ]; then
  echo "!! the session failed with exit code $rc (/$COMMAND on $FIXTURE)" >&2
  echo "-- stderr tail:" >&2; tail -20 "$err" >&2
  exit 3
fi

cost="unknown"
is_error=""
if [ "$FMT" = "json" ]; then
  is_error="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
print("yes" if d.get("is_error") or d.get("subtype") not in (None,"success") else "")' "$raw" 2>/dev/null || true)"
  answer="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
sys.stdout.write(d.get("result") or "")' "$raw" 2>/dev/null || true)"
  cost="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
c=d.get("total_cost_usd")
u=d.get("usage") or {}
print("usd=%s in=%s out=%s" % (c, u.get("input_tokens"), u.get("output_tokens")))' "$raw" 2>/dev/null || echo "unknown")"
  # A parse failure must not masquerade as an empty answer.
  [ -n "$answer" ] || answer="$(cat "$raw")"
else
  answer="$(cat "$raw")"
fi

if [ -z "$(printf '%s' "$answer" | tr -d '[:space:]')" ]; then
  echo "!! the session returned an empty answer (/$COMMAND on $FIXTURE)" >&2
  echo "-- stderr tail:" >&2; tail -20 "$err" >&2
  exit 4
fi

# A session can exit 0 and still not have run the command: an unresolved slash
# command comes back as a one-line "Unknown command" that would otherwise be
# scored as if it were the command's answer. Non-answers fail loudly.
if [ -n "$is_error" ] || printf '%s' "$answer" | head -3 | grep -qiE '^(Unknown command|Command not found|Error:)'; then
  echo "!! the session did not run the command (/$COMMAND on $FIXTURE)" >&2
  echo "-- what came back instead:" >&2; printf '%s\n' "$answer" | head -5 >&2
  echo "-- stderr tail:" >&2; tail -20 "$err" >&2
  exit 3
fi

meta_line="command=/$COMMAND role=$ROLE model=$MODEL fixture=$(basename "$FIXTURE") env=$env_note seconds=$elapsed $cost"
echo "-- done: $meta_line" >&2
if [ -n "$META" ]; then printf '%s\n' "$meta_line" > "$META"; fi

if [ -n "$OUT" ]; then printf '%s\n' "$answer" > "$OUT"; echo "-- answer: $OUT" >&2
else printf '%s\n' "$answer"; fi
