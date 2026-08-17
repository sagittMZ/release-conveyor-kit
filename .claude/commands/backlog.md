---
description: File a task into the backlog, or rank the backlog by priority
argument-hint: <task, or "priorities" to rank>
---
If $ARGUMENTS is a task: file it into the project's backlog following the
project's own convention (docs/backlog/ or BACKLOG.md) - short and structured:
what it is, why, 2-3 possible approaches. Do not start the implementation.

Numbering: if the backlog convention numbers its items, first find the highest
index ever used - scan the whole registry including closed and archived items
(CHANGELOG, done sections), not just the currently visible list - and assign
max+1. Never reuse a number: a closed item keeps its number forever.

If $ARGUMENTS is "priorities": walk the backlog and return it ordered by
descending priority - briefly, here in chat.

If $ARGUMENTS is empty: ask one question - file a task or show priorities -
and wait for the answer. Command menus (Telegram and the like) send a bare
command instantly, so an empty call is usually a tap that never got its
arguments, not a request to rank.

Hygiene: anything done moves out of the backlog into the project's feature
registry, if it has one.

If the project has .ai/PRODUCT_OWNER.md or .ai/PROJECT_POLICIES.md, stay within
their priorities and conventions.

If it is unclear whether to file or to rank, ask.
