---
description: Security review of a path, run by a subagent
argument-hint: <path, e.g. src/api/>
---
Launch a subagent to review $ARGUMENTS for security problems: hardcoded
secrets, injection, access control mistakes, unsafe defaults. If the project
uses Supabase, additionally check for RLS bypasses and service role key usage
in user-facing flows.

If the project has .ai/SECURITY_CHECKLIST.md or .ai/SECURITY_AUDITOR.md, check
against them as criteria (those are my security rules).

Report findings as a list ordered by severity, each with a file, a line and how
to fix it. Do not change anything without my explicit word.

If no path is given, review the main application code (src/ or equivalent).
