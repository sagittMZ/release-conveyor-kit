# How to write prompts: 6 patterns and the escalation ladder

Every prompt in `library/` is built on six patterns. Once you know them you
write your own prompts, and the library becomes a starter rather than a
reference you consult daily.

## 1. Describe the outcome, not the steps

Say what you want to end up with and let the agent find the files.

```
add rate limiting to the public API and make sure the existing tests still pass
```

Not a single file path, and none is needed. Listing the steps takes away the
agent's chance to find a better path than yours.

## 2. Give it a self-check loop

Ask for "do it, run it, fix it" in one prompt - otherwise the agent stops after
the first attempt and waits for instructions.

```
write the migration, run it against the dev database and confirm the schema matches
```

## 3. Point at a reference

Name an existing file, test or pattern. Without a reference the agent writes to
generic best practices; with one it writes to your project's conventions.

```
build the settings page with the same layout as the profile page
```

## 4. Name a measurable target

When the goal is performance or coverage, give a metric and a threshold - the
definition of done stops being a matter of opinion.

```
get the bundle under 200KB and show me exactly what you dropped
```

## 5. Give the artifact, not a retelling

Paste errors, logs, screenshots or plan output straight into the prompt (or
@-mention the file). The agent reads the source instead of your description of
the source.

```
why is the build failing? @build.log
```

## 6. State the output format

Name the format, the length and the audience - the explanation adapts to how you
are going to use it.

```
explain how the payment retry logic works, as an HTML page with a diagram,
and open it in the browser
```

## The escalation ladder

A prompt that worked twice should not live in your clipboard. The escalation:

1. **Prompt** - a one-off request. It lives here, in `library/`.
2. **A rule in CLAUDE.md** - when you correct the agent about the same thing a
   second time: `you are using default exports again - add a rule to CLAUDE.md
   so this stops`. The rule is read by every session and reaches the whole team
   through git.
3. **A skill (a /command)** - when a chain of steps repeats: `create a
   /release-notes skill that compares two tags and groups the changes`.
4. **A hook** - when something must happen ALWAYS, without being asked: `write a
   hook that runs prettier after every edit to a .ts file`.

Rule of thumb: chat -> file -> command -> automatic. Each rung removes the need
to remember the previous one.

## Number what you hand back

When a reply contains several things the user will choose between or
recombine - variants of a screen, candidate names, alternative plans - number
them. "Take the layout from 3 and the copy from 6" is a one-line instruction;
"the one with the sidebar, but with the shorter text from the other one" is a
guessing game. The same holds for findings and steps: a numbered item can be
referred to, a paragraph cannot.

## Roles are your .ai/

Module 09 does not introduce roles of its own and does not invent persona tags.
When a prompt needs a "lens" - to look at something as a product owner, a
security engineer, a QA would - that lens is already described: it is the
corresponding file in the project's `.ai/`, with its own required reading.
"Taking the lens" means literally that: read the relevant `.ai/` file and stay
within its priorities and criteria.

Lens-to-file map:

| Lens (tag) | File in .ai/ |
| --- | --- |
| pm | PRODUCT_OWNER.md |
| design | UX_DESIGN.md / UI_RULES.md |
| security | SECURITY_CHECKLIST.md + SECURITY_AUDITOR.md |
| data | DATA_INTERPRETER.md |
| qa | QA_ENGINEER.md |
| marketing | MARKETING.md |

Project-wide rules live in `.ai/PROJECT_POLICIES.md`; every lens honors them.

This is why the kit's slash commands reference `.ai/` conditionally ("if the
project has <file>, check against it"): in a project with `.ai/` the command
works to the project's own rules, and without `.ai/` it degrades to a sensible
default. Do not bake a role into a prompt - delegate it to `.ai/`.
