# Module 11 - command-evals

Command quality as a number instead of a feeling. A local equivalent of
eval-driven agent development: a rubric, checks, a baseline and a delta. The
whole module runs on the stack already in use (bash + Claude Code) - no cloud,
no paid jobs.

## Philosophy: programmatic first, judge selectively

- **Layer 1 (always on, free):** deterministic bash checks over the command
  sources. Catches structural defects - broken frontmatter, a command that takes
  an argument with no fallback, a lost binding to `.ai/`, a missing "do not
  write code" guard, an em dash. Reproducible, and usable as a CI gate.
- **Layer 2 (implemented):** an LLM judge over test cases, for the behavioral
  quality structure cannot see. One subagent executes the command against a case
  input, a second subagent judges the answer against the rubric
  (SCORE 0-5 / PASS / NOTES). It runs inside a session that is already going,
  via `/eval-command --judge`, rather than as a separate paid job. Run it
  selectively, on the commands that are actually used.

The metric is always reported as both layers. Structural 100% never stands in
for "the behavior was checked".

## Contents

| File | What it is |
|---|---|
| RUBRIC.md | What makes a command good, in human language (for layer 2 and review) |
| expectations.tsv | The layer 1 rubric in machine form: one row per command (needs_arg / analyzer / ai_role) |
| eval.sh | The layer 1 harness: checks + scorecard + delta against the baseline |
| cases/&lt;name&gt;.md | Layer 2 test cases on invented examples: input plus expect/avoid |
| judge/judge-prompt.md | The layer 2 LLM judge prompt (SCORE/PASS/NOTES) |

The `/eval-command` command itself lives in `modules/09-prompt-library/commands/`,
because commands have one home.

## Running it

```
bash modules/11-command-evals/eval.sh [--all|<name>] [--baseline] [--strict]
```

- no argument / `--all` - evaluate every command;
- `<name>` - a single command;
- `--baseline` - record the current result as the baseline for future deltas;
- `--strict` - non-zero exit code on any failed check (for CI).

From a session: `/eval-command $ARGUMENTS`.

Output: a scorecard on stdout plus `docs/evals/scorecard.{md,tsv}`. The baseline
lives in `docs/evals/baseline.tsv`. The `docs/evals/` directory is in
`.gitignore` - it is reproducible and it carries usage counters derived from
private transcripts, so it never reaches history.

## Layer 1 checks

Universal, applied to every command: valid frontmatter with a `description`; no
em dash used as punctuation; any reference to an `.ai/` role file is
conditional. Driven by `expectations.tsv`: a command with an argument has an
`argument-hint`, `$ARGUMENTS`/`$1` and a fallback; an analyzer command has a
"do not change / do not commit / do not start" guard; a declared role is bound
to the right `.ai/` file (or to the `PATTERNS.md` map for multi-role commands).

The phrase matching is bilingual: the harness recognizes both the English
wording of the kit's own commands and commands written in the owner's language
after rollout. A command is judged on the guarantee, never on its language.

A new command with no row in `expectations.tsv` is a deliberate FAIL, "no
expectations": add a row and declare the intent.

## Relationship to usage-digest

Through `lib-transcripts.sh` (module 09) `eval.sh` reads command frequencies and
ranks its output so the commands actually in use come first. Commands with zero
usage are candidates for renaming or removal - the same logic as the digest.

## Running layer 2

From a session: `/eval-command --judge`. For every command that has a
`cases/<name>.md` file, the agent has a subagent execute the command against the
case input, a second subagent judge the answer against `judge/judge-prompt.md`
plus `RUBRIC.md` plus the case expect/avoid, and collects SCORE/PASS/NOTES into
`docs/evals/judge-<date>.md`. The cases use invented examples so they are safe
to publish. Run it selectively - subagents cost money - and on the commands that
are actually used.
