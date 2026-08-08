---
description: Release notes between two points, grouped by type
argument-hint: <from-ref> <to-ref>
---
Compare $1 and $2 (tags or commits) and write release notes from the git log
between them. Group into: New, Fixes, Breaking changes. Write in the product's
voice, briefly, ready to paste into a store's "What's new".

If $1 or $2 is not given, take the two most recent tags
(git tag --sort=-creatordate) and say which ones you took.
