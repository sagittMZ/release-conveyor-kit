# Usage digest - which prompts and commands actually get used

Answers the question a bare menu library cannot: which prompts and skills are
actually in use. It counts slash command invocations in the Claude Code
transcripts and gives a weekly picture of what went into service and what is
sitting there as dead weight.

## How it works

Every `/command` invocation is written into the session transcript
(`~/.claude/projects/<project>/*.jsonl`) as `<command-name>/name`. Over a window
of N days (7 by default) `usage-digest.sh` counts the invocations of the
library's commands and prints a summary. Optionally it sends the summary to
Telegram, if `TG_BOT_TOKEN` and `TG_CHAT_ID` are set in the environment.

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

## v0 limitation

The window is measured by the transcript file's modification time (`find
-mtime`), not by the timestamps of individual messages inside it. That is
accurate enough for a weekly digest; if per-message precision is ever needed,
parse the time field in the jsonl.
