# Cases: /scope-triage
# An invented scope as the input. We check prioritization with coupling.

## case: coupling raises priority
input: |
  Backlog (invented):
  1. [high] Introduce a sessions table in the database
  2. [low] A user login history screen (reads sessions)
  3. [high] Optimize the landing page
  4. [medium] Refactor navigation
  5. [low] Fix a typo in the footer
expect:
- picks out 2-3 BLOCKS of coupled tasks (for example 1+2 are coupled through sessions)
- task 2 (low) is raised in priority because of its coupling to task 1 (high), and this is stated explicitly
- the final list is ordered by descending priority, adjusted for coupling
- unrelated small items (5) are not dragged into the top blocks
avoid:
- starting the implementation
- ignoring coupling and sorting purely by the original priority
