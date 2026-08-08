# Rolling the stack-independent layer into a project

Full installation of the kit's stack-independent layer (modules **09 + 11 + 12
+ 13**) into a target project. It is executed by an agent in the session of the
TARGET project itself: the agent takes the sources from the kit and integrates
them ORGANICALLY, following the project's own conventions, rather than dropping
"pieces of the kit" into it.

Set the path to the kit once: `KIT=<path-to-your-clone-of-the-kit>` (for
example `KIT=~/projects/release-conveyor-kit`). Everything below uses `$KIT`.

**What is included, and why only this:**
- 09 (commands + menu), 11 (evals), 12 (memory consolidation), 13 (arch-viz) are
  stack-independent.
- 01-08 are the release pipeline for React/Vite/Supabase and do not travel to
  other stacks.
- 10 (coverage-matrix) is not built, only backlogged. There is nothing to roll
  out.

Paste the prompt below into the target project's session.

## Rollout prompt (any stack)

```
Install the release kit's stack-independent layer (modules 09+11+12+13) into
this project from: <path-to-your-clone-of-the-kit>

Goal: this project must end up SELF-SUFFICIENT and ORGANIC - no "pieces of the
kit", everything placed by this project's conventions. Do not touch any
application code. Show me the git diff and wait for my word before committing.

KIT=<path-to-your-clone-of-the-kit>
KIT_STAMP="release-conveyor-kit@$(git -C $KIT rev-parse --short HEAD) $(date +%F)"

0. PROVENANCE (rule that applies throughout): every copied artifact gets the
   $KIT_STAMP stamp - otherwise, across three or more projects, the copies drift
   apart with no way to notice. How to stamp is in the steps below; reconciling
   later: tools/prompt-kit/check-provenance.sh.

1. COMMANDS (14) -> .claude/commands/ as REAL files (not symlinks into the kit):
   copy $KIT/modules/09-prompt-library/commands/*.md.
   The list: spec, precommit, session-wrap, release-notes, security-scan,
   edge-cases, backlog, scope-triage, handoff, impl-plan, audit, eval-command,
   consolidate-memory, arch-viz.
   Into every copied file add this line to the frontmatter (after description:):
   provenance: $KIT_STAMP

2. MENU LIBRARY -> this project's docs/prompts/library/:
   copy $KIT/modules/09-prompt-library/PATTERNS.md and .../library/.
   IDEMPOTENCY: if docs/prompts/ is already taken (for example by large
   PROMPT_*.md files), do NOT overwrite - put the menu into a separate
   docs/prompts/library/ and merge only.
   Add this as the FIRST line of PATTERNS.md and of every file in library/:
   <!-- provenance: $KIT_STAMP -->

3. GUIDE -> docs/prompt-kit-guide.md: copy $KIT/docs/prompt-kit-guide.md (the
   same relative location it has in the kit) and add the same
   <!-- provenance: $KIT_STAMP --> as its first line.

4. TOOLING (the evals and consolidation harness) -> tools/prompt-kit/, VENDORED:
   tools/prompt-kit/
     lib-transcripts.sh            <- $KIT/modules/09-prompt-library/usage-digest/lib-transcripts.sh
     usage-digest.sh               <- $KIT/modules/09-prompt-library/usage-digest/usage-digest.sh
     command-evals/                <- everything from $KIT/modules/11-command-evals/
       (eval.sh, expectations.tsv, RUBRIC.md, cases/, judge/)
     memory-consolidation/         <- consolidate.sh, DISTILL_RUBRIC.md from $KIT/modules/12-memory-consolidation/
     arch-viz/                     <- template.html, build-arch-viz.sh, freshness-hook.sh, README.md, checklist.md from $KIT/modules/13-arch-viz/
     check-provenance.sh           <- $KIT/modules/09-prompt-library/check-provenance.sh
     PROVENANCE                    <- two lines:
                                      vendored from $KIT_STAMP
                                      kit path: $KIT

5. FIX THE PATHS in the two copied meta-commands (.claude/commands/): in
   eval-command.md and consolidate-memory.md replace the harness path prefixes:
     modules/11-command-evals/        -> tools/prompt-kit/command-evals/
     modules/12-memory-consolidation/ -> tools/prompt-kit/memory-consolidation/
   (The scripts locate the project root through git and their lib next to
   themselves - they need no edits, only the references inside the command
   texts do.)

6. WIRING -> a section in the project's AI_WORKFLOW.md (that is where it belongs
   in the hierarchy, not CLAUDE.md; if there is no AI_WORKFLOW.md, add a line to
   CLAUDE.md):
   "Prompt-kit layer: guide docs/prompt-kit-guide.md; menu docs/prompts/library/
   (start with PATTERNS.md); tooling tools/prompt-kit/. Slash commands: /spec
   /precommit /session-wrap /release-notes /security-scan /edge-cases /backlog
   /scope-triage /handoff /impl-plan /audit /eval-command /consolidate-memory
   /arch-viz."

7. GITIGNORE (publishability): add to the project's .gitignore if not there yet:
   docs/evals/
   docs/consolidation/
   (docs/evals/ holds the eval scorecards - private and reproducible.
   Consolidation raw material is written OUTSIDE the tree by default, into
   <claude-config>/projects/<enc>/consolidation/ (base: CLAUDE_CONFIG_DIR,
   otherwise ~/.claude - identical on every platform); the docs/consolidation/
   line is insurance against a CONSOLIDATE_OUT_DIR override pointing inside.)

7b. ARCH-VIZ WORKFLOW: copy $KIT/modules/13-arch-viz/templates/arch-viz.yml to
   .github/workflows/arch-viz.yml and adjust the conveyor markers: the branch,
   the builder path (tools/prompt-kit/arch-viz/build-arch-viz.sh) and the source
   paths watched for staleness (for example src/). Generate the data the first
   time with the /arch-viz command in a session (that is the LLM step, not CI)
   and commit docs/arch/ together with the rollout.
   AUTO-TRIGGER (the main loop, no owner involvement): add to the project's
   .claude/settings.json (merging, without clobbering existing hooks)
   hooks.UserPromptSubmit -> command:
   ARCHVIZ_SRC_PATHS="src/" bash tools/prompt-kit/arch-viz/freshness-hook.sh
   (same paths as in the workflow). When the visualization goes stale the hook
   gives the running session the task of refreshing it in the current turn; it
   nudges at most once a day.
   HARD FRESHNESS GUARANTEE (external backstop, an owner step): put three
   secrets into Settings -> Secrets and variables -> Actions -
   TELEGRAM_BOT_TOKEN (the owner's bot), TELEGRAM_CHAT_ID (the forum group id),
   TELEGRAM_THREAD_ID (THIS project's topic in that forum group). CI then pings
   the project's topic directly when the visualization is stale, once per
   episode. To test the wiring: Run workflow with test_notify=true.

8. SCALING PLAN -> the project's BACKLOG (do NOT implement):
   - Multi-agent orchestration (a coordinator plus parallel subagents) for wide
     decomposable tasks (audits, research). Condition: such tasks appearing.
   - Cloud managed agents + dreaming-as-a-service + hosted evals - when there is
     money, scale, and a need for unattended agents.

9. VERIFICATION (run it and show the result):
   - bash tools/prompt-kit/command-evals/eval.sh --all -> layer 1 = 100% across
     the kit's 14 commands (the harness reads this project's .claude/commands by
     itself); this project's OWN commands land in the "outside expectations"
     section - that is normal, not a failure; to bring them into scoring, add
     rows for them to tools/prompt-kit/command-evals/expectations.tsv. The
     "layer 2" line will honestly say "not run" - the behavioral pass in the
     target project is optional (/eval-command --judge);
   - bash tools/prompt-kit/memory-consolidation/consolidate.sh --days 7 ->
     creates material-<date>.md in <claude-config>/projects/<enc>/consolidation/
     (the script prints the path) without errors, and NO file appears inside the
     project tree;
   - git status -> clean of eval and consolidation artifacts (docs/evals/ hidden
     by gitignore, consolidation raw material physically outside the tree);
   - bash tools/prompt-kit/check-provenance.sh --strict -> every artifact
     stamped, no drift (a fresh rollout sits on the kit's HEAD);
   - the machine-level wrapping is in place: the tools in the owner's registry
     answer to `--version` (if not, install them BEFORE working in the project);
   - checklists: $KIT/modules/09-prompt-library/checklist.md,
     $KIT/modules/11-command-evals/checklist.md,
     $KIT/modules/12-memory-consolidation/checklist.md.

10. REPORT: what was copied where, the verification results, what went to the
    BACKLOG. Leave stack-specific commands as they are (security-scan detects
    Supabase by itself; release-notes works with any git). If a command has
    nothing to do in this project, note that in the report - do not delete it.
    Wait for my word before committing.
```

## The project's agent environment - the zero-wrapping principle

The kit is the accumulator of accepted improvements: EVERY project, new or
existing, receives the whole accepted infrastructure layer when it is wrapped.
Otherwise findings are lost as soon as attention moves on. Two levels:

- **Project level** (vendored into the project's repo by the rollout): commands,
  menu, guide, tooling (steps 1-9), accepted plugins - through `enabledPlugins`
  in the project's `.claude/settings.json`.
- **Machine level** (installed once per machine; the rollout only VERIFIES it):
  shared tooling, locally pinned plugin clones.

The kit's owner keeps their own **wrapping registry** - a table of component /
level / status - outside the public repository (`docs/private/`), because it is
the state of one machine and one set of projects, not part of the product.
Row template: `| <component> | project \| machine | in the wrapping \| pilot until <date> |`.

A new component enters the registry only through a pilot verdict or an audit,
never through enthusiasm. Accepted means added both to the registry and to the
rollout prompt.

## After the rollout

- A week or two later, run `tools/prompt-kit/usage-digest.sh`: what actually got
  used.
- Updating the kit -> the project: `bash tools/prompt-kit/check-provenance.sh`
  shows how far the stamps lag behind the kit's HEAD and which sources changed;
  port the changes you want and update the stamps (this is vendoring, not a
  submodule - the project owns its copy).
- The scheme above is identical for every project - that is the whole point of
  having one.
