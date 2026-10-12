# Usage digest - which prompts and commands actually get used

Answers the question a bare menu library cannot: which prompts and skills are
actually in use. It counts slash command invocations in the Claude Code
transcripts and gives a weekly picture of what went into service and what is
sitting there as dead weight.

## How it works

Every `/command` invocation is written into the session transcript
(`~/.claude/projects/<project>/*.jsonl`) as a user message carrying
`<command-name>/name`; a skill Claude picks up itself and a subagent it starts
are tool calls of the assistant. Over a window of N days (7 by default)
`usage-digest.sh` counts all three and prints a summary. Optionally it sends the
summary to Telegram, if `TG_BOT_TOKEN` and `TG_CHAT_ID` are set in the
environment.

What counts and what does not:

- Records are read, not raw text. A command name quoted in a tool result or a
  pasted log is not an invocation, and a record copied into a resumed session's
  file is counted once.
- Only records inside the window count, by their own timestamp. The file's
  modification time just selects which transcripts to open.
- Names keep their group: `/kit:handoff` is listed as `kit:handoff`. A library
  command is recognized under any group, and its number is every way it ran -
  typed, or run by Claude as a skill.
- Needs `python3`. Without it the counters fall back to counting text matches,
  which is looser (no window inside a file, no de-duplication).

## More than one config directory

The digest reads `~/.claude/projects` unless told otherwise. If you run Claude
Code with several config directories (`CLAUDE_CONFIG_DIR`), the sessions of the
others are invisible until you list every projects directory, separated by `:`:

```bash
CLAUDE_PROJECTS_DIR="$HOME/.claude/projects:$HOME/.claude-work/projects" bash usage-digest.sh
```

The report then says how many transcripts each directory gave. Symbolic links
inside a projects directory are followed, and a transcript reached twice is
counted once.

## Running it by hand

```bash
bash usage-digest.sh                 # report to stdout, 7 day window
DIGEST_DAYS=30 bash usage-digest.sh  # 30 day window
```

## On a schedule

Put the digest on cron through a SEPARATE wrapper outside the repository, so the
token never reaches git:

```bash
# ~/prompt-usage-digest.sh  (outside the repository, chmod 600)
#!/bin/bash
export TG_BOT_TOKEN="<token>"
export TG_CHAT_ID="<chat_id>"
export DIGEST_DAYS=7
KIT=<path-to-your-clone-of-the-kit>
bash "$KIT/modules/09-prompt-library/usage-digest/usage-digest.sh"
```

```
# crontab: Sundays
5 16 * * 0 ~/prompt-usage-digest.sh
```

## How to read the digest

- **Zero invocations over the period** - either the command is not being found
  (bad naming, you forgot it exists) or it is not needed. A candidate for
  renaming or removal.
- **Frequent invocations** - a candidate for the next rung of the escalation
  ladder: from a command into a hook, so it happens automatically without being
  invoked.
- After two to four weeks there is enough data to decide what to build next
  deliberately, instead of guessing.

## Provenance

Extracted from a working donor setup (proven): the weekly cron run and the
Telegram delivery. Added by the kit: reading records instead of text, the
per-record window, group names, several projects directories - run on the
owner's machine against a week of real transcripts, not on anyone else's.
