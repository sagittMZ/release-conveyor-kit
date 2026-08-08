---
description: Refresh the interactive architecture visualization (data + HTML)
---
Analyze this repository's code and structure in depth and bring the
architecture visualization up to date (module 13 of the kit).

1. DATA (canonical language is ENGLISH - this is a public portfolio artifact):
   update docs/arch/arch-data.json per the schema in the module README (in the
   kit modules/13-arch-viz/README.md, in a vendored project
   tools/prompt-kit/arch-viz/README.md): meta (project, updated, commit),
   groups (layers with colors), nodes (id, label, group, desc, files, tech),
   edges (from, to, label, kind), flows (key flows with steps across nodes).
   If the file already exists, update it incrementally: keep the ids that
   stuck (saved positions are bound to them), add what is new, drop what is
   gone, fix the descriptions. Keep the graph readable: 20-60 nodes, a
   component is a module or a coherent unit, not every file.

2. PRIVACY: only what exists in the repository itself goes into the data. No
   absolute machine paths, no names of other projects, no personal data.

3. BUILD: run build-arch-viz.sh (in the kit modules/13-arch-viz/, in a vendored
   project tools/prompt-kit/arch-viz/) - it validates the invariants and builds
   a self-contained docs/arch/index.html. Fix invariant errors in the data and
   rebuild.

4. TRANSLATED VERSION (optional, if asked for or if
   docs/arch/arch-data.<lang>.json already exists): update it by translating
   the canonical data (meta.lang) and build with
   --data docs/arch/arch-data.<lang>.json --out docs/arch/index.<lang>.html.
   Those files are git-ignored - do not commit them.

5. REPORT: show a summary - how many nodes/edges/flows, what was added or
   removed relative to the previous version of the data, and the path to the
   built HTML.
