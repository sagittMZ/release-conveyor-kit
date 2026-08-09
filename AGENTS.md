# Agent rules - working on the kit

Rules for an AI agent working **on this repository**. They override defaults
for the whole session.

Not to be confused with `modules/08-agent-layer/AGENTS.md`, which is the rules
file the kit *ships* to a target project. This file is about developing the
kit; that one is about applying it.

## What this repository is

A release conveyor delivered as modules an agent applies to an existing
project, plus a stack-independent layer of commands, evals, memory
consolidation and architecture visualization. Structure and reasoning:
[ARCHITECTURE.md](ARCHITECTURE.md). Entry point for users: [README.md](README.md).

The kit is dogfooded - its own commands run against it. That makes it easy to
confuse the instruments with the traces of using them. The rule below exists
because of that.

## Hard rules

1. **Public tree = instruments. Private layer = the owner's work.**
   The repository publishes what a user needs to run the kit. The owner's spec,
   build journal, audits, implementation plans, handoffs and backlog live in
   `docs/private/`, which is git-ignored. Before adding a file to the public
   tree, ask: would someone who forked this repository need it? If not, it
   belongs in `docs/private/`.

2. **Nothing personal in the public tree, ever.** No personal or project names
   of the owner, no absolute home paths (`$KIT` or `<path-to-kit>` instead), no
   chat ids, project refs, organization names, or references to the owner's
   local toolchain. The donor project is referred to by role only - "the donor"
   - never by name. This holds for commit messages too.

3. **Secrets are placeholders.** No real key, token, DSN or keystore in the
   tree, in an example file, or in a comment. Name the secret and say where the
   owner puts it.

4. **Honest provenance.** Every module README splits its content into extracted
   from a working donor project (proven) and added by the kit (not verified).
   New material is "not verified" until it has actually run. Never present an
   unrun template as proven, and never report a check as passed without running
   it.

5. **English is canonical.** Everything in the public tree - documentation,
   commands, prompts, rubrics, code comments, commit messages - is English.
   The private layer is in whatever language the owner writes in. Where a local
   translation is useful, English stays canonical and the translation is
   regenerated and git-ignored.

6. **Templates are parameterized.** Anything project-specific in a template
   carries a `# conveyor:` marker and reads from `conveyor.config.json`.
   No values copied from one project hardcoded into another.

7. **Verify before reporting.** Before a commit that touches commands or
   scripts: `bash modules/11-command-evals/eval.sh --all` (layer 1 must stay at
   100%) and `bash -n` on changed shell scripts. State results as they were,
   including failures.

## Conventions

- **Commits.** English, imperative, one logical step per commit. Body explains
  why when the diff cannot.
- **Punctuation.** No em dashes anywhere in the repository. Use a hyphen with
  spaces instead.
- **Decision records.** A decision about the product - how the kit is built,
  what it guarantees, what it refuses to do - goes into `ARCHITECTURE.md`, in
  English, as a new numbered record with context, alternatives and consequences.
  Never into a session snapshot, a commit message alone, or the private journal.
  Records are append-only: a decision that stops being true gets a new record
  that says `Supersedes: <the old one>`, and the old record stays where it is.
  A decision about process, one machine or the owner's other projects goes into
  the private journal instead. `/session-wrap` asks about this at the end of a
  session, so it does not depend on anyone remembering.
- **Scope discipline.** Anything outside the current scope goes to the backlog
  with the condition that would activate it, rather than being built "while we
  are here".

## Where things are

| Path | What |
|---|---|
| `README.md` | user-facing entry point |
| `ARCHITECTURE.md` | structure and design decisions |
| `conveyor.config.example.json` | target project parameters, with explanations |
| `modules/01..08/` | release pipeline, stack-specific |
| `modules/09, 11, 12, 13/` | stack-independent layer |
| `modules/09-prompt-library/ROLLOUT.md` | full rollout spec for a target project |
| `docs/EXPLAIN.md`, `docs/prompt-kit-guide.md` | explanations and user guide |
| `docs/arch/` | architecture visualization (canonical, English) |
| `docs/private/` | the owner's working layer - git-ignored, never published |
| `.claude/commands/` | the kit's own slash commands (dogfooding) |
