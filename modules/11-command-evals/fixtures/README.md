# Fixtures - repositories built to be broken

Layer 2 judges behavior, and the behavior worth judging most is what a command
does when the repository is not in a happy state: nothing committed yet, a diff
far too large to read, a binary blob staged, no tags to compare, a path that is
not there. None of that can be simulated by asking a model to imagine it - the
answer would be a model's idea of the command, not the command. So the states
are generated, and the real command is dispatched against them by
[../run-case.sh](../run-case.sh).

## Building one

```bash
bash mkfixture.sh --list
fx="$(bash mkfixture.sh dirty)"      # prints the path it built
bash mkfixture.sh huge-diff /tmp/hd  # or pick the path yourself
bash mkfixture.sh --clean "$fx"      # removes it, and whatever it put outside
```

Fixtures go to a temporary directory, are never committed, and are safe to
delete. Rebuilding is cheaper than keeping one around.

| Kind | The state it creates | Written for |
|---|---|---|
| `dirty` | one commit, then a working tree with an off-by-one, a leftover debug line and a hardcoded credential | `/precommit` |
| `empty-git` | an initialized repository: no commits, no changes, no files | `/precommit` |
| `huge-diff` | 40 files of 150 lines, every line rewritten - about 12000 diff lines | `/precommit` |
| `binary` | a 256 KB random blob staged for commit | `/precommit` |
| `tagged` | 12 commits, tags `v1.0.0` and `v1.1.0`, features, fixes and breaking changes among them | `/release-notes` |
| `tagged-one` | the same history with a single tag | `/release-notes` |
| `vuln` | `src/api/` with string-concatenated SQL, an authorization check taken from the request body, a service-role client in a user-facing path, and permissive cookie defaults | `/security-scan` |
| `backlog` | a `BACKLOG.md` of seven items with mixed priorities and one coupled pair | `/backlog`, `/scope-triage` |
| `no-backlog` | the same project with no backlog file at all | `/scope-triage` |
| `app` | a small application with a money path that has no tests, an `.env.example` naming secrets, docs and a session snapshot | `/audit`, `/session-wrap` |
| `memory` | raw material outside the tree (two durable facts, one relative date, one one-off episode) plus a memory record that partly overlaps it | `/consolidate-memory` |
| `memory-empty` | the same project with a consolidation directory that exists and is empty | `/consolidate-memory` |
| `memory-conflict` | the same material plus a hand-written memory record that contradicts it | `/consolidate-memory` |
| `arch` | a service in four parts (client, API, domain, storage) with the arch-viz builder vendored, and no data yet | `/arch-viz` |
| `arch-stale` | the same, plus `arch-data.json` carrying a node for a directory that no longer exists | `/arch-viz` |
| `arch-broken` | the same, plus `arch-data.json` with an edge to a node that does not exist - the builder refuses it | `/arch-viz` |
| `commands` | a project the prompt-kit layer was rolled out into: vendored harness, no cases, one command with a broken frontmatter | `/eval-command` |

Nothing in a fixture is code from any real project. Every defect is planted on
purpose and invented for the occasion.

## Three details that are not obvious

**The credential in `dirty` is assembled at generation time.** A literal
key-shaped string in the generator would trip the kit's own gitleaks gate, which
scans this tree and its whole history. The fragments are joined and a random
tail is added when the fixture is built, so the secret exists only inside a
temporary directory that never meets git.

**The kit's commands are hidden inside `.git`.** A fixture carries
`.claude/commands/` so the dispatched session can run the real slash command
rather than a paraphrase of it. Those files would otherwise show up as untracked
in `git status` and ruin the fixtures whose whole point is to look empty, so the
generator writes the ignore rule into `.git/info/exclude` - a per-repository
ignore file that lives inside `.git`, invisible both to `git status` and to the
working tree.

**The memory fixtures have a second half outside themselves.** Module 12 keeps
raw material and memory outside the git tree on purpose (record 9 in
`ARCHITECTURE.md`), so a fixture for `/consolidate-memory` has to put its
material where the command will actually look:
`<claude-config>/projects/<encoded-fixture-path>/`. The encoded name is derived
from the fixture's own temporary path, so it cannot collide with a real
project's memory; the directory carries its own stamp, the generator refuses to
touch an unstamped one, and `--clean` removes both halves. The path is printed
on stderr when the fixture is built.

Two kinds also need the kit vendored into them - `arch` needs the builder,
`commands` needs the harness - because the command under test resolves those by
the rolled-out layout. The generator follows `ROLLOUT.md` steps 4 and 5 for
that, including the two path rewrites in the meta-commands, so the fixture is a
rolled-out project rather than an approximation of one.

## Safety

`run-case.sh` runs the session with permissions bypassed, because a command that
has to ask before every `git diff` cannot be measured. Everything that makes
that acceptable is a guard on the target:

- the directory must carry the `.git/eval-fixture` stamp the generator writes;
- it must be its own git root;
- it must have no git remote;
- it must not be inside the repository the runner was invoked from.

Each of those is a hard stop with a non-zero exit, never a warning. The
generator has its own guard in the other direction: it refuses to overwrite a
directory that exists and is not already a fixture.

## What has actually been run

Kit vocabulary: proven means it was executed and the result observed.

**Proven.** All seventeen kinds build. The seven added for the second half of
the case matrix were checked against the tool that will meet them, which is as
far as a fixture can be verified without paying for a run: the `memory` material
lands exactly where the command computes its path, `arch-stale` builds through
the vendored builder while `arch-broken` is refused by it with the invariant
named, `commands` runs the vendored harness to 61/62 with the single planted
frontmatter defect as the only failure, and `--clean` removes both halves of a
fixture. No command has been dispatched against any of the seven yet - that is
phase 5.

`/precommit` was dispatched end to end against
`empty-git`, `huge-diff` and `dirty`. On `empty-git` it reported that there was
nothing to review and invented nothing. On `huge-diff` it triaged 12000 diff
lines and reported honestly what it had checked. On `dirty` it found all three
planted defects, ordered by severity with file and line, and committed nothing.
All four refusal guards were exercised, including the runner being pointed at a
real repository and at a fixture nested inside one.

**Measured, and worth knowing.** By default the dispatched session is the
operator's own: their global `CLAUDE.md`, hooks and plugins apply. This is not
theoretical - in the `huge-diff` run the command wrote a session snapshot file
into the fixture, because the operator's global instructions ask for one at the
end of every task, and `/precommit` is a command that must not write anything.
The environment is therefore recorded in the runner's meta line (`env=`) and
belongs in the scorecard: a layer 2 score describes a command *in an
environment*, not a command alone.

**Not verified.** `--isolated`, which points `CLAUDE_CONFIG_DIR` at an empty
directory to keep the operator's global layer out, has never completed a run
here: the empty config has no credentials, so the session cannot authenticate
and the runner stops with exit 3. It needs an auth method that does not live in
the operator's config directory (`ANTHROPIC_API_KEY` or an `apiKeyHelper`). The
runner never reads or copies credentials to work around this.

**Known dead end.** `--bare` looks like the right isolation switch and is not:
it skips project command discovery, so `/precommit` comes back as "Unknown
command". That failure used to be reported as a successful answer, which is why
the runner now treats a non-answer as a hard failure rather than something to
score.
