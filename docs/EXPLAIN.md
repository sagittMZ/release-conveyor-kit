# What the Release Conveyor Kit is - explained at four levels

An answer to "what is this / how does it work / why would I want it" for four
different audiences. Also usable as raw material for a landing page or a talk.

## The one-line analogy

You wrote a book (the app). The kit is the printing house with a conveyor: it
takes your manuscript and prints it, binds it, proofreads it and delivers it to
the shops. You write the book; the conveyor does everything after that.

## To a ten-year-old

**What it is.** Imagine you built a great game out of building blocks. Now you
want to show it to your friends: put it in a box, check nothing fell off, carry
it to the toy shop. The kit is a magic robot helper that does all of that for
you, every time you change something in the game.

**How it works.** You tell the robot once how your game is put together. After
that, whenever you change the game, the robot checks by itself that it is not
broken, packs it into the box and carries it to the shop. If something fell off,
the robot waves a red flag and does not let the broken version reach your
friends.

**Why you want it.** So you never have to do the boring part by hand, and so
your friends never get a broken game.

## To a non-technical adult who builds things by chatting with an AI

**What it is.** You built a working app by chatting with an AI - that is great,
but it is only half the job. The other half is "release": checking that the new
version did not break the old one, building an installable file, publishing to
the App Store / Google Play / a website, and watching that it does not crash for
people. Normally that is weeks of fiddling with settings nobody explained to
you. The kit is those settings, ready-made, plus the instructions your AI agent
needs to apply them to your app.

**How it works.** You do not learn the details. You tell your AI agent: "apply
this kit". The agent asks you a few simple questions (what the app is called,
do you need Android or iPhone, which accounts you have), then puts all the
technical files in place itself and checks that everything works. Where your own
hand is required - registering a developer account and paying for it, say - the
agent gives you a short "do these 3 steps" list.

**Why you want it.** So the app you built actually reaches people and keeps
working, without you spending a month learning DevOps. From "it works on my
laptop" to "it is in the store and updates itself".

## To someone who understands IT but has never built release plumbing

**What it is.** A deliverable release layer (CI/CD + monitoring + store
processes) for one specific stack: React/TS + Vite + Capacitor + Supabase +
Vercel, with CI on GitHub Actions and Codemagic. Not a starter for a new app -
plumbing on top of an MVP that already exists. It ships as templates with
placeholders plus the prompts for an AI agent that applies them.

**How it works.** One `conveyor.config.json` parameterizes everything (names,
identifiers, branches). Eight independent modules (CI, mobile builds, store
deployment, environments, monitoring, secrets, smoke tests, the agent layer).
The agent runs an interview -> detects the stack -> applies the modules in order
-> verifies each one against its checklist -> hands back a report of "what was
applied / what was verified / what is left for you". The principles: idempotency
(re-applying breaks nothing), config-first, secrets as placeholders only,
nothing pushed without a green check.

**Why you want it.** Because building this plumbing from scratch means weeks of
reading documentation for each tool and stepping on every rake along the way
(Android signing, SPM in Capacitor 8, Playwright sharding, secret leaks). The
kit hands you the path already walked: the same plumbing that actually runs in a
production project, in an evening instead of weeks.

## To an engineer

**What it is.** A release pipeline extracted from production and generalized
into an applicable kit: a set of GitHub Actions workflows, a codemagic.yaml, the
Sentry initialization, a Playwright smoke suite, gitleaks, and a pattern for QA
environments on a free-tier Supabase - all parameterized through one config and
applied through an agent scenario (AGENTS.md + apply-kit.md).

**How it works.** The scope is deliberately pinned to one stack (React/TS +
Vite + Capacitor + Supabase + Vercel + GH Actions + Codemagic) - that pinning is
the strategy: deep support for one familiar stack rather than a multi-stack
machine. The modules:
1. ci-core - lint + unit + build on PRs, caching, concurrency.
2. mobile-build - Android AAB/APK signed through injected gradle props,
   versionCode = run_number; iOS on Codemagic, Capacitor 8 means SPM
   (App.xcodeproj, no CocoaPods and no workspace).
3. store-deploy - Google Play + TestFlight, automated where the API is stable
   and step-by-step instructions everywhere else (this module stays in prose on
   purpose - the stores keep changing their requirements).
4. staging - variant A (a second project or branch) or variant B (tagged QA
   accounts plus a SECURITY DEFINER cleanup RPC under the user's own JWT, with
   no service role in CI).
5. monitoring - Sentry (release tags via a define from package.json, sourcemaps
   through @sentry/vite-plugin, apikey redaction in beforeSend), plus a
   health-check cron.
6. secrets - .env and .gitignore patterns, gitleaks with an allowlist, a map of
   every secret.
7. smoke-e2e - Playwright, authentication through the Supabase REST API (no UI,
   sub-second setup), 7 scenarios with TODO markers.
8. agent-layer - the invariants, the application scenario and the report
   template.

Idempotency through CREATE OR REPLACE and merge-not-overwrite; verification by
checklist as the gate before a push; honest classification of every result
(verified / unverified / manual / skipped).

**Why you want it.** It removes weeks of DevOps plumbing from the project owner
and eliminates a class of mistakes that has already been made and documented
once. A bonus worth noting: the kit's own self-test found three real bugs
(gitleaks PR permissions, the health endpoint, a vitest/playwright collision) -
that is the product knowledge in it.

---

## The scenario: "I have no project, only an idea"

An honest boundary: **kit v0 is a release layer on top of an app that ALREADY
exists, not a generator of the app.** If you only have an idea, the kit will not
produce an application - there is nothing for it to wrap. But it slots exactly
into the second half of the road. The full route:

### Step 1 - build the MVP (without the kit)

The idea becomes a working minimal product through the usual vibe-coding tools:
Lovable, Bolt, v0, Cursor, Claude Code. The one thing that matters is that the
result is on the right stack: React + Vite + TypeScript with data in Supabase.
For a simple app that is one or two evenings.

An example. The idea: "an app that tracks houseplants and reminds me to water
them". You build: a plant list, add and delete, mark as watered, login. It works
for you under `npm run dev`. That is the MVP.

### Step 2 - apply the kit (this is where it helps)

Now the app exists, but there is no automatic build, no store release, no
monitoring, the secrets are scattered and there are no tests. Open an AI agent
session in the project folder and say "apply the Release Conveyor Kit". The
agent:
- asks what it is called, whether you need Android, which accounts exist, what
  the main entity is (for you, "plant");
- puts the workflows in place, configures Sentry, writes smoke tests for your
  screens, closes the secrets;
- runs the verification and hands back a report plus a list of "create these
  accounts and secrets".

The result: every push of yours is checked and built automatically, the app
ships to the store, and crashes show up in Sentry. From "works on my laptop" to
"lives in production".

### What is needed from you, in plain terms

1. A working MVP on the right stack (or build one - step 1).
2. Accounts: GitHub (free), Supabase (free), and for the stores Google Play ($25
   once) and/or Apple Developer ($99/year); optionally Sentry (free to start)
   and Vercel (free).
3. Start an agent with the kit and answer the interview questions.
4. Do the manual steps from the final report - mostly pasting secrets and
   pressing a couple of buttons in consoles.

### Who it is for

- **The kit's owner (v0):** your own new projects go live in an evening instead
  of weeks. That is the kit's first purpose.
- **A friend or partner who vibe-codes:** they built an MVP and neither know nor
  want to learn how to release it - they hand their own agent the kit and get a
  working conveyor. You never get access to their code; their agent applies it.
- **A future paying client:** "I have an MVP in Lovable, I want it in the App
  Store and I want it not to crash" - that is exactly what the kit is about.

### If you want "from an idea in one click" (out of v0 scope)

Technically, during the kit's self-test a minimal clean skeleton
(Vite + React + TS + Supabase) was already generated, so the kit can produce a
starter. Turning that into a mode where the kit creates both the empty project
and the plumbing is a realistic extension, but it is a separate feature: v0
deliberately leaves it out to keep the scope from blurring.
