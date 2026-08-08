# NEW_SESSION_PROMPT - session entry point (template)

> Copy this file to `docs/NEW_SESSION_PROMPT.md` and keep the copy out of git
> (the kit's `.gitignore` already excludes it). The real file holds your current
> priorities and personal context - it is a working file, like `.env`, not a
> document for the repository.
>
> How it is used: you open a fresh session with "Read
> docs/NEW_SESSION_PROMPT.md". The agent reads it and starts on "Priority now"
> without a briefing round. The `/handoff` command regenerates it.

**Project:** <name> (<one line: what it is>).
**Updated:** <YYYY-MM-DD> (<what the last session did>).

You are the standing agent for this project (cwd: `<path to repo>`). Read
`docs/.session-current.md` first for the last session's snapshot.

## Status

Where things stand right now. Keep it to what changes decisions - not a
changelog, git already has one.

- <Subsystem / module>: <done | in progress | blocked>, <commit or artifact
  that proves it>.
- <Rollout / integration>: <what is waiting, and on whose word>.
- <Infrastructure done recently and NOT to be redone>: <short list, so a fresh
  session does not rebuild what already works>.

## Priority now (order matters)

1. **<Task>** - <what exactly to do, what "done" looks like, what to check
   before starting>.
2. **<Task>** - <same>.

Keep this list short. Two or three items. Everything else belongs in the
backlog.

## Deferred (waits for a trigger - do NOT start on your own)

- <Item> - <what trigger unblocks it>.
- <Item> - <why it is deferred, so nobody re-litigates the decision>.

## Rules

- <Communication language; code, comments and commits in English.>
- <Commit granularity, trailer, branch policy.>
- <What the agent must never touch without an explicit go: other repos,
  external publications, running services.>
- <Plan-first threshold: which changes need a plan in chat before code.>

## How to maintain this file

At the end of a task: update "Status" and "Priority now". Keep only what is
current here. Detailed handoffs go to `docs/private/handoff-*.md`, the previous
session's snapshot to `docs/.session-current.md`.
