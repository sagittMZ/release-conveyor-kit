# Prompt Kit - user guide

The kit's stack-independent layer: **commands + prompt patterns +
measurability + memory**. It applies to any project (Python, Next.js, anything),
separately from the release pipeline (modules 01-08, which target one stack).
This guide is both a "what to call when" manual and a demonstration of how the
work with an agent is organized.

## What you get

1. **Commands** (`/name`) - one-line actions, every invocation logged.
2. **Patterns and the escalation ladder** - how to write prompts, and how to
   lift whatever repeats out of chat and into a command, then a hook.
3. **Measurability and memory** - evals of command quality (module 11) and
   memory consolidation (module 12), so quality does not drift and memory does
   not pile up as raw sediment.

## The commands: what each is for

### Working commands

| Command | When to call it | What it does |
|---|---|---|
| `/spec` | starting a feature, requirements needed | a feature interview -> SPEC.md |
| `/impl-plan` | requirements ready, a work plan needed | a phased plan by a team of roles + an uncertainty gate |
| `/edge-cases` | designing or testing a feature | the errors, empty states and edge cases |
| `/scope-triage` | many tasks, unclear order | the top 2-3 blocks, priority adjusted for coupling |
| `/backlog` | an idea appeared, or ranking is needed | file it into the backlog, or sort by priority |
| `/precommit` | before a commit | review of what is uncommitted: bugs, leaks, broken invariants |
| `/security-scan` | touching something sensitive | a security review of a path, run by a subagent |
| `/release-notes` | a release went out | grouped notes between two tags |
| `/session-wrap` | end of a session | a state snapshot + suggestions for CLAUDE.md |
| `/handoff` | context is running out, a new session is needed | a kickoff prompt for a fresh agent |
| `/audit` | the project needs a review | an analytical note -> docs/*.md + a summary |

### Meta and tooling

| Command | When to call it | What it does |
|---|---|---|
| `/eval-command` | editing commands, want to measure quality | structural evals (layer 1) + the LLM judge over cases (`--judge`) |
| `/consolidate-memory` | memory and snapshots have grown | distill the raw material into a reviewable DRAFT (the live files are untouched) |
| `/arch-viz` | the structure changed | refresh the architecture visualization: data + built HTML |

## Choosing a command (a decision tree)

- I do not know what to build, I need requirements -> **/spec**
- Requirements exist, I need a plan -> **/impl-plan**
- What could break in this feature -> **/edge-cases**
- Too many tasks, where do I start -> **/scope-triage**
- Just park an idea for later -> **/backlog**
- Check before committing -> **/precommit** (security -> **/security-scan**)
- Review or assess the whole project -> **/audit**
- Wrapping up work -> **/session-wrap**; handing over to a new session ->
  **/handoff**
- Measure the quality of my commands -> **/eval-command**
- Memory has gone weedy -> **/consolidate-memory**
- The architecture drawing is out of date -> **/arch-viz**

## Roles are your .ai/

The commands introduce no roles of their own: where a "lens" is needed (the
product, security or QA view), that lens is the corresponding file in the
project's `.ai/`. Commands reference it conditionally - if the file is there
they check against it, if not they fall back to a sensible default.

| Lens | File in .ai/ |
|---|---|
| pm | PRODUCT_OWNER.md |
| design | UX_DESIGN.md / UI_RULES.md |
| security | SECURITY_CHECKLIST.md + SECURITY_AUDITOR.md |
| qa | QA_ENGINEER.md |
| data | DATA_INTERPRETER.md |
| project-wide rules | PROJECT_POLICIES.md |

## The escalation ladder

A prompt that worked twice should not live in your clipboard:

`chat -> a rule in CLAUDE.md -> a command (/name) -> a hook (always, unasked)`

Each rung removes the need to remember the previous one. Details in
`modules/09-prompt-library/PATTERNS.md` (the six prompt-writing patterns).

## Measurability: command evals (module 11)

"Is `/spec` any good?" - answered with a number, not a feeling.
- **Layer 1** (bash, zero cost): structural checks of the command sources -
  valid frontmatter, a fallback, the analyzer guard, the `.ai/` binding,
  hygiene. With a baseline and a delta: an edit either holds the score or drops
  it.
- **Layer 2** (`--judge`): a subagent executes the command against a test case
  and a judge scores the answer against the rubric (0-5). Runs inside the
  current session, selectively.

Run it with `/eval-command --all` (layer 1) or `/eval-command --judge`.

## Memory: consolidation (module 12)

A file-based way to keep memory from turning into sediment.
1. `consolidate.sh` deterministically gathers the raw material (snapshots,
   MEMORY.md, .ai/, usage) into one file.
2. `/consolidate-memory` distills it into a **DRAFT** (Add / Update / Conflicts)
   - the live MEMORY.md and .ai/ are never touched.
3. You read the DRAFT and merge what you accept by hand.

## Map of the kit's modules

| # | Layer | Stack |
|---|---|---|
| 01-07 | the release pipeline (CI, builds, stores, staging, monitoring, secrets, smoke) | React/Vite/Supabase |
| 08 | agent-layer (the prompts that apply the kit) | - |
| 09 | prompt-library (commands + patterns) | stack-independent |
| 10 | coverage-matrix (test coverage matrix) | reserved, in the backlog |
| 11 | command-evals (measurable command quality) | stack-independent |
| 12 | memory-consolidation | stack-independent |
| 13 | arch-viz (architecture visualization) | stack-independent |

The stack-independent layer (09 + 11 + 12 + 13) applies to any project; 01-08
target the stack.

## Where things go

- commands -> `.claude/commands/` (invoked as `/name`);
- the menu library -> `docs/prompts/library/`;
- the evals and consolidation tooling plus lib -> `tools/prompt-kit/` (vendored,
  with a PROVENANCE file);
- the wiring for the commands -> a section in `AI_WORKFLOW.md`;
- eval artifacts -> `docs/evals/`, and consolidation raw material outside the
  tree entirely (both private and reproducible; `docs/consolidation/` stays in
  `.gitignore` as insurance).
