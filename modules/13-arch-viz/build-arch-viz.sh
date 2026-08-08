#!/bin/bash
# build-arch-viz.sh - module 13, the deterministic build of the visualization.
# It validates arch-data.json (the schema invariants) and inlines it into
# template.html -> one self-contained HTML file. No LLM involved: the data is
# updated by /arch-viz inside a session, and the build is free and reproducible,
# both locally and in CI.
#
# Usage:
#   build-arch-viz.sh [--data <path>] [--out <path>]
# Defaults: data docs/arch/arch-data.json, output docs/arch/index.html (paths
# relative to the git repository root; works both in the kit and in a vendored
# tools/prompt-kit/arch-viz/ layout).
#
# Requires: python3 (stdlib). Exit 1 means broken data, with the problems
# listed.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DATA="$PROJECT_ROOT/docs/arch/arch-data.json"
OUT="$PROJECT_ROOT/docs/arch/index.html"
TEMPLATE="$HERE/template.html"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --data) DATA="${2:?}"; shift 2 ;;
    --out)  OUT="${2:?}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -f "$DATA" ] || { echo "no data: $DATA (generate it with /arch-viz)" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "no template: $TEMPLATE" >&2; exit 1; }

DATA="$DATA" OUT="$OUT" TEMPLATE="$TEMPLATE" python3 - <<'PY'
import json, os, sys

data_path, out_path, tpl_path = os.environ['DATA'], os.environ['OUT'], os.environ['TEMPLATE']
try:
    d = json.load(open(data_path, encoding='utf-8'))
except json.JSONDecodeError as e:
    sys.exit(f"broken JSON: {e}")

errs = []
def need(cond, msg):
    if not cond: errs.append(msg)

for key in ('meta', 'groups', 'nodes', 'edges', 'flows'):
    need(key in d, f"missing section '{key}'")
if errs: sys.exit("schema:\n  " + "\n  ".join(errs))

gids = [g.get('id') for g in d['groups']]
nids = [n.get('id') for n in d['nodes']]
need(len(gids) == len(set(gids)), "group ids are not unique")
need(len(nids) == len(set(nids)), "node ids are not unique")
nset, gset = set(nids), set(gids)

for n in d['nodes']:
    need(n.get('label'), f"node {n.get('id')}: no label")
    need(n.get('group') in gset, f"node {n.get('id')}: group '{n.get('group')}' is not declared in groups")
for i, e in enumerate(d['edges']):
    need(e.get('from') in nset, f"edge #{i}: from '{e.get('from')}' does not exist")
    need(e.get('to') in nset, f"edge #{i}: to '{e.get('to')}' does not exist")
for f in d['flows']:
    steps = f.get('steps') or []
    need(len(steps) >= 2, f"flow {f.get('id')}: fewer than 2 steps")
    for s in steps:
        need(s.get('node') in nset, f"flow {f.get('id')}: a step references a node that does not exist, '{s.get('node')}'")

if errs:
    sys.exit("data invariants violated:\n  " + "\n  ".join(errs))

tpl = open(tpl_path, encoding='utf-8').read()
marker = '__ARCH_DATA__'
if marker not in tpl:
    sys.exit("the template has no __ARCH_DATA__ placeholder")
# a </script> inside a data string would break the inline script - escape it.
payload = json.dumps(d, ensure_ascii=False).replace('</', '<\\/')
html = tpl.replace(marker, payload)

os.makedirs(os.path.dirname(out_path), exist_ok=True)
open(out_path, 'w', encoding='utf-8').write(html)
print(f"ok: {out_path} ({len(d['nodes'])} nodes, {len(d['edges'])} edges, {len(d['flows'])} flows)")
PY
