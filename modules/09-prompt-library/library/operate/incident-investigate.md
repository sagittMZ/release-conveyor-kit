---
id: incident-investigate
phase: operate
category: incident
roles: [ops, security]
needs: []
module: 05-monitoring
---

## Prompt

```
{symptom}. check the Sentry errors, the recent deploys and the config changes,
then name the most likely cause
```

Slot: `symptom` = checkout started returning 500s an hour ago.

## Why it works

You list the SOURCES of evidence, not the steps of the investigation. The agent
reads logs, git history and configs together and narrows the cause down at their
intersection - like someone on call, not like a checklist.

Sentry is installed by module 05; a health check (`/auth/v1/health` for
Supabase) is the first "is the backend alive at all" probe.

## How to escalate it

Connect Sentry through MCP - the agent will read error reports itself, with no
stack traces pasted by hand.
