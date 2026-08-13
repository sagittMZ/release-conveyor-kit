# Layer 2 scorecard - the format

This is the skeleton `/eval-command --judge` writes into
`docs/evals/judge-<date>.md`. Everything in angle brackets is a placeholder:
this file is a format, not a run, and no number in it is an assessment of
anything.

Why the format looks like this:

- **Both judges are reported.** A single number would hide the one thing worth
  knowing - how much the two disagree.
- **The conservative (lower) score survives, but it is not the headline.**
  Reporting only the minimum quietly turns a disagreement into a verdict.
- **Disagreements of 2 points or more get their own list.** That list is a work
  queue, and the first suspect on it is the wording of the case expectations,
  not the command.
- **Self-grading bias is measured, not disclaimed.** One judge shares its model
  with the executor. The gap between the two judges' means is the size of that
  effect, in points, for this run.
- **The run states its own cost.** Layer 2 is the expensive layer; a scorecard
  that does not say what it cost invites running it more often than it deserves.

---

## Skeleton

````markdown
# Command evals, layer 2 - <YYYY-MM-DD>

layer2-summary: commands=<n> cases=<m> agreement=<p>

- kit commit: `<sha>`
- executor (EXECUTOR): `<resolved model>`
- judge A (JUDGE_A): `<resolved model>`
- judge B (JUDGE_B): `<resolved model>`
- cases run: <m> of <total in cases/>
- commands covered: <n> of <total scored by layer 1>
- run cost: <actual input/output tokens, or the share of the session window>

**Headline.** Layer 2 judged <n> of <K> commands over <m> cases. Judge A mean
<a>/5, judge B mean <b>/5, the two agree within 1 point on <p>% of cases.
Conservative score (the lower of the two, per case): <c>/5 mean,
<x> of <m> cases pass.

## Per case

| Command | Case | A | A pass | B | B pass | Delta | Min |
|---|---|---|---|---|---|---|---|
| <name> | <case title> | <0-5> | <yes/no> | <0-5> | <yes/no> | <abs diff> | <lower> |

## Disagreements of 2 points or more

Work queue. First suspect is the case wording, not the command.

| Command | Case | A | B | What each judge saw |
|---|---|---|---|---|
| <name> | <case title> | <0-5> | <0-5> | <one line from each NOTES> |

Verdict per row, filled in by hand: `case reworded` / `command is at fault` /
`judges read the rubric differently` / `left as is, with a reason`.

## Self-grading bias

Judge A runs on the same model as the executor (`<model>`); judge B does not.

- mean(A) - mean(B) = <+/-x.x> points over <m> cases
- cases where A scored strictly higher: <i>; where B did: <j>
- read: <a positive gap means the same-model judge was more generous to the
  executor's answers than the different-model judge was, on this set of cases>

This is one measurement on one set of cases, not a general property of the
models.

## Not judged

| Command | Why |
|---|---|
| <name> | <no cases yet / fixture not available / skipped deliberately, reason> |
````

---

## Rules the format has to keep

1. The `layer2-summary:` line is machine-readable and stays first in the body:
   `eval.sh` reads it to report layer 2 coverage next to layer 1. Keys are
   `commands`, `cases`, `agreement` (an integer percentage).
2. Nothing here may be collapsed into a single quality number. The metric is
   always "layer 1: X/Y" plus "layer 2: n of K commands" (record 8 in
   `ARCHITECTURE.md`).
3. A command with no cases appears in "Not judged" with a reason. Silence would
   read as coverage.
4. Resolved model names, the date, the kit commit and the actual run cost are
   part of the report, not of the surrounding conversation. A scorecard without
   them cannot be compared to the next one.
