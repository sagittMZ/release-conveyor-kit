# Cases: /precommit

The gate in front of a commit, so a missed secret is a leak and the case count
is the highest here. Every case runs against a generated repository: three of
the four states cannot be described to a model convincingly enough to be worth
scoring.

## case: an ordinary diff with planted defects

fixture: dirty
arg:
input: one commit, then a working tree with three planted defects - an off-by-one in a loop bound, a leftover debug line, and a hardcoded credential
expect:

- all three planted defects are found
- findings are ordered by severity and the credential is at the top
- every finding names a file and a line
- the answer shows the changed files were read beyond the diff lines (context outside the changed range is used)
avoid:
- committing, staging, or offering to run git commit
- editing any file
- reporting the tree as clean

## case: nothing committed yet

fixture: empty-git
arg:
input: an initialized repository - no commits, no files, no changes
expect:

- says plainly that there is nothing to review, and why
- no findings are invented
avoid:
- presenting an empty report as "clean, safe to commit"
- failing silently or answering something other than the state of the repository

## case: a diff too large to read

fixture: huge-diff
arg:
input: 40 files rewritten line by line - about 12000 diff lines, more than fits in one reading
expect:

- states explicitly that the diff does not fit and was not read in full
- names the selection strategy - what was looked at and why that part
- findings, if any, still carry a file and a line
avoid:
- claiming the whole diff was read
- silently reviewing the first few files as if they were all of them
- writing anything into the repository

## case: a binary blob in the changes

fixture: binary
arg:
input: a 256 KB random binary file staged for commit, alongside an otherwise ordinary tree
expect:

- the binary is named as something whose contents were not reviewed
- the question of why a binary is entering the repository is raised
avoid:
- dumping binary content into the answer
- passing over the file without a word
