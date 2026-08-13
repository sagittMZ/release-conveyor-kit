#!/bin/bash
# mkfixture.sh - build a throwaway repository for a layer 2 eval case.
#
# Layer 2 judges behavior, and a large part of behavior only shows against a
# real repository state: an empty git, a diff too large to read, a binary file,
# no tags to compare. Those states cannot be simulated by asking a model to
# imagine them, so they are generated here and the command is really run
# against them (see run-case.sh).
#
# Fixtures are built in a temporary directory and are never committed. Each one
# is stamped with .git/eval-fixture, which is what run-case.sh requires before
# it will dispatch anything - a real repository does not have that file.
#
# Usage:
#   mkfixture.sh --list
#   mkfixture.sh <kind> [dir]
#
# With no dir, the fixture goes to ${TMPDIR:-/tmp}/command-evals/<kind>-<pid>.
# The path is printed on stdout, so it can be captured:
#   fx="$(mkfixture.sh dirty)"

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Where the commands to vendor into a fixture come from. Resolved the same way
# eval.sh resolves them, so this works both inside the kit and after the module
# has been vendored into a project as tools/prompt-kit/command-evals/.
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [ -n "${EVAL_CMD_DIR:-}" ]; then CMD_SRC="$EVAL_CMD_DIR"
elif [ -d "$PROJECT_ROOT/.claude/commands" ]; then CMD_SRC="$PROJECT_ROOT/.claude/commands"
else CMD_SRC="$HERE/../../09-prompt-library/commands"; fi

KINDS="dirty empty-git huge-diff binary tagged tagged-one vuln backlog no-backlog app"

die() { echo "!! $1" >&2; exit 2; }

usage() {
  sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  echo
  echo "kinds: $KINDS"
}

case "${1:-}" in
  --list) echo "$KINDS"; exit 0 ;;
  -h|--help|"") usage; exit 0 ;;
esac

KIND="$1"
case " $KINDS " in
  *" $KIND "*) ;;
  *) echo "!! unknown kind: $KIND (see --list)" >&2; exit 2 ;;
esac

DIR="${2:-${TMPDIR:-/tmp}/command-evals/$KIND-$$}"
case "$DIR" in
  ""|"/"|"$HOME") echo "!! refusing to build a fixture in $DIR" >&2; exit 2 ;;
esac

# An existing directory is only reused when it is a fixture we made. Anything
# else - a real project, a home directory - is left alone.
if [ -e "$DIR" ]; then
  if [ -f "$DIR/.git/eval-fixture" ]; then rm -rf "${DIR:?}"
  else echo "!! $DIR exists and is not a fixture - refusing to touch it" >&2; exit 2; fi
fi
mkdir -p "$DIR"

# Fixture git identity: never the operator's. commit.gpgsign is off because a
# signing prompt would hang a headless run.
fx_git() {
  git -C "$DIR" \
    -c user.name='Eval Fixture' \
    -c user.email='fixture@example.invalid' \
    -c commit.gpgsign=false \
    -c core.hooksPath=/dev/null \
    "$@"
}

fx_init() {
  git init -q "$DIR"
  fx_git symbolic-ref HEAD refs/heads/main
  # The kit's own commands, so the fixture can dispatch the real slash command
  # rather than a paraphrase of it. They live in .git/info/exclude rather than
  # in a .gitignore file: an ignore rule inside .git is invisible to git status
  # and to the working tree, so a fixture that is supposed to look empty really
  # does look empty to the command under test.
  mkdir -p "$DIR/.claude/commands"
  [ -d "$CMD_SRC" ] || die "no command directory at $CMD_SRC - set EVAL_CMD_DIR"
  cp "$CMD_SRC"/*.md "$DIR/.claude/commands/"
  printf '.claude/\n' >> "$DIR/.git/info/exclude"
  printf 'kind=%s\nbuilt=%s\nnote=throwaway eval fixture, safe to delete\n' \
    "$KIND" "$(date '+%Y-%m-%dT%H:%M:%S')" > "$DIR/.git/eval-fixture"
}

# .claude/ is already excluded through .git/info/exclude, so a plain add -A
# never picks it up - no pathspec gymnastics needed.
fx_commit() { fx_git add -A; fx_git commit -q -m "$1"; }

# --- shared scaffolding ---------------------------------------------------

seed_app() {
  mkdir -p "$DIR/src" "$DIR/docs"
  cat > "$DIR/README.md" <<'EOF'
# Notes

A small invented application. Nothing here is real code from any project.
EOF
  cat > "$DIR/src/cart.js" <<'EOF'
export function subtotal(items) {
  let sum = 0;
  for (let i = 0; i < items.length; i++) {
    sum += items[i].price * items[i].qty;
  }
  return sum;
}

export function applyDiscount(sum, percent) {
  return sum - (sum * percent) / 100;
}
EOF
  cat > "$DIR/src/api.js" <<'EOF'
import { subtotal } from './cart.js';

export async function checkout(req, res) {
  const items = req.body.items || [];
  return res.json({ total: subtotal(items) });
}
EOF
}

# --- kinds ----------------------------------------------------------------

build_dirty() {
  fx_init; seed_app; fx_commit "initial commit"
  # Three planted defects in the working tree: an off-by-one, a leftover debug
  # line, and a hardcoded credential. The credential is assembled at run time
  # from fragments and random characters on purpose - a literal key in this
  # file would trip the kit's own gitleaks gate, which is exactly the rule the
  # planted defect is meant to test in someone else's repository.
  local p1='sk' p2='live' tail
  tail="$(head -c 64 /dev/urandom | base64 | LC_ALL=C tr -dc 'A-Za-z0-9' | cut -c1-24)"
  cat > "$DIR/src/cart.js" <<'EOF'
export function subtotal(items) {
  let sum = 0;
  for (let i = 0; i <= items.length; i++) {
    sum += items[i].price * items[i].qty;
  }
  return sum;
}

export function applyDiscount(sum, percent) {
  return sum - (sum * percent) / 100;
}
EOF
  {
    printf 'import { subtotal } from '\''./cart.js'\'';\n\n'
    printf 'const PAYMENT_KEY = "%s_%s_%s";\n\n' "$p1" "$p2" "$tail"
    printf 'export async function checkout(req, res) {\n'
    printf '  const items = req.body.items || [];\n'
    printf '  console.log("checkout debug", req.body, PAYMENT_KEY);\n'
    printf '  return res.json({ total: subtotal(items) });\n'
    printf '}\n'
  } > "$DIR/src/api.js"
}

build_empty_git() {
  # Nothing but an initialized repository: no commits, no changes, no files
  # the command under test can see.
  fx_init
}

build_huge_diff() {
  fx_init; mkdir -p "$DIR/src"
  local i j
  for i in $(seq 1 40); do
    { for j in $(seq 1 150); do printf 'export const value_%d_%d = %d;\n' "$i" "$j" "$((i * j))"; done; } > "$DIR/src/mod_$i.ts"
  done
  fx_commit "initial commit"
  # Every line of every file rewritten: 40 files, ~12000 diff lines.
  for i in $(seq 1 40); do
    { for j in $(seq 1 150); do printf 'export const value_%d_%d = %d; // reworked\n' "$i" "$j" "$((i + j))"; done; } > "$DIR/src/mod_$i.ts"
  done
}

build_binary() {
  fx_init; seed_app; fx_commit "initial commit"
  mkdir -p "$DIR/assets"
  head -c 262144 /dev/urandom > "$DIR/assets/blob.bin"
  fx_git add assets/blob.bin
}

seed_history() {
  fx_init; seed_app; fx_commit "initial commit"
  local msgs=(
    "add a cart summary panel"
    "fix a rounding error in the subtotal"
    "add keyboard navigation to the item list"
    "fix the empty cart state"
    "rename the checkout endpoint (breaking change for API clients)"
    "add a discount code field"
    "fix a crash when the price is missing"
    "speed up the item list rendering"
    "add an order confirmation screen"
    "fix the back button on the confirmation screen"
    "drop support for the legacy cart format (breaking change)"
  )
  local n=0 m
  for m in "${msgs[@]}"; do
    n=$((n + 1))
    printf '// change %d: %s\n' "$n" "$m" >> "$DIR/src/cart.js"
    fx_commit "$m"
    # An "if" and not "[ ] && ...": under set -e a false test as the last
    # command of the loop body would end the whole script.
    if [ "$n" -eq 4 ]; then fx_git tag v1.0.0; fi
  done
}

build_tagged()     { seed_history; fx_git tag v1.1.0; }
build_tagged_one() { seed_history; }

build_vuln() {
  fx_init; mkdir -p "$DIR/src/api"
  # Invented insecure patterns, not code from anywhere. No literal credentials:
  # the point is the pattern, and a real key here would be a defect of its own.
  cat > "$DIR/src/api/reports.js" <<'EOF'
import { createClient } from '@supabase/supabase-js';

// Runs in a user-facing request path.
const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

export async function getReport(req, res) {
  const id = req.query.id;
  const rows = await db.raw("select * from reports where id = '" + id + "'");
  return res.json(rows);
}

export async function deleteReport(req, res) {
  if (req.body.isAdmin) {
    await db.raw("delete from reports where id = '" + req.query.id + "'");
    return res.json({ ok: true });
  }
  return res.status(403).json({ ok: false });
}
EOF
  cat > "$DIR/src/api/session.js" <<'EOF'
export function cookieOptions() {
  return { httpOnly: false, secure: false, sameSite: 'none', maxAge: 31536000 };
}
EOF
  fx_commit "initial commit"
}

seed_backlog_items() {
  cat > "$DIR/BACKLOG.md" <<'EOF'
# Backlog

1. [high] Introduce a sessions table in the database
2. [low] A user login history screen (reads sessions)
3. [high] Optimize the landing page
4. [medium] Refactor navigation
5. [low] Fix a typo in the footer
6. [medium] Add CSV export to the item list
7. [low] Replace the favicon
EOF
}

build_backlog()    { fx_init; seed_app; seed_backlog_items; fx_commit "initial commit"; }
build_no_backlog() { fx_init; seed_app; fx_commit "initial commit"; }

build_app() {
  fx_init; seed_app
  mkdir -p "$DIR/src/payments" "$DIR/src/__tests__" "$DIR/docs"
  # Deliberate material for a role-lens review: a money path with no tests, a
  # secret named in an example file (a name, never a value), a session snapshot.
  cat > "$DIR/src/payments/charge.js" <<'EOF'
export async function charge(userId, amountCents) {
  const res = await fetch('https://payments.example.invalid/charge', {
    method: 'POST',
    body: JSON.stringify({ userId, amountCents }),
  });
  return res.json();
}
EOF
  cat > "$DIR/src/__tests__/cart.test.js" <<'EOF'
import { subtotal } from '../cart.js';

test('subtotal adds up', () => {
  expect(subtotal([{ price: 100, qty: 2 }])).toBe(200);
});
EOF
  cat > "$DIR/.env.example" <<'EOF'
# Names only. Values live in the deployment environment.
PAYMENTS_API_KEY=
DATABASE_URL=
EOF
  cat > "$DIR/docs/.session-current.md" <<'EOF'
# Session snapshot

Done: the cart subtotal. Next: the payments path. Blockers: none.
EOF
  seed_backlog_items
  fx_commit "initial commit"
}

case "$KIND" in
  dirty)      build_dirty ;;
  empty-git)  build_empty_git ;;
  huge-diff)  build_huge_diff ;;
  binary)     build_binary ;;
  tagged)     build_tagged ;;
  tagged-one) build_tagged_one ;;
  vuln)       build_vuln ;;
  backlog)    build_backlog ;;
  no-backlog) build_no_backlog ;;
  app)        build_app ;;
esac

echo "$DIR"
