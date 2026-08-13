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

Nothing in a fixture is code from any real project. Every defect is planted on
purpose and invented for the occasion.

## Two details that are not obvious

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

**Proven.** All ten kinds build. `/precommit` was dispatched end to end against
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
