# Verification checklist: 09-prompt-library

1. The target project has `docs/prompts/library/PATTERNS.md` and
   `docs/prompts/library/` with six phase subdirectories (discover, design,
   build, ship, operate, automate). Any pre-existing `docs/prompts/` was not
   overwritten - the kit's menu sits in its own `library/`.
2. Every menu file starts with YAML frontmatter and carries the fields `id`,
   `phase`, `category`, `roles`. Quick check:
   `grep -L "^id:" docs/prompts/library/*/*.md` - the output must be empty.
3. The `phase` in the frontmatter matches the name of the file's directory.
4. The target project's AI_WORKFLOW.md has a pointer section to
   `docs/prompts/library/` and the list of slash commands (if there is no
   AI_WORKFLOW.md, a line in CLAUDE.md).
5. The slash commands are in place: `ls .claude/commands/` shows 14 files -
   spec.md, precommit.md, session-wrap.md, release-notes.md, security-scan.md,
   edge-cases.md, backlog.md, scope-triage.md, handoff.md, impl-plan.md,
   audit.md, eval-command.md, consolidate-memory.md, arch-viz.md (the last three
   are the meta-commands of modules 11/12/13; their harness paths are adjusted
   to tools/prompt-kit/). To confirm the agent sees them: `/precommit` appears
   in autocomplete or in `/help`. Invoke `/precommit` on a clean tree - it
   should answer that there are no changes.
6. (Optional) The usage digest runs:
   `bash modules/09-prompt-library/usage-digest/usage-digest.sh` prints a
   report.
7. Spot check: open two or three menu prompts, fill their slots for the target
   project and send them to the agent - the answer is sensible (the prompt does
   not reference things the project does not have; if it does, say Sentry is
   missing, the prompt is marked with the corresponding `needs`).
