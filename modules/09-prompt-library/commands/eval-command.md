---
description: Command evals - layer 1 (structure) and layer 2 (LLM judge over cases)
argument-hint: <name | --all | --baseline | --judge>
---
LAYER 1 (default): run the structural checks through the harness
modules/11-command-evals/eval.sh with argument $ARGUMENTS (if not given, use
--all). Show the scorecard, the failed checks and the delta against the
baseline. If asked for --baseline, record the baseline.
Report the metric ONLY in the honest form the harness prints: "layer 1
(structure): X/Y" plus "layer 2 (behavior): N of K commands". Never present
structural 100% as evidence that behavior was verified.

LAYER 2 (when the argument contains --judge): read the model roles from
modules/11-command-evals/models.json (EXECUTOR, JUDGE_A, JUDGE_B) and use those
models, never a model named in this prompt. For every command that has a
modules/11-command-evals/cases/<name>.md file, for each case:

1. EXECUTOR - if the case has a fixture: build it with
   modules/11-command-evals/fixtures/mkfixture.sh <kind>, dispatch the real
   command with modules/11-command-evals/run-case.sh --fixture <dir> --command
   <name> --arg "<the case arg>" --out <answer> --meta <meta>, keep the meta
   line (it carries the environment and what the run cost), and remove the
   fixture afterwards with mkfixture.sh --clean <dir>. If the case has no
   fixture: a subagent that gets the body of
   modules/09-prompt-library/commands/<name>.md with the case input substituted
   and produces the answer the command would give. Either way the executor never
   sees the case expectations;
2. JUDGE_A and JUDGE_B - two subagents, each in a fresh context, each given the
   command text, the case input, the answer and the case expectations
   (expect/avoid), and scoring per modules/11-command-evals/judge/judge-prompt.md
   grounded in modules/11-command-evals/RUBRIC.md. Neither sees the other's
   score; do not tell either that a second judge exists. Collect SCORE/PASS/NOTES
   from both.
Write the results into docs/evals/judge-<date>.md in the format of
modules/11-command-evals/judge/scorecard-template.md: both scores per case, the
agreement rate, disagreements of 2 points or more as a separate work queue, the
lower score as the conservative result but not as the headline, the measured gap
between the judge that shares a model with the executor and the one that does
not, and the run metadata (resolved models, date, kit commit, what the run
cost). Show a short summary here. Prioritize the commands that are actually
used (per the usage digest).

Do not change anything in the commands without my word - show the report first.
