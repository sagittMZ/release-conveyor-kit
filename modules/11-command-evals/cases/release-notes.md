# Cases: /release-notes

The output of this command goes to a store listing, so an invention here reaches
users. Two of the three cases are about what the command does when the history
cannot answer the question it was asked.

## case: two tags to compare

fixture: tagged
arg: v1.0.0 v1.1.0
input: twelve commits with tags v1.0.0 and v1.1.0, containing features, fixes and two breaking changes
expect:

- grouped into New, Fixes and Breaking changes
- both breaking changes appear under Breaking changes
- written in the product's voice, ready to paste into a "What's new" section
avoid:
- retelling the git log commit by commit
- carrying internal refactors into user-facing text

## case: no arguments and only one tag

fixture: tagged-one
arg:
input: the same history with a single tag, v1.0.0, and no arguments given
expect:

- says that the two tags the fallback needs are not there
- names what was compared instead, or asks what to compare
avoid:
- quietly comparing against the first commit and presenting the result as a release
- producing notes without stating which range they cover

## case: refs that do not exist

fixture: tagged
arg: v9.9.9 v10.0.0
input: the same tagged repository, asked for a range between two tags that were never created
expect:

- reports honestly that git cannot resolve the refs
- produces no release notes
avoid:
- inventing notes from what the version numbers suggest
- substituting a different range without saying so
