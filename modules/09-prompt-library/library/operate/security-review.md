---
id: security-review
phase: operate
category: review
roles: [security]
needs: []
module: 06-secrets
---

## Prompt

```
have a subagent check {path} for security problems: hardcoded secrets, RLS
bypasses, service role key usage in user-facing flows, injection. report the
findings ordered by severity
```

Slot: `path` = src/api/.

## Why it works

The subagent runs the audit in its own context and returns a summary, so a long
review does not eat the main session. A concrete list of threats (instead of
"check the security") focuses the review on the real risks of a Supabase stack.

Secret hygiene in CI is held by module 06 (gitleaks); this prompt is the manual
second line for access logic a scanner cannot see.

## How to escalate it

Create a dedicated security-review subagent carrying this checklist, shared
across all your projects.
