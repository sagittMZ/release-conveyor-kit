---
description: Scope prioritization with coupling in mind - the top 2-3 blocks
argument-hint: <area or scope, optional>
---
Analyze the project's current scope ($ARGUMENTS if given, otherwise the whole
backlog or the open tasks) for both priority AND coupling. Pull out the top 2-3
blocks of coupled tasks; tasks unrelated to them should ideally stay out of the
selection.

Coupling rule: if a task has low priority of its own but is tightly coupled to
a higher-priority task (they are better done together or back to back), its
priority is raised to match the senior task of the block.

Return those 2-3 blocks here in chat, ordered by descending priority (already
adjusted for coupling). Do not start the implementation.

If the project has .ai/PRODUCT_OWNER.md, stay within its priorities.
