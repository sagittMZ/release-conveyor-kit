# Why the kit exists

The long version of the [README](../README.md): what problem the kit answers,
the decisions that shaped it, and what broke on the way. The full reasoning,
with alternatives and costs, is in [ARCHITECTURE.md](../ARCHITECTURE.md).

## Four ways an agent simulates work

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

## Six decisions worth reading

The full reasoning, with alternatives and costs, is in
[ARCHITECTURE.md](../ARCHITECTURE.md). These six shaped the kit more than the
rest.

**Honest provenance
([record 4](../ARCHITECTURE.md#4-honest-provenance-proven-vs-added)).**
Roughly half the kit was extracted from production and half was written for the
kit and never run in anger. Presenting both as one thing would be the most
damaging lie the kit could tell, so every README splits them and the split is
never blurred. The kit reads as less finished than it could; that is the point.

**Tools, not traces
([record 12](../ARCHITECTURE.md#12-the-repository-publishes-tools-not-the-artifacts-of-using-them-on-itself)).**
The kit runs its own commands on itself, so it accumulates audits, plans,
handoffs and journals. Those are the products of using the instruments, full
of one owner's context, and they stay in a private layer outside git. The
public tree carries the instruments and the decisions.

**The kit gates itself
([record 14](../ARCHITECTURE.md#14-the-kit-gates-itself-with-the-checks-it-demands-of-others)).**
A tool that gates other repositories while running ungated is not credible.
Every push runs shellcheck, actionlint over the shipped templates,
markdownlint, the layer 1 evals in strict mode, a gitleaks scan of the full
history, and a publishability job that fails if a home path or a private file
ever becomes tracked.

**Two judges, nothing averaged
([record 15](../ARCHITECTURE.md#15-layer-2-judges-real-dispatches-with-two-judges-and-nothing-averaged)).**
An LLM judge stops measuring anything the moment it imagines the repository
instead of seeing it, or grades its own output. So a case gets a real
throwaway repository, the real command is dispatched into it, and two judges
in fresh sessions score it, one on the executor's model and one on a different
model. The gap between their means is the measured size of self-grading bias.

**Done is proven, not declared
([record 17](../ARCHITECTURE.md#17-done-is-proven-not-declared)).**
A model that spent an hour on a feature honestly believes in it. The direction
fixed here: acceptance criteria that start as *fail* and flip only with
attached evidence, and an evaluator that never saw the work happen. The record
fixes the direction; the commands that implement it are on the backlog.

**Sessions survive the machine
([record 18](../ARCHITECTURE.md#18-sessions-survive-the-machine-respawn-from-a-manifest-once-per-boot)).**
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
