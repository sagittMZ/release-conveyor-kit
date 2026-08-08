# Verification checklist: 13-arch-viz

Structural (by the agent, on every build):

1. `build-arch-viz.sh` on valid data prints `ok: ... (N nodes, M edges, K
   flows)`, the HTML is created, and the `__ARCH_DATA__` placeholder is
   replaced.
2. Broken data (a group or node that does not exist, referenced from an edge or
   a flow step; a duplicate id; a flow shorter than 2 steps) exits 1 with the
   problems listed.
3. The HTML is self-contained: no external URLs in src/href (other than `#`
   anchors), and the single file opens both from disk and over http.
4. `eval.sh --all` is green: the arch-viz command has its row in
   expectations.tsv.

Browser smoke test (once per meaningful change to the template):

5. Clicking a node highlights its incoming and outgoing edges, dims the rest,
   and fills the card on the right (description, group, technologies, files,
   clickable relations).
6. Clicking a menu item centers the view on that node and marks the item active.
7. A flow: a yellow path, with the step numbering on the diagram matching the
   "Steps" list in the panel.
8. Search: live filtering of the contents with the match highlighted.
9. Hover tooltip: description plus key files.
10. Pan, zoom and drag work; Fit to screen / Reset zoom / Reset layout are
    present; node positions survive a reload (localStorage).
11. The browser console is free of errors.
