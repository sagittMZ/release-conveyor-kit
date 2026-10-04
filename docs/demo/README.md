# The demo in the README

`precommit.gif` replays one real run of `/precommit`. Nothing in it comes from
a real project.

## What was run

1. A throwaway repository was built by the kit's own fixture generator. The
   `dirty` fixture is one commit plus a working tree with three planted
   defects: an off-by-one in a loop bound, a leftover debug line, and a
   hardcoded credential assembled from random characters at build time.
2. The real `/precommit` command was dispatched into that repository by
   `run-case.sh`, the same script the layer 2 evals use.
3. The answer came back in 33 seconds. The repository state after the run was
   unchanged: two modified files, nothing staged, nothing committed.

## What the animation shows

The headline of every finding, word for word and in the order the command
returned them:

```
Findings (by severity)

1. CRITICAL - Hardcoded live payment secret - src/api.js:3
2. CRITICAL - Secret and raw request body written to logs - src/api.js:7
3. CRITICAL - Off-by-one crashes every checkout - src/cart.js:3
4. LOW - Dead code once the debug line is removed - src/api.js:3

Nothing was committed.
```

It is an excerpt. In the full answer every finding also carries an explanation
and a fix, and the answer opens and closes with a summary. The typing and the
pauses are drawn; the 33 seconds are compressed.

The run used the operator's own agent configuration, not an isolated one, so
the full answer is not published here. Why that matters for evals is in
[../../modules/11-command-evals/fixtures/README.md](../../modules/11-command-evals/fixtures/README.md).

## Repeat it

```bash
cd modules/11-command-evals
fx="$(bash fixtures/mkfixture.sh dirty)"
bash run-case.sh --fixture "$fx" --command precommit --out answer.md
bash fixtures/mkfixture.sh --clean "$fx"
```

This dispatches a real agent session and costs what one session costs. The
wording of the findings will differ from run to run; the three planted defects
are what a good run finds.
