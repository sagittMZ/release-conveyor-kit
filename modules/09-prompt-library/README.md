# Module 09 - prompt-library

The starter prompt library the conveyor installs into a target project
alongside the pipeline. The pipeline answers "how a release is built and
shipped"; the library answers "how the owner and the agent talk about this
project".

## How it differs from the other modules

**Stack-independent.** The only module that applies to any project (Python,
Next.js, anything), including SEPARATELY from modules 01-07. The scope guard in
AGENTS.md does not apply to it: if the target project's stack is out of v0
scope, module 09 is still applied.

## Two levels: menu and commands

The library is a copy-paste menu, for a human. The commands are invoked as
`/name`. That is exactly the escalation ladder: whatever you actually use rises
from the menu into a command - easier from a phone, and every invocation is
logged.

| File | What it is |
|---|---|
| PATTERNS.md | 6 prompt-writing patterns + the escalation ladder. The owner reads it once |
| library/&lt;phase&gt;/*.md | 21 menu prompts: one file per prompt, YAML frontmatter (id, phase, category, roles, needs, module) + the text + "why it works" + "how to escalate it" |
| commands/*.md | 14 Claude Code slash commands (table below). Installed into the project's `.claude/commands/`, invoked in chat, logged |
| usage-digest/ | Analyzer: how many times each command was invoked this week, read from transcripts |
| ROLLOUT.md | The rollout spec and prompts for installing this layer into a project |
| check-provenance.sh | Reconciles vendored copies with the kit: every artifact carries a `kit@<sha>` stamp, and the script reports the lag behind the kit's HEAD and which sources changed. Vendored into tools/prompt-kit/ at rollout |
| checklist.md | Verification of the application |

Phases: discover / design / build / ship / operate / automate.
Role tags: pm, design, docs, marketing, security, ops, data. An empty role list
means the prompt is universal. For a solo owner the roles are "lenses": ask the
project as a PM would, as a security engineer would.

## Application

1. `PATTERNS.md` and `library/` -> the target project's `docs/prompts/library/`
   (the menu).
2. `commands/*.md` -> the target project's `.claude/commands/` (slash commands).
3. Add a section to the target project's AI_WORKFLOW.md - a pointer to
   `docs/prompts/library/` and the list of commands (ROLLOUT.md has a
   ready-made prompt).
4. Run checklist.md.

Idempotency: if `docs/prompts/` is already taken in the project (say it already
holds large PROMPT_*.md files), the kit's menu goes into a separate
`docs/prompts/library/` - existing content is merged with, never overwritten.

Slots in the menu prompts are `{in curly braces}`, with example values under
them. In commands, arguments are substituted as `$ARGUMENTS` / `$1 $2`.

## Commands (14)

Commands reference roles conditionally: if the project has the named `.ai/`
file, the command checks against it; without it, the command degrades to a
sensible default (see "Roles are your .ai/" in PATTERNS.md).

| Command | .ai/ role | What it does |
|---|---|---|
| /spec | PRODUCT_OWNER, PROJECT_POLICIES | feature interview -> SPEC.md |
| /precommit | PROJECT_POLICIES, SECURITY_CHECKLIST | review of uncommitted changes before a commit |
| /session-wrap | - | session snapshot (done / state / next / blockers) |
| /release-notes | - | release notes between two tags |
| /security-scan | SECURITY_CHECKLIST, SECURITY_AUDITOR | security review of a path, run by a subagent |
| /edge-cases | QA_ENGINEER | edge cases and empty states for a feature |
| /backlog | PRODUCT_OWNER, PROJECT_POLICIES | file a task into the backlog / rank by priority |
| /scope-triage | PRODUCT_OWNER | top 2-3 task blocks, priority adjusted for coupling |
| /handoff | - | kickoff prompt for a new session (handing over context) |
| /impl-plan | a team of roles (architect/full-stack, UX, PO, SDET/QA, security, PROJECT_POLICIES) | phased implementation plan from a finished spec + an uncertainty gate |
| /audit | - (multi-lens) | analytical note on the project -> a .md in docs/ + a summary |
| /eval-command | - | structural evals of the commands (module 11, layer 1) + delta against the baseline |
| /consolidate-memory | - | distill memory raw material (module 12) into a reviewable DRAFT |
| /arch-viz | - | refresh the architecture visualization (module 13): data + built HTML |

## Language

**Commands are written in English.** All 14 of them are, and so is everything
else in this repository - the same convention the rest of the industry follows,
and the kit's own rule (record 13 in `ARCHITECTURE.md`). Write your own commands
in English too: they are read by a model and by whoever forks your project next.

**The language you and the agent speak is a separate thing, and the kit does not
touch it.** It comes from your own environment - your global or project
`CLAUDE.md` - so an English command answers you in Spanish, Russian or anything
else, without a single edit here.

If you do write a command in another language, nothing breaks. The evals in
module 11 only score commands that have a row in `expectations.tsv`; your own
commands are listed as "outside expectations" and are neither passed nor failed
until you declare them there. The structural checks also recognize a handful of
Russian phrasings besides the English ones, so a command is judged on the
guarantee it makes rather than the language it makes it in.

## Links to the other modules

| Prompt | Module |
|---|---|
| ship/ci-workflow | 01-ci-core |
| ship/release-notes | 03-store-deploy |
| operate/supabase-logs | 04-staging |
| operate/incident-investigate | 05-monitoring |
| operate/security-review | 06-secrets |
| operate/smoke-fix | 07-smoke-e2e |

## Origin

This module was ADDED by the kit - it is not extracted from the donor. Its
source is Anthropic's prompt library (code.claude.com/docs/en/prompt-library,
July 2026): the taxonomy (phase x category x role), the six patterns and about
40% of the prompts, adapted to the kit's stack. The prompt texts are
provider-independent; only the "escalate it" blocks (CLAUDE.md, skills, hooks)
are Claude-specific.
