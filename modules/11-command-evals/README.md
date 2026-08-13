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
| models.json | Which model plays which layer 2 role (EXECUTOR / JUDGE_A / JUDGE_B) |
| run-case.sh | Dispatches a real slash command against a fixture, headless |
| fixtures/mkfixture.sh | Builds the throwaway repositories the negative cases need |
| judge/judge-prompt.md | The layer 2 LLM judge prompt (SCORE/PASS/NOTES) |
| judge/scorecard-template.md | The shape of a layer 2 report, with the rules it has to keep |

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

Commands are written in English, here and in the projects the kit is applied to
(see "Language" in the module 09 README). The phrase matching also recognizes a
handful of Russian phrasings, so that a command written in the owner's language
is judged on the guarantee it makes rather than on the language it makes it in.

A new command with no row in `expectations.tsv` is a deliberate FAIL, "no
expectations": add a row and declare the intent.

## Relationship to usage-digest

Through `lib-transcripts.sh` (module 09) `eval.sh` reads command frequencies and
ranks its output so the commands actually in use come first. Commands with zero
usage are candidates for renaming or removal - the same logic as the digest.

## Running layer 2

From a session: `/eval-command --judge`. For every command that has a
`cases/<name>.md` file, each case costs three subagent calls: one executor and
two judges. Results are collected into `docs/evals/judge-<date>.md` in the
format of `judge/scorecard-template.md`. The cases use invented examples so they
are safe to publish. Run it selectively - subagents cost money - and on the
commands that are actually used.

### The command is really run

The executor does not describe what a command would answer - it runs it. A
throwaway repository is built by `fixtures/mkfixture.sh`, and `run-case.sh`
dispatches the actual slash command into it headlessly, with the model from
`models.json`:

```bash
fx="$(bash modules/11-command-evals/fixtures/mkfixture.sh empty-git)"
bash modules/11-command-evals/run-case.sh --fixture "$fx" --command precommit
```

This exists because the cases that matter most cannot be imagined into being:
an empty git, a diff too large to read, a staged binary, a repository with no
tags. A model asked to picture those states answers about itself.

The session runs with permissions bypassed, which is only safe because the
runner refuses any target that is not a generated fixture - see
[fixtures/README.md](fixtures/README.md) for the guards, for what has actually
been run, and for the one confound that was measured rather than assumed: by
default the dispatched session inherits the operator's global `CLAUDE.md` and
hooks, so a layer 2 score describes a command in an environment. The runner
records that environment; the scorecard reports it.

### The protocol

The value of a judged score comes from what each participant is **not** allowed
to see.

1. **The executor** (`EXECUTOR`) gets the command body with the case input
   substituted, and the fixture repository if the case has one. It never sees
   the case expectations. A command that is told what it will be graded on
   stops being evidence of anything.
2. **Judge A** (`JUDGE_A`) and **judge B** (`JUDGE_B`) each get the same four
   things - command text, case input, the answer, expect/avoid - plus
   `judge/judge-prompt.md` and `RUBRIC.md`. Each runs in a fresh context.
   Neither sees the other's score, and neither is told a second judge exists.
3. **Nothing is averaged.** Both scores go into the report. The lower of the two
   is the conservative result; the headline stays two numbers plus how often
   they agree.
4. **Disagreements of 2 points or more** go to a work queue instead of a
   tie-breaker call. The first suspect is the wording of the case expectations,
   the second is the judge prompt, and only then the command. A third judge
   would buy a majority, not an answer.
5. **Score anchors live in the judge prompt**, so both judges anchor to the same
   behavior. The sharpest one is for negative cases: refusing or asking is
   correct and can score 5, while a confident answer built on material that was
   not there scores 0-1.

Rerun policy is per changed command by default; a full pass is for a rollout, a
public release or a change of models, never for a push.

## Models are configuration

`models.json` maps three aliases to actual models:

| Alias | Role | Why this one |
|---|---|---|
| `EXECUTOR` | runs the command against a case input | called once per case, the cheap seat |
| `JUDGE_A` | first judge | deliberately the **same** model as the executor |
| `JUDGE_B` | second judge | deliberately a **different** model |

Prompts and scripts refer to the aliases, never to a model name, so switching
models is one edit in one file. The values do not live in
`conveyor.config.json`: that file parameterizes the release pipeline of a target
project, and this layer is stack-independent and applied on its own (record 6 in
`ARCHITECTURE.md`).

Judge A sharing a model with the executor is the point, not an oversight. A
model grading its own output is the standard failure mode of self-evaluation;
a second judge on a different model turns that failure mode into a number - the
gap between the two judges' means over the same answers. Declaring the
limitation is honest, measuring it is better.

## What a layer 2 run reports

The report format is `judge/scorecard-template.md`. In short: both judges'
scores per case, how often they agree, a separate work queue of disagreements of
2 points or more, the conservative (lower) score as a result but never as the
headline, the measured self-grading gap, and the run's own metadata - resolved
model names, date, kit commit, and what the run actually cost.

`eval.sh` reads the `layer2-summary:` line out of the most recent report, so the
layer 1 scorecard always carries layer 2 coverage next to it. "Not run" stays a
visible and legitimate result.
