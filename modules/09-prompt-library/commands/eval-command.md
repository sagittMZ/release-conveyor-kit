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

LAYER 2 (when the argument contains --judge): for every command that has a
modules/11-command-evals/cases/<name>.md file, for each case:

1. have a subagent execute the command - give it the body of commands/<name>.md
   with the case input substituted, and ask for the answer the command would
   produce;
2. have a second subagent act as judge and score that answer per
   modules/11-command-evals/judge/judge-prompt.md, grounded in RUBRIC.md and the
   case expectations (expect/avoid); collect SCORE/PASS/NOTES.
Collect the results into docs/evals/judge-<date>.md and show a summary (command,
case, SCORE, PASS). Prioritize the commands that are actually used (per the
usage digest).

Do not change anything in the commands without my word - show the report first.
