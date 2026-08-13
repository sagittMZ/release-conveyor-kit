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
#   mkfixture.sh --clean <dir>
#
# With no dir, the fixture goes to ${TMPDIR:-/tmp}/command-evals/<kind>-<pid>.
# The path is printed on stdout, so it can be captured:
#   fx="$(mkfixture.sh dirty)"
#
# A few kinds need material OUTSIDE the fixture, because that is where the
# command under test looks for it: the memory kinds write into
# <claude-config>/projects/<encoded-fixture-path>/, which is the rule module 12
# follows on every platform. That directory is named after the fixture's own
# temporary path, so it can never collide with a real project's memory, it is
# stamped like the fixture itself, and --clean removes both halves.

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
KINDS="$KINDS memory memory-empty memory-conflict arch arch-stale arch-broken commands"

die() { echo "!! $1" >&2; exit 2; }

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  echo
  echo "kinds: $KINDS"
}

# Remove a fixture and whatever it put outside itself. Only ever touches a
# directory carrying the generator's own stamp.
clean_fixture() {
  local d="${1:-}" aux
  [ -n "$d" ] || die "--clean needs a directory"
  [ -f "$d/.git/eval-fixture" ] || die "$d carries no .git/eval-fixture stamp - refusing to delete it"
  aux="$(sed -n 's/^aux=//p' "$d/.git/eval-fixture" | head -1)"
  if [ -n "$aux" ] && [ -f "$aux/.eval-fixture-aux" ]; then
    rm -rf "${aux:?}"; echo "removed: $aux"
  fi
  rm -rf "${d:?}"; echo "removed: $d"
}

case "${1:-}" in
  --list) echo "$KINDS"; exit 0 ;;
  --clean) clean_fixture "${2:-}"; exit 0 ;;
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
# The physical path, because the command under test derives the memory path from
# `git rev-parse --show-toplevel`, which is resolved. A fixture reached through a
# symlinked /tmp would otherwise get material in a directory nobody reads.
DIR="$(cd "$DIR" && pwd -P)"

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

# --- sources a fixture may have to vendor ---------------------------------

# Neighbouring modules sit one level up in both layouts: modules/13-arch-viz in
# the kit, tools/prompt-kit/arch-viz after rollout. Try both names.
find_src() { # find_src <kit-name> <vendored-name>
  local c
  for c in "$HERE/../../$1" "$HERE/../../$2"; do
    if [ -d "$c" ]; then (cd "$c" && pwd -P); return 0; fi
  done
  die "cannot find the source of $2 (looked for $1 and $2 next to $HERE/..)"
}

# Some fixtures have to look like a project the kit was rolled out into, because
# that is the layout the command under test will meet in the wild. The layout and
# the two path rewrites below are ROLLOUT.md steps 4 and 5, not an invention.
vendor_arch_viz() {
  local src; src="$(find_src 13-arch-viz arch-viz)"
  mkdir -p "$DIR/tools/prompt-kit/arch-viz"
  cp "$src/build-arch-viz.sh" "$src/template.html" "$src/README.md" \
     "$DIR/tools/prompt-kit/arch-viz/"
}

vendor_command_evals() {
  local src="$HERE/.."
  mkdir -p "$DIR/tools/prompt-kit/command-evals"
  cp "$src/eval.sh" "$src/run-case.sh" "$src/models.json" "$src/expectations.tsv" \
     "$src/RUBRIC.md" "$src/README.md" "$DIR/tools/prompt-kit/command-evals/"
  cp -r "$src/judge" "$DIR/tools/prompt-kit/command-evals/judge"
  # cases/ and fixtures/ are deliberately NOT vendored here: a project that has
  # no cases yet is exactly the state one of the /eval-command cases is about.
  # eval.sh looks for its transcript library next to itself once vendored.
  local lib
  for lib in "$HERE/../../09-prompt-library/usage-digest/lib-transcripts.sh" \
             "$HERE/../../lib-transcripts.sh"; do
    if [ -f "$lib" ]; then cp "$lib" "$DIR/tools/prompt-kit/"; break; fi
  done
  # ROLLOUT step 5: the two meta-commands carry kit-relative paths on purpose,
  # and a vendored copy has to have them rewritten or it points at nothing.
  local f
  for f in eval-command consolidate-memory; do
    [ -f "$DIR/.claude/commands/$f.md" ] || continue
    sed -i \
      -e 's#modules/09-prompt-library/commands/#.claude/commands/#g' \
      -e 's#modules/11-command-evals/#tools/prompt-kit/command-evals/#g' \
      -e 's#modules/12-memory-consolidation/#tools/prompt-kit/memory-consolidation/#g' \
      "$DIR/.claude/commands/$f.md"
  done
}

# --- material that has to live outside the fixture -------------------------

# Module 12 keeps raw material and memory OUTSIDE the git tree (record 9 in
# ARCHITECTURE.md), so a fixture for /consolidate-memory has to write where the
# command will actually look: <claude-config>/projects/<encoded-repo-root>/.
AUX=""
aux_init() {
  local base enc
  base="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  enc="$(printf '%s' "$DIR" | sed 's#/#-#g')"
  AUX="$base/projects/$enc"
  if [ -e "$AUX" ] && [ ! -f "$AUX/.eval-fixture-aux" ]; then
    die "$AUX exists and was not built by this generator - refusing to touch it"
  fi
  rm -rf "${AUX:?}"
  mkdir -p "$AUX/consolidation" "$AUX/memory"
  printf 'built for the eval fixture at %s - safe to delete\n' "$DIR" > "$AUX/.eval-fixture-aux"
  printf 'aux=%s\n' "$AUX" >> "$DIR/.git/eval-fixture"
  echo "-- material outside the fixture: $AUX" >&2
}

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

# --- memory: material lives outside the tree, so the fixture has two halves ---

# The raw material is a deliberate mix: two facts that outlive a session, one
# date written the way a person writes it, and one episode that must be dropped.
# A distillate that keeps the episode or leaves "last week" unresolved has
# failed the rubric, and the case can say so without naming a string to find.
write_material() {
  local today; today="$(date '+%Y-%m-%d')"
  cat > "$AUX/consolidation/material-$today.md" <<EOF
# Raw material - collected $today

Source: three sessions on the invented Notes project.

## Session one

- The owner asked twice for release notes in the product voice, not a rewritten
  git log. Second time with visible irritation.
- The integration tests of the API layer live in tests/api-contract/, which is
  not obvious from the directory tree.

## Session two

- Last week we decided the payments module stays behind a feature flag until
  the provider contract is signed.
- Re-ran the test suite three times because the terminal had scrolled away.
EOF
}

write_memory_record() { # write_memory_record <slug> <description> <body>
  cat > "$AUX/memory/$1.md" <<EOF
---
name: $1
description: $2
metadata:
  type: project
---

$3
EOF
  printf -- '- [%s](%s.md) - %s\n' "$2" "$1" "$2" >> "$AUX/memory/MEMORY.md"
}

seed_memory_index() { printf '# Memory index\n\n' > "$AUX/memory/MEMORY.md"; }

build_memory() {
  fx_init; seed_app; fx_commit "initial commit"
  aux_init; seed_memory_index; write_material
  # One existing record that partly overlaps the material: the distillate has to
  # merge into it rather than add a second copy of the same fact.
  write_memory_record notes-release-voice \
    "release notes are written in the product voice" \
    "Release notes go out in the product voice. Source: an earlier session."
}

build_memory_empty() {
  fx_init; seed_app; fx_commit "initial commit"
  aux_init; seed_memory_index
  # The directory exists and is empty - the state after a project has been set
  # up but consolidate.sh has never been run.
}

build_memory_conflict() {
  fx_init; seed_app; fx_commit "initial commit"
  aux_init; seed_memory_index; write_material
  # A hand-written record that contradicts the material head on. The rubric says
  # such a record is never rewritten - it goes to Conflicts with both versions.
  write_memory_record notes-payments-flag \
    "payments ship without a feature flag" \
    "The payments module ships without a feature flag; the flag was considered and rejected. Source: written by hand by the owner."
}

# --- arch: a repository with four parts, and a vendored builder --------------

seed_arch_app() {
  mkdir -p "$DIR/src/api" "$DIR/src/core" "$DIR/src/store" "$DIR/web" "$DIR/docs/arch"
  cat > "$DIR/README.md" <<'EOF'
# Notes service

An invented service in four parts: HTTP handlers, domain logic, persistence and
a browser client. Nothing here is code from any real project.
EOF
  cat > "$DIR/src/api/routes.js" <<'EOF'
import { createNote, listNotes } from '../core/notes.js';

export function routes(app) {
  app.get('/notes', async (req, res) => res.json(await listNotes(req.userId)));
  app.post('/notes', async (req, res) => res.json(await createNote(req.userId, req.body)));
}
EOF
  cat > "$DIR/src/core/notes.js" <<'EOF'
import { insert, selectByUser } from '../store/notes-table.js';

export async function createNote(userId, note) {
  if (!note.title) throw new Error('a note needs a title');
  return insert({ ...note, userId });
}

export async function listNotes(userId) {
  return selectByUser(userId);
}
EOF
  cat > "$DIR/src/store/notes-table.js" <<'EOF'
const rows = [];

export async function insert(note) { rows.push(note); return note; }
export async function selectByUser(userId) { return rows.filter((r) => r.userId === userId); }
EOF
  cat > "$DIR/web/app.js" <<'EOF'
export async function loadNotes() {
  const res = await fetch('/notes');
  return res.json();
}
EOF
  vendor_arch_viz
}

# Valid data for the four parts. $1 picks the defect: "stale" adds a node for a
# directory that is gone, "broken" adds an edge to a node that does not exist.
write_arch_data() {
  local variant="${1:-}" extra_node="" extra_edge=""
  if [ "$variant" = "stale" ]; then
    extra_node=',
    { "id": "notify", "label": "Notifications", "group": "backend",
      "desc": "Email and push notifications", "files": ["src/notifications/"], "tech": ["node"] }'
    extra_edge=',
    { "from": "core", "to": "notify", "label": "emits", "kind": "async" }'
  fi
  if [ "$variant" = "broken" ]; then
    extra_edge=',
    { "from": "core", "to": "search", "label": "queries", "kind": "sync" }'
  fi
  mkdir -p "$DIR/docs/arch"
  cat > "$DIR/docs/arch/arch-data.json" <<EOF
{
  "meta": { "project": "Notes service", "updated": "2026-01-15", "commit": "0000000" },
  "groups": [
    { "id": "frontend", "label": "Client", "color": "#4c78a8" },
    { "id": "backend", "label": "Service", "color": "#72b7b2" }
  ],
  "nodes": [
    { "id": "web", "label": "Browser client", "group": "frontend",
      "desc": "Loads and renders notes", "files": ["web/"], "tech": ["js"] },
    { "id": "api", "label": "HTTP API", "group": "backend",
      "desc": "Routes requests to the domain layer", "files": ["src/api/"], "tech": ["node"] },
    { "id": "core", "label": "Domain logic", "group": "backend",
      "desc": "Note rules and validation", "files": ["src/core/"], "tech": ["node"] },
    { "id": "store", "label": "Persistence", "group": "backend",
      "desc": "Stores notes per user", "files": ["src/store/"], "tech": ["node"] }$extra_node
  ],
  "edges": [
    { "from": "web", "to": "api", "label": "calls", "kind": "sync" },
    { "from": "api", "to": "core", "label": "uses", "kind": "sync" },
    { "from": "core", "to": "store", "label": "reads and writes", "kind": "sync" }$extra_edge
  ],
  "flows": [
    { "id": "create-note", "label": "Creating a note", "steps": [
      { "node": "web", "note": "the form is submitted" },
      { "node": "api", "note": "the request is routed" },
      { "node": "core", "note": "the note is validated" },
      { "node": "store", "note": "the row is written" }
    ] }
  ]
}
EOF
}

build_arch()        { fx_init; seed_arch_app; fx_commit "initial commit"; }
build_arch_stale()  { fx_init; seed_arch_app; write_arch_data stale;  fx_commit "initial commit"; }
build_arch_broken() { fx_init; seed_arch_app; write_arch_data broken; fx_commit "initial commit"; }

# --- commands: a project the prompt-kit layer was rolled out into ------------

build_commands() {
  fx_init; seed_app
  vendor_command_evals
  # One command with a broken frontmatter: the opening fence is gone, so the
  # harness has exactly one structural failure to report - and the case is about
  # whether the command reports it honestly instead of quietly fixing it.
  if [ -f "$DIR/.claude/commands/spec.md" ]; then
    sed -i '1{/^---$/d;}' "$DIR/.claude/commands/spec.md"
  fi
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
  memory)          build_memory ;;
  memory-empty)    build_memory_empty ;;
  memory-conflict) build_memory_conflict ;;
  arch)         build_arch ;;
  arch-stale)   build_arch_stale ;;
  arch-broken)  build_arch_broken ;;
  commands)     build_commands ;;
esac

echo "$DIR"
