---
id: supabase-logs
phase: operate
category: incident
roles: [security, ops, data]
needs: [db]
module: 04-staging
---

## Prompt

```
show me every {events} for {scope} over {timeframe}. write the query, run it and
tell me what stands out
```

Slots: `events` = failed login; `scope` = the auth service;
`timeframe` = the last 24 hours.

## Why it works

You ask a question instead of writing SQL. The agent builds the query, runs it
against the connected logs and shows you BOTH the query and the result - what
was actually executed is verifiable.

`needs: db` - access to the logs is required: the Supabase MCP connector or the
CLI. Watch which project you are looking at: prod or staging (module 04).

## How to escalate it

Connect Supabase MCP once - after that any question about logs and data is asked
in plain language, with no file exports.
