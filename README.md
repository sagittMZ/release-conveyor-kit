# Release Conveyor Kit

Release pipeline + agent sessions, as modules.

[![CI](https://github.com/sagittMZ/release-conveyor-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sagittMZ/release-conveyor-kit/actions/workflows/ci.yml)

A release pipeline and an agent harness, delivered as modules that an AI agent
applies to a repository you already have. It is not an npm package and not a
CLI: each module is a folder with a README that says where its content came
from, a checklist that defines what "applied" means, and templates with markers
where a project-specific value goes. Half of it was extracted from one
production pipeline (React/TS + Vite + Capacitor + Supabase + Vercel + GitHub
Actions + Codemagic); that project is called *the donor* throughout the kit,
and "extracted from the donor" means the file ran there in production before
it was generalized here. The other half is about how a human and an agent work together on
any repository in any language, and it is the half most people come here for.

- Four levels of explanation, from a ten-year-old to an engineer:
  [docs/EXPLAIN.md](docs/EXPLAIN.md)
- How it is put together and why, as 18 numbered decision records:
  [ARCHITECTURE.md](ARCHITECTURE.md)
- Live example: [the kit's own architecture](docs/arch/index.html), one
  self-contained HTML file rebuilt by CI

## Why it exists: four ways an agent simulates work

A well-known essay on working with AI agents lists four corners where an agent
stops doing the work and starts simulating it. The kit was not built from that
list, but it maps onto it almost one to one, and the list is the shortest
honest description of what the kit is for. Its lesson in a chat is a prompt.
The kit's lesson is that a prompt is the first rung of a ladder whose top is a
check nobody has to remember to run.

### Corner 1: a word instead of a trace

"Done", "tested", "verified" - with nothing attached. The essay's cure is to
demand the object: the line, the number, the artifact.

The kit's cure is to stop believing the author at all. Record 17, *done is
proven, not declared*, says the author of a change is the least reliable
witness to its success. Module 11 turns that into a number: layer 1 is a
deterministic structural check over every slash command (free, runs as a CI
gate), and layer 2 dispatches the real command into a throwaway repository
built by a script and has two judges in fresh sessions score the answer,
nothing averaged. Module 06 and the kit's own CI scan the full history for
secrets, not just the working tree. Every module README splits its content into
*extracted from a working donor (proven)* and *added by the kit (not verified)*,
and nothing moves from the second column to the first without having run.

### Corner 2: a result without the road

A one-verb request ("do the release") gets a confident answer with no
procedure behind it. The essay's cure: name the accepted procedure first, then
walk it.

The kit's cure is to make the procedure a file. Module 09 ships fourteen slash
commands, each a fixed procedure for a recurring moment: `/spec` interviews you
before writing a spec, `/impl-plan` produces a phased plan by a team of roles
before any code, `/precommit` reviews the diff against a checklist,
`/release-notes` groups commits between two points by type, `/security-scan`
runs in a subagent and reports on a path. The commands reference the project's
own `.ai/` role files when they exist and degrade to a sensible default when
they do not. Module 08 does the same for the release pipeline itself: interview,
stack detection, apply, verify, and a report that says *applied and verified*,
*applied and NOT verified*, *manual step* or *skipped*, each with a reason.

### Corner 3: memory as hope

One giant chat that is supposed to remember everything, until it does not. The
essay's cure: a numbered rulebook, and a note to the next session in a fixed
form.

The kit's cure is to give memory a place and a lifecycle. `/session-wrap` ends
a session with a 15-line snapshot: what was done, how it was verified, the
current state, the next step, the blockers. `/handoff` writes the kickoff
prompt for the next session and moves history into a ledger instead of letting
the prompt grow. Module 12 distills session transcripts into reviewable
insights on a schedule, with the raw material kept outside the git tree because
transcripts contain whatever was discussed. Module 14 goes one level down:
after a reboot, every agent session comes back from one manifest with its chat
topic binding intact, so a restart of the machine stops being an incident.
Rules live in `AGENTS.md`, numbered, and the repository's own CI enforces the
ones that can be enforced.

### Corner 4: a form without slots

The agent agrees. It restates the task, offers a plan, and never once names
the strongest objection or the nearest alternative. The essay's cure is a
mandatory slot for the objection before the proposal.

This is the corner the kit covers least. `/impl-plan` plans through a team of
roles, `/audit` reviews through role lenses, `/scope-triage` forces a choice of
the top two or three blocks with coupling in mind. None of them has a
mandatory objection slot yet. It is on the backlog, and it is listed here so
that nobody mistakes the other three corners for four.

## What is in the box

| Layer | Modules | What it is | Where it came from |
|---|---|---|---|
| A. Release pipeline | 01 ci-core, 02 mobile-build, 03 store-deploy, 04 staging, 05 monitoring, 06 secrets, 07 smoke-e2e, 08 agent-layer | CI, Android and iOS builds, store playbooks, staging, Sentry, secrets hygiene, a Playwright smoke suite, and the prompts that apply all of it | Extracted from the donor (ran in production) where a README says so; the rest added by the kit and marked *not verified* per file |
| B. Agent harness | 09 prompt-library, 11 command-evals, 12 memory-consolidation, 13 arch-viz | Slash commands and prompt patterns, command quality as a number, memory distillation, an architecture page CI keeps honest | Added by the kit, verified by dogfooding: the kit runs all of it on itself |
| C. Machine level | 14 session-respawn | Agent sessions and their chat-topic bindings rebuilt from one manifest after a reboot | Added by the kit, *not verified*: see below |

Layer A is tied to one stack and changes when that stack changes. Layer B has
nothing to do with React or Supabase and can be rolled into any repository on
its own. Layer C is about the workstation that hosts the sessions, not about
any repository. Module 10 (a test coverage matrix) has a reserved number and is
not built.

## Six decisions worth reading

The full reasoning, with alternatives and costs, is in
[ARCHITECTURE.md](ARCHITECTURE.md). These six shaped the kit more than the
rest.

**Honest provenance
([record 4](ARCHITECTURE.md#4-honest-provenance-proven-vs-added)).**
Roughly half the kit was extracted from production and half was written for the
kit and never run in anger. Presenting both as one thing would be the most
damaging lie the kit could tell, so every README splits them and the split is
never blurred. The kit reads as less finished than it could; that is the point.

**Tools, not traces
([record 12](ARCHITECTURE.md#12-the-repository-publishes-tools-not-the-artifacts-of-using-them-on-itself)).**
The kit runs its own commands on itself, so it accumulates audits, plans,
handoffs and journals. Those are the products of using the instruments, full
of one owner's context, and they stay in a private layer outside git. The
public tree carries the instruments and the decisions.

**The kit gates itself
([record 14](ARCHITECTURE.md#14-the-kit-gates-itself-with-the-checks-it-demands-of-others)).**
A tool that gates other repositories while running ungated is not credible.
Every push runs shellcheck, actionlint over the shipped templates,
markdownlint, the layer 1 evals in strict mode, a gitleaks scan of the full
history, and a publishability job that fails if a home path or a private file
ever becomes tracked.

**Two judges, nothing averaged
([record 15](ARCHITECTURE.md#15-layer-2-judges-real-dispatches-with-two-judges-and-nothing-averaged)).**
An LLM judge stops measuring anything the moment it imagines the repository
instead of seeing it, or grades its own output. So a case gets a real
throwaway repository, the real command is dispatched into it, and two judges
in fresh sessions score it, one on the executor's model and one on a different
model. The gap between their means is the measured size of self-grading bias.

**Done is proven, not declared
([record 17](ARCHITECTURE.md#17-done-is-proven-not-declared)).**
A model that spent an hour on a feature honestly believes in it. The direction
fixed here: acceptance criteria that start as *fail* and flip only with
attached evidence, and an evaluator that never saw the work happen. The record
fixes the direction; the commands that implement it are on the backlog.

**Sessions survive the machine
([record 18](ARCHITECTURE.md#18-sessions-survive-the-machine-respawn-from-a-manifest-once-per-boot)).**
One session per project, each in a tmux window, each bound to a chat topic.
The bridge and tmux come back after a boot; the sessions do not. Module 14
rebuilds them from one manifest, once per boot, with loop protection that is
layered and boring: a lock, a ceiling, no `Restart=`, a dry run before the
unit is ever enabled.

## What broke on the way

Each of these is a decision record because it hurt first.

- **The donor ran one Node version in CI and pinned another in the tree.**
  Versions became parameters of the config, never constants in a template
  (record 3).
- **A model asked to picture an empty repository answers about itself.** The
  obvious design of the evals would have asked the model what a command
  *would* answer. Instead a script builds the repository and the command
  really runs (record 15).
- **Symlinks broke the moment the tree was cloned on Windows.** The dogfood
  copies of the commands became real files, with a CI diff that fails on drift
  (record 16).
- **Prompts rot silently.** A command keeps its name while its behaviour
  drifts, and nobody notices until a bad release. That is why command quality
  is a number, reported in two layers so a partial score is never mistaken for
  a full one (record 8).
- **Re-creating eight sessions by hand after a reboot hit the same traps every
  time.** Window order decides which topic talks to which project, a resume
  dialog blocks a window until a key is pressed, stopping the bridge with
  windows alive wipes its map. The manifest and the script exist because the
  traps were real (record 18).

## Not verified

The kit never presents an unrun template as proven. As of this release the
following are *added by the kit, not verified*, and their READMEs say so:

- **Module 14, session respawn.** Syntax, shellcheck and dry runs pass in all
  three modes. The first real reboot with the unit enabled did not pass: the
  unit had a hard dependency on the bridge, so when the script stopped the
  bridge the service manager stopped the script with it. That is fixed. The
  first real cold run, after a power loss, brought every window, binding and
  session back, but the bridge treated more than half of the windows as dead
  until it was restarted by hand. The script now does that restart itself and
  checks the result; that change has not run in a real cold start, and the
  module stays *not verified* until one passes clean.
  A known limitation is documented in the module: a warm run for a window
  whose topic binding is missing lets the bridge create a fresh topic instead
  of rebinding the one from the manifest.
- **iOS TestFlight publishing.** The Codemagic bootstrap (generate the iOS
  project, compile unsigned) is from the donor and proven. Signing and
  publishing to TestFlight are a scaffold marked TODO (module 02); the App
  Store playbook beyond the first wave is written, not run (module 03).
- **Staging as a second Supabase project.** The donor ran QA accounts on one
  project; that variant is proven. The second-project variant is instructions
  that were never run against a live project (module 04).
- **Parts of monitoring and secrets.** Sourcemap upload, the release version
  define and the health-check cron in module 05, and the gitleaks workflow in
  module 06, were added after an audit found the gaps in the donor. The
  gitleaks workflow runs in the kit's own CI; the health-check cron has not
  run anywhere yet (the kit has no production URL to check).
- **Store playbook additions.** Data Safety notes and the Play API upload job
  in module 03.

Everything marked proven in a module README was extracted from the donor's
production pipeline as it ran there.

## A day with it

One agent session per project, each in its own tmux window, each bound to one
topic of a forum group in a messenger, through a bridge daemon that maps topic
to window. From a phone, a message in a topic reaches that project's session
and the answer comes back to the same topic. `/session-wrap` closes the day
with a snapshot, `/handoff` writes the next session's kickoff, and after a
reboot module 14 brings the whole fleet back from the manifest.

The bridge is a replaceable part. The only one proven with the kit is a
Telegram-to-tmux bridge; a Slack bridge would slot in by analogy, but none
has been run with module 14, so the module says Telegram and means it.

## How to try it

The stack-independent layer (modules 09, 11, 12 and 13) rolls into any
repository with the prompt in
[modules/09-prompt-library/ROLLOUT.md](modules/09-prompt-library/ROLLOUT.md):
the agent of the target project takes the sources from your clone of the kit
and places them by that project's own conventions, as real files with a
provenance stamp. The release pipeline (modules 01-08) starts from
[conveyor.config.example.json](conveyor.config.example.json) and the prompt in
[modules/08-agent-layer/](modules/08-agent-layer/). The kit applies all of this
to itself: its own slash commands are CI-guarded copies of module 09, its own
CI is the gate it ships, and its own architecture page is built by module 13.

## What stays manual

Creating accounts and paying for them (Google Play, Apple Developer, Codemagic,
Sentry), entering secrets into GitHub, Codemagic and Vercel, the buttons in
store consoles and *Submit for review*, alert rules in the Sentry UI. For each
of these the modules produce a short numbered instruction instead of pretending
to automate it. A map of every secret the pipeline uses, and where the owner
puts the real value, is in
[modules/06-secrets/README.md](modules/06-secrets/README.md). Neither this
repository nor your project ever holds a real value.

## Modules

| # | Module | What it gives you |
|---|---|---|
| 1 | [ci-core](modules/01-ci-core/) | Lint + typecheck + unit + build on every PR |
| 2 | [mobile-build](modules/02-mobile-build/) | Android AAB/APK via Actions, iOS via Codemagic (Capacitor 8, SPM) |
| 3 | [store-deploy](modules/03-store-deploy/) | Google Play and TestFlight: what is automated, and step-by-step instructions for what cannot be |
| 4 | [staging](modules/04-staging/) | Staging for Supabase: a second project, or QA accounts on the free tier |
| 5 | [monitoring](modules/05-monitoring/) | Sentry: init, release tags, sourcemaps, alerts, health check |
| 6 | [secrets](modules/06-secrets/) | `.env` patterns, `.gitignore`, gitleaks in CI, a map of every secret |
| 7 | [smoke-e2e](modules/07-smoke-e2e/) | Playwright smoke suite (5-8 scenarios) as a template |
| 8 | [agent-layer](modules/08-agent-layer/) | The application prompts: interview -> stack detection -> apply -> verify |
| 9 | [prompt-library](modules/09-prompt-library/) | 6 prompt patterns + 21 prompts by project phase + 14 slash commands. Stack-independent |
| 10 | coverage-matrix | Test coverage matrix. Number reserved, module not built |
| 11 | [command-evals](modules/11-command-evals/) | Command quality as a number: structural checks + an LLM judge. Stack-independent |
| 12 | [memory-consolidation](modules/12-memory-consolidation/) | Distilling session history into reviewable insights, on files, for free. Stack-independent |
| 13 | [arch-viz](modules/13-arch-viz/) | Interactive architecture visualization as one self-contained HTML file; CI watches it for staleness. Stack-independent |
| 14 | [session-respawn](modules/14-session-respawn/) | Agent sessions and their chat-topic bindings come back after a reboot from one manifest, with loop protection. Stack-independent, machine-level |

Guide and worked examples: [docs/prompt-kit-guide.md](docs/prompt-kit-guide.md).
Rules for working on this repository: [AGENTS.md](AGENTS.md).

## License

MIT - see [LICENSE](LICENSE).
