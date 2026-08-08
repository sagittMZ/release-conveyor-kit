# Module 13 - arch-viz

An interactive architecture visualization of a project: one self-contained HTML
file (SVG + vanilla JS, dark theme, no external dependencies and no CDN). A
person understands the structure of the system in ten seconds and can jump to
any component through the sidebar.

Stack-independent (like 09/11/12): it works for any repository.

## The hybrid mechanism

Semantic analysis of code is LLM work: free inside a session, paid in CI. So:

1. **The data** (`docs/arch/arch-data.json`) is updated by the `/arch-viz` slash
   command inside a session: a deep read of the repo -> nodes/edges/flows.
2. **The build** is deterministic and free: `build-arch-viz.sh` inlines the JSON
   into `template.html` -> a self-contained `docs/arch/index.html`. The command
   runs it right after updating the data, and CI runs it too.
3. **CI** (`templates/arch-viz.yml`): on a push to main it rebuilds the HTML
   from the JSON (auto-committing only when the HTML lags behind the JSON -
   usually a no-op) and checks FRESHNESS: if the project's sources changed later
   than arch-data.json, it writes "the visualization is stale, run /arch-viz"
   into the run summary. Manual runs go through workflow_dispatch. In projects
   with a develop branch: automatic on main, dispatch on develop.

## Data schema (arch-data.json)

```json
{
  "meta":  { "project": "...", "updated": "YYYY-MM-DD", "commit": "sha7" },
  "groups": [ { "id": "layer-id", "label": "Layer or category", "color": "#8fbfa3" } ],
  "nodes": [ { "id": "node-id", "label": "Name", "group": "layer-id",
               "desc": "1-3 sentences on what it is responsible for",
               "files": ["path/one", "path/two"], "tech": ["bash", "SVG"] } ],
  "edges": [ { "from": "node-id", "to": "node-id", "label": "what flows",
               "kind": "data|control|build" } ],
  "flows": [ { "id": "flow-id", "name": "Flow name", "desc": "why it matters",
               "steps": [ { "node": "node-id", "text": "what happens" } ] } ]
}
```

Invariants (the builder checks them; broken data means exit 1): ids are unique;
every node's group exists in groups; every edge's from/to and every flow step's
node exist in nodes.

## Contents

| File | What it is |
|---|---|
| template.html | The UI template: a sidebar with search and collapsing, the SVG graph (pan/zoom/drag, positions kept in localStorage), tooltips, component cards, a flows panel with path highlighting and numbered steps, a legend, a dark theme, responsive layout. Placeholder: `__ARCH_DATA__` |
| build-arch-viz.sh | The deterministic build: invariant validation + inlining the JSON into the template -> docs/arch/index.html (python3 stdlib, no node) |
| freshness-hook.sh | The UserPromptSubmit hook that keeps the data fresh automatically |
| templates/arch-viz.yml | GitHub Actions: rebuild on push to main + staleness report + workflow_dispatch |
| checklist.md | Verification (structural plus a browser smoke test) |

The `/arch-viz` command lives in `modules/09-prompt-library/commands/arch-viz.md`
- commands have one home.

## Refresh triggers (the full loop, from strongest to backstop)

1. **freshness-hook.sh (primary, fully automatic):** a UserPromptSubmit hook in
   the project's .claude/settings.json. On every prompt (two fast git log calls)
   it compares freshness; if the data is stale it gives the session the task of
   running /arch-viz in the current turn. The owner does nothing. It nudges at
   most once a day (the marker lives in the project's private zone).
2. **/session-wrap** offers /arch-viz when the session changed the structure.
3. **The CI backstop:** the workflow on every push to main - a staleness report
   in the summary plus a Telegram ping to the project's topic (TELEGRAM_*
   secrets, one ping per episode, delivery confirmed by the API response; test
   it with a dispatch and test_notify=true).
4. **Manual:** /arch-viz.

## Languages

The canonical version is ENGLISH: docs/arch/arch-data.json (meta.lang: en) and
docs/arch/index.html are part of the public repository. The template's UI is
bilingual: it carries an EN/RU dictionary inside, switched by the data's
meta.lang field. A translated version is the owner's personal layer -
arch-data.<lang>.json + index.<lang>.html, git-ignored and regenerated on demand
(`build-arch-viz.sh --data docs/arch/arch-data.ru.json --out docs/arch/index.ru.html`).

## Publishability

The data contains only what exists in the repository itself. No private machine
paths, no names of other projects, no personal data. The rule is baked into the
command.

## Field test

The kit itself is the proving ground: the kit's own data lives in
docs/arch/index.html, verified in a browser against the checklist, and the
module is part of what a rollout installs into a project.
