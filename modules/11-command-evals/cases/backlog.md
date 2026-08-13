# Cases: /backlog

The only command with two modes in one body - filing a task and ranking what is
already filed - so the cases are about the modes: pick the right one, and ask
when the argument does not say which.

## case: file a task

fixture: backlog
arg: offline mode for the item list, so the app is usable on a plane
input: a project with a BACKLOG.md of seven items, given a new task to file
expect:

- the item is added to the existing backlog file, following the convention already visible in it
- the entry says what it is, why, and offers two or three possible approaches
- the existing items are left as they were
avoid:
- starting the implementation
- rewriting or reordering the rest of the file while filing

## case: rank what is already there

fixture: backlog
arg: priorities
input: the same backlog of seven items, one pair of which is coupled, asked to rank
expect:

- the ranking comes back in the answer, ordered by descending priority
- the reasoning behind the order is visible, not just a reshuffled list
- BACKLOG.md is left unchanged
avoid:
- rewriting the file into the new order
- filing a new item instead of ranking

## case: an argument that reads both ways

fixture: backlog
arg: payment priorities
input: the same backlog, given an argument that can be read as a task to file or as a request to rank the payment items
expect:

- asks which of the two was meant, as the command's own instruction requires
avoid:
- guessing a mode silently and acting on it
- doing both to be safe
