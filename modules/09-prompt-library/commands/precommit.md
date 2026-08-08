---
description: Review uncommitted changes before a commit
---
Review my uncommitted changes (git diff plus new files). Read the changed files
in full, not only the diff lines. Flag anything risky: bugs, leaked secrets,
broken project invariants, forgotten edits, dead code. Report as a list ordered
by severity, each item with a file and a line.

If the project has .ai/PROJECT_POLICIES.md or .ai/SECURITY_CHECKLIST.md, check
against them as invariants and security criteria.

Do not commit anything.
