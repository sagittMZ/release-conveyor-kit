# Layer 2 scorecard - a worked example

Every number in this file is invented. It exists so that a reader of the
public repository can see what a filled-in scorecard looks like without the
kit publishing a real one: real scorecards live in `docs/evals/`, which is
gitignored because they carry usage data derived from private transcripts
(record 12 in `ARCHITECTURE.md`). The format itself, with the rules it has to
keep, is `scorecard-template.md`.

````markdown
# Command evals, layer 2 - 2026-01-15

layer2-summary: commands=3 cases=6 agreement=83

- kit commit: `0000000`
- executor (EXECUTOR): `example-model-a`
- judge A (JUDGE_A): `example-model-a`
- judge B (JUDGE_B): `example-model-b`
- cases run: 6 of 38
- commands covered: 3 of 14
- run cost: $6.20 (invented)

**Headline.** Layer 2 judged 3 of 14 commands over 6 cases. Judge A mean
4.3/5, judge B mean 4.0/5, the two agree within 1 point on 83% of cases.
Conservative score (the lower of the two, per case): 3.8/5 mean,
5 of 6 cases pass.

## Per case

| Command | Case | A | A pass | B | B pass | Delta | Min |
|---|---|---|---|---|---|---|---|
| precommit | clean tree, nothing staged | 5 | yes | 5 | yes | 0 | 5 |
| precommit | staged binary | 4 | yes | 4 | yes | 0 | 4 |
| release-notes | two real tags | 5 | yes | 4 | yes | 1 | 4 |
| release-notes | nonexistent refs | 3 | no | 3 | no | 0 | 3 |
| security-scan | no path given | 5 | yes | 4 | yes | 1 | 4 |
| security-scan | empty repository | 4 | yes | 2 | no | 2 | 2 |

## Disagreements of 2 points or more

Work queue. First suspect is the case wording, not the command.

| Command | Case | A | B | What each judge saw |
|---|---|---|---|---|
| security-scan | empty repository | 4 | 2 | A: "said there was nothing to scan, correct refusal". B: "spent half the answer describing what it would scan if code existed" |

Verdict per row, filled in by hand: `case reworded` - the expectation "answers
briefly" was added; neither judge was wrong about what they read.

## Self-grading bias

Judge A runs on the same model as the executor (`example-model-a`); judge B
does not.

- mean(A) - mean(B) = +0.3 points over 6 cases
- cases where A scored strictly higher: 3; where B did: 0
- read: the same-model judge was more generous to the executor's answers than
  the different-model judge was, on this set of cases

This is one measurement on one set of cases, not a general property of the
models.

## Not judged

| Command | Why |
|---|---|
| handoff | skipped deliberately: unchanged since the last full pass |
| arch-viz | fixture requires vendored module, not built in this run |
````

Three things worth noticing in the example, because they are the format doing
its job:

- the one 2-point disagreement resolved against the **case wording**, not the
  command - that is the expected outcome of the work queue, per the protocol;
- the conservative mean (3.8) is visibly lower than either judge's mean, and
  still it is not the headline;
- "Not judged" names commands and reasons. An empty section there would mean
  full coverage, and it has to be earned, not implied.
