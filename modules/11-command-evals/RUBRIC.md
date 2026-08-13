# RUBRIC - what makes a slash command good

The human-readable rubric. Layer 1 (`eval.sh` + `expectations.tsv`) checks
items 1-5 programmatically; items 6-8 are for layer 2 (the LLM judge) and for
manual review.

## Structure (layer 1, programmatic)

1. **Frontmatter.** The `---` fences and a `description` are present. If the
   command takes an argument, `argument-hint` is present too.
2. **Argument and fallback.** The body uses `$ARGUMENTS`/`$1`, and there is a
   branch for "the argument was not given" (ask, or a sensible default).
3. **Analyzer guard.** A command that only reads or analyzes explicitly forbids
   itself to change or commit ("do not write code", "do not change anything",
   "do not start").
4. **Binding to .ai/.** If a command has a natural role, its body carries a
   CONDITIONAL reference to the relevant `.ai/` file ("if the project has
   <file>, check against it"). Multi-role commands point at the map in
   `PATTERNS.md`.
5. **Hygiene.** No em dash used as punctuation (project rule: `--` -> ` - `).

Commands are written in English (see "Language" in the module 09 README). The
layer 1 checks also recognize a handful of Russian phrasings, so a command is
never penalized for the language it is written in - only for missing the
guarantee itself.

## Behavior (layer 2, LLM judge)

6. **Outcome, not steps.** The command describes the outcome it wants and lets
   the agent find the path, rather than dictating step by step (pattern 1 in
   PATTERNS.md).
7. **One clear output.** The command's answer arrives in the declared format or
   artifact, with nothing extra, and does not sprawl beyond the task.
8. **Stays inside its role.** An analyzer does not start editing; a planner does
   not write code; a command respects the boundaries of neighboring commands (no
   duplication).

Layer 2 scale: 0-5 per case (0 - does not do what it claims, 5 - precise and
within bounds). The anchors for each score are in `judge/judge-prompt.md`.

**Case expectations describe behavior, never a string to find.** "Asks a
clarifying question before planning" is checkable in any language; "contains the
word 'clarify'" is a spelling test that fails the moment the answer comes back
in the language the owner actually speaks.
