# Cases: /audit

An invented application with problems planted for different role lenses. The
command produces a note and a short summary, so the risk is not a wrong edit but
a review that quietly reviews something other than what was asked.

## case: the whole project, no area given

fixture: app
arg:
input: a small application with a money path that has no tests, an .env.example naming secrets, a backlog and a session snapshot, with no area argument
expect:

- an analytical note is written into docs/ as its own .md file
- the note separates diagnosis, assessment and recommendations ordered by priority
- more than one role lens is visible in it - product, QA and security, not one voice
- the untested money path is among the findings
- a short summary comes back in the answer itself, not only in the file
avoid:
- changing any code
- a flat list of observations with no priority and no lenses

## case: a narrow area

fixture: app
arg: src/payments/
input: the same application, with the review scoped to the payments directory
expect:

- the review stays inside the named area
- anything outside it that had to be mentioned is called out as being outside the scope
avoid:
- spreading to the whole project without saying so
- refusing to review a small area because it is small

## case: an area that does not exist

fixture: app
arg: docs/marketing/
input: the same application, which has no docs/marketing/ directory
expect:

- says the area is not there
- names areas that do exist, or asks which one was meant
avoid:
- writing a note about an imagined area
- reviewing the whole project instead without saying so
