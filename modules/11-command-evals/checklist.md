# Verification checklist: 11-command-evals

1. `bash modules/11-command-evals/eval.sh --all` prints a scorecard for every
   command and exits without errors.
2. On a clean set of commands layer 1 gives 100% (`--strict` -> exit code 0).
   Below 100%, every failed check is listed with the command name and the
   reason.
3. Regressions are caught: temporarily put an em dash into any command - that
   command's score drops and `--strict` exits 1; after reverting, 100% again.
4. Baseline and delta: `eval.sh --all --baseline` records the baseline; the next
   run shows the delta column (`d:=` unchanged, `d:-N` regression).
5. Every command in `modules/09-prompt-library/commands/` has a row in
   `expectations.tsv` (a command without one is a deliberate FAIL, "no
   expectations").
6. Artifacts stay out of git: `git status` does not show `docs/evals/` (the
   directory is in `.gitignore`).
7. Ranking by usage: when transcripts are available, frequently invoked commands
   show a higher `use=` count and sort to the top.
