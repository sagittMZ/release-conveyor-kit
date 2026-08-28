# Release Conveyor Kit (v0)

[![CI](https://github.com/sagittMZ/release-conveyor-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sagittMZ/release-conveyor-kit/actions/workflows/ci.yml)

A release pipeline you hand to an AI agent, which applies it to an app you have
already built. Target stack: React/TS + Vite + Capacitor + Supabase + Vercel +
GitHub Actions + Codemagic. The patterns were extracted from a working
production pipeline of a private donor project, not invented for a demo.

Four of the modules do not depend on that stack at all. They are about how a
human and an agent work together on a repository, and they apply to any project
in any language - see [the stack-independent layer](#stack-independent-layer).

- What this is, at four levels of detail, plus the "I only have an idea"
  scenario: [docs/EXPLAIN.md](docs/EXPLAIN.md)
- How it is put together and why: [ARCHITECTURE.md](ARCHITECTURE.md)
- Live example: [the kit's own architecture](docs/arch/index.html), a single
  self-contained HTML file

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

## Quick start

1. Copy `conveyor.config.example.json` into your project root as
   `conveyor.config.json` and fill it in.
2. Give your agent the prompt from `modules/08-agent-layer/`. It detects the
   stack, applies modules 1-7 and 9 according to the config, and runs
   verification.
3. Or apply a single module by hand: each one is self-contained, with the
   secrets it needs and a `checklist.md` that defines what "applied" means.

## Stack-independent layer

Modules 09, 11, 12, 13 and 14 have nothing to do with React or Supabase. They
can be applied alone, to any repository (14 to the machine that hosts them):

- **Commands and prompts** - 14 slash commands for the recurring moments of
  work (spec, pre-commit review, release notes, security scan, handoff,
  implementation plan, audit), plus a menu of prompts organized by project
  phase.
- **Evals** - command quality measured in two layers: deterministic structural
  checks that are free to run as a CI gate, and an LLM judge over recorded
  cases for behavior. The score is always reported as both, so partial
  evaluation is never mistaken for full evaluation.
- **Memory consolidation** - session history distilled into reviewable
  insights. Collection is deterministic bash and costs nothing; the raw
  material is written outside the git tree, because transcripts contain
  whatever was discussed.
- **Architecture visualization** - an LLM updates the data in-session, a script
  deterministically builds a self-contained page, CI reports when it goes
  stale.
- **Session respawn** - a manifest of agent sessions (tmux window, project,
  chat topic, model, resume mode) and a script that brings them all back after
  a reboot, once, with the bindings intact and a hard ceiling on processes.

Guide and worked examples: [docs/prompt-kit-guide.md](docs/prompt-kit-guide.md).
Rollout into an existing project:
[modules/09-prompt-library/ROLLOUT.md](modules/09-prompt-library/ROLLOUT.md).

## Secrets

A map of every secret the pipeline uses - what it is, where it is stored, which
module needs it - is in
[modules/06-secrets/README.md](modules/06-secrets/README.md). Neither this
repository nor your project ever holds a real value: only placeholders, and the
instruction for where the owner puts the real one.

## What stays manual

Creating accounts and paying for them (Google Play $25, Apple Developer $99/yr,
Codemagic, Sentry), entering secrets into GitHub / Codemagic / Vercel, the
buttons in store consoles and Submit for review, alert rules in the Sentry UI.
For each of these the modules produce a short numbered instruction instead of
pretending to automate it.

## Proven vs added

Every module README has an "Origin" section that splits its content in two:
what was extracted from the working donor project (proven in production) and
what was added by the kit (marked "not verified" until it has actually run).
This is a hard rule throughout: the kit never presents an unrun template as
battle-tested. It is why the modules read as less finished than they could -
you can tell which parts to trust.

## License

MIT - see [LICENSE](LICENSE).
