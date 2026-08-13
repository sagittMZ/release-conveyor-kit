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
8. Fixtures build: `bash fixtures/mkfixture.sh <kind>` prints a path for every
   kind in `--list`, and `git status` inside an `empty-git` fixture is empty
   (the vendored commands are hidden through `.git/info/exclude`).
9. The runner refuses anything that is not a fixture: pointed at a real
   repository, or at a fixture nested inside one, `run-case.sh` exits non-zero
   with the reason and dispatches nothing.
10. Real dispatch works end to end: `run-case.sh --fixture <empty-git>
    --command precommit` returns an answer that says there is nothing to review,
    and the same command against a `dirty` fixture finds the planted defects
    with file and line.
11. Failure is loud: when the session cannot run the command, the runner exits
    non-zero and prints what came back instead. It never returns an empty or a
    non-answer as if it were the command's output.
12. The scorecard states its environment and its price: the meta line carries
    `env=`, the model, the elapsed time and the cost of the run.
