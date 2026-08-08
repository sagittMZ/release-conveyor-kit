# Architecture

How the kit is put together, and the reasoning behind the decisions that shaped
it. Written for someone deciding whether to use the kit, fork it, or borrow one
idea out of it.

## The shape of it

The kit is not a framework and not a CLI. It is a set of **modules an AI agent
applies to an existing repository**, plus the contracts that keep that
application honest.

```
conveyor.config.json      parameters of the target project (names, branches, versions)
        |
        v
modules/01..08            release pipeline, stack-specific (React/TS + Vite +
                          Capacitor + Supabase + Vercel + Actions + Codemagic)
modules/09, 11, 12, 13    prompt-kit layer, stack-independent - works on any repo
        |
        v
target project            vendored copy: .claude/commands/, docs/prompts/,
                          tools/prompt-kit/, workflows - the project owns it
```

Two layers with different lifetimes. The release pipeline is tied to one stack
and changes when that stack changes. The prompt-kit layer is about how a human
and an agent work together, and it survives any stack.

Each module is self-contained: a `README.md` with an "Origin" section, a
`checklist.md` that defines what "applied" means, and `templates/` with
`# conveyor:` markers on every line that needs a project-specific value.

## Design decisions

Each record states what was decided, what it was weighed against, and what it
costs. Records are append-only: a decision that stops being true gets
superseded by a later record, not edited away.

---

### 1. Modules are folders with numeric prefixes

**Context.** The kit ships eight release modules plus a stack-independent
layer. Application order matters: CI and secret hygiene must exist before
anything can be verified.

**Decision.** Module folders carry a numeric prefix (`01-ci-core` ...
`13-arch-viz`), and the number encodes the intended application order.

**Alternatives.** Flat names with the order documented separately - rejected:
the order then lives in a file nobody reads at the moment of the decision.
A manifest file listing modules - rejected as a second source of truth.

**Consequences.** The order is visible in `ls`. Inserting a module between two
existing ones is awkward; in practice new modules append (11, 12, 13), which is
why the numbers are the *intended* order, not a strict sequence - see record 5.

---

### 2. `conveyor.config` is JSON, not YAML

**Context.** Every module template needs the target project's names, branches,
versions and build commands. Both a human, an agent, and shell scripts read
these values.

**Decision.** A single `conveyor.config.json` in the target project root.

**Alternatives.** YAML - friendlier to write, but needs a parser dependency in
scripts and is ambiguous around types and indentation. Environment variables -
rejected: no structure, and values belong in the repo, not the shell.

**Consequences.** No parsing dependency anywhere: `node`, `python3 -c`, `jq`
and an LLM all read it directly. Cost: no comments in the config, which is why
`conveyor.config.example.json` carries the explanations instead.

---

### 3. Versions are parameters, not constants

**Context.** The donor project ran Node 24 in its workflows while pinning 22 in
`.nvmrc` - a real drift found during extraction. Any value copied from a
working project is a snapshot of that project, not a truth.

**Decision.** Runtime versions, shard counts and similar numbers live in
`conveyor.config.json`. Templates reference them through `# conveyor:` markers.
Defaults come from what was observed working, and are labelled as such.

**Alternatives.** Hardcode the donor's values - rejected: guarantees silent
drift in every target project. Detect versions automatically - rejected for v0:
detection failures are harder to notice than a wrong default.

**Consequences.** Applying the kit to a project on a different Node version is
a config edit, not a template edit. The `# conveyor:` markers double as the
review checklist for what must be looked at.

---

### 4. Honest provenance: proven vs added

**Context.** Roughly half the kit was extracted from a production pipeline and
half was written for the kit and never run in anger. Presenting both as one
thing would be the single most damaging lie the kit could tell: an owner would
trust an unverified template with a store release.

**Decision.** Every module README has an "Origin" section splitting its content
into **extracted from a working donor project (proven)** and **added by the kit
(not verified)**. Verification gates and reports use the same vocabulary:
applied+verified / applied+NOT verified / manual step / skipped, each with a
reason. Nothing is ever reported as verified when it was not run.

**Alternatives.** Verify everything before shipping - rejected: some paths need
paid accounts (Apple Developer, Play Console) and physical devices. Ship
without the distinction - rejected as dishonest.

**Consequences.** The kit reads as less finished than it could. That is the
point: the reader can tell which parts to trust. The donor itself stays
anonymous - the role is what carries meaning, its identity does not.

---

### 5. Application order 01 -> 06 -> 04 -> 07 -> 05 -> 02 -> 03

**Context.** The numeric order of the folders is not the order of application.
CI and secret hygiene carry everything else; mobile and store work has the
longest human-side loops (accounts, payments, review queues).

**Decision.** Modules are applied CI first, secrets second, then staging, smoke
tests, monitoring, and finally mobile builds and store deployment. The
stack-independent layer is applied last, or alone.

**Alternatives.** Apply in numeric order - rejected: store work would start
before there is a green pipeline to prove anything. Let the agent choose -
rejected: the ordering rationale is not recoverable from the modules
themselves.

**Consequences.** An owner blocked on a paid account still gets the whole
verified core. The stack-independent layer being last means it can be offered
even when the stack is out of scope - which is how most projects meet the kit.

---

### 6. The stack-independent layer is a separate concern

**Context.** Modules 09, 11, 12 and 13 (commands, evals, memory consolidation,
architecture visualization) have nothing to do with React or Supabase. They are
about how work with an agent is organized.

**Decision.** They are packaged so they can be applied alone, to a repository
in any language, with no reference to the release pipeline.

**Alternatives.** Keep one indivisible kit - rejected: it would make the most
broadly useful part unreachable for anything outside the v0 stack. Split into a
second repository - rejected: two repos to maintain for one body of work.

**Consequences.** The scope guard has an explicit exception: an out-of-scope
stack still gets offered this layer. In practice this is the part that gets
adopted first.

---

### 7. Vendoring, not submodules

**Context.** A project that adopts the kit needs the commands and tooling
present in its own tree - the agent reads them from the project, and a
submodule that nobody initializes is worse than no dependency at all.

**Decision.** Rollout copies artifacts into the target project. Each copy is
stamped `kit@<sha> <date>` in its frontmatter or first line, and
`check-provenance.sh` reports how far a copy has drifted from the kit's HEAD
and which sources changed since.

**Alternatives.** Git submodule - rejected: fragile, invisible to the agent,
and it makes the project not self-sufficient. Package manager distribution -
rejected for v0: these are prompts and shell scripts, not a library, and the
project must be free to edit its copy.

**Consequences.** The project owns its copy and may edit it. Drift is expected
and made visible rather than prevented. With three or more projects, the stamp
is the only thing that keeps the copies accountable.

---

### 8. Command quality is a number, reported in two layers

**Context.** Slash commands are prompts. Prompts rot silently: a command keeps
"working" while producing steadily worse output, and nobody notices.

**Decision.** `eval.sh` scores commands on two layers. Layer 1 is structural
and deterministic: invariants checked against `expectations.tsv`, free to run.
Layer 2 is behavioral: an LLM judge over recorded cases, costly, run on demand.
The metric is always stated as both - "layer 1: X/Y; layer 2: N of K commands"
- never collapsed into one number.

**Alternatives.** Structural checks only - rejected: they cannot see that a
command's output got worse. LLM judging only - rejected: too expensive to gate
on, and non-deterministic as a CI check.

**Consequences.** Layer 1 is usable as a hard gate. Layer 2 stays honest about
its own coverage: "not run" is a legitimate and visible result, so partial
evaluation can never be mistaken for full evaluation.

---

### 9. Consolidation raw material lives outside the git tree

**Context.** Memory consolidation reads session transcripts. Those contain
whatever was discussed - personal context, credentials in passing, and in
medical projects, PHI. The obvious place to write intermediate material is
`docs/`, and that is exactly wrong.

**Decision.** Raw material and drafts are written next to the project's agent
memory, outside the repository -
`<claude-config>/projects/<encoded-root>/consolidation/`, honoring
`CLAUDE_CONFIG_DIR` and identical on every platform. A `docs/consolidation/`
entry stays in `.gitignore` purely as insurance against an override that points
back inside the tree.

**Alternatives.** Write into the tree and rely on `.gitignore` - rejected: one
missing line and private transcripts land in a public repository forever.
Write to a system temp directory - rejected: material must survive between
sessions.

**Consequences.** Nothing generated from transcripts can reach git by accident.
The path is printed by the script on every run, so it is never a mystery where
material went.

---

### 10. Architecture visualization is a hybrid, not a generator

**Context.** An architecture diagram is only worth having if it is current, and
diagram generators that parse code produce either import graphs (true but
meaningless) or nothing.

**Decision.** Two halves with a clean seam. The **data** (`arch-data.json`) is
written by an LLM in-session via `/arch-viz` - understanding what the system
does is the part that needs judgement. The **HTML** is built deterministically
by a script that validates invariants and inlines the JSON into a
self-contained page - no node, no CDN, no runtime dependency. Freshness is
enforced from outside: a prompt hook nudges the session when sources moved
ahead of the data, and CI reports staleness.

**Alternatives.** Full generation from code - rejected: produces a graph nobody
learns anything from. Hand-drawn diagram - rejected: stale within two weeks.
LLM generating the HTML too - rejected: non-reproducible output and no way to
validate it.

**Consequences.** The expensive half runs when architecture actually changes;
the cheap half runs on every push. The published page is one file that opens
offline. Cost: the data is only as good as the last `/arch-viz` run, which is
why staleness is reported rather than assumed away.

---

### 11. Every accepted improvement becomes part of what every project gets

**Context.** Tooling findings - a plugin, a command, a piece of local
infrastructure - get adopted in whichever project happened to be open at the
time, then are lost when attention moves on.

**Decision.** The kit is the accumulator. Anything **accepted** becomes part of
the layer that every project receives at rollout, and is recorded in a wrapping
registry at one of two levels: project (vendored into the repo) or machine
(installed once, only verified at rollout). Entry into the registry happens
through a pilot verdict or an audit, never through enthusiasm.

**Alternatives.** Adopt per project as needed - rejected: that is the failure
mode this record exists to fix. Adopt everything promising immediately -
rejected: the registry becomes a graveyard of half-tried tools.

**Consequences.** New projects start with the current accepted layer rather
than whatever the last project happened to have. The pilot requirement makes
adoption slow on purpose.

---

### 12. The repository publishes tools, not the artifacts of using them on itself

**Context.** The kit is dogfooded: its own commands run against it, so it
accumulates its own audits, implementation plans, handoffs, session snapshots
and decision journals. These are the products of applying the instruments, and
they are full of context that belongs to one owner and one machine.

**Decision.** The public tree carries the instruments and what a user needs to
run them. The owner's working layer - spec, build journal, audits, plans,
handoffs, backlog - lives in `docs/private/`, outside git. Session mechanics
(`NEW_SESSION_PROMPT.md`, `.session-current.md`) follow the `.env` pattern: a
committed `.example` template, the real file ignored. Product-level decisions
are published here; the process journal stays private.

**Alternatives.** Publish everything as evidence of process - rejected: it
exposes private projects and personal context, and it buries the product under
the workshop. Publish nothing but code - rejected: the reasoning is the part
worth reading.

**Consequences.** The root of the repository reads as a product. A reader can
still see how decisions were made - through this file - without reading
someone's working notes.

---

### 13. English is the canonical language of the repository

**Supersedes:** an earlier decision that module READMEs stay in the owner's
language while only agent-facing configs are in English.

**Context.** The kit is published as an open repository. Its earlier rule split
languages by audience - configs and code in English, documentation in the
owner's language - which was right while the repository was private and had one
reader.

**Decision.** Everything in the public tree is English: READMEs, commands,
prompts, rubrics, comments, commit messages, this file. The owner's private
layer stays in whatever language the owner thinks in. Where a translated
artifact is useful locally, the English version is canonical and the
translation is regenerated and git-ignored - the pattern already used for the
architecture visualization.

**Alternatives.** Bilingual repository - rejected: two copies of every document
drift within a month. Translate only the entry points - rejected: a reader hits
the untranslated layer on the second click.

**Consequences.** A one-time translation of the product layer, and the
discipline of writing new product documentation in English from the start. The
private layer costs nothing, because it is never translated at all.
