#!/bin/bash
# build-arch-viz.sh - модуль 13, детерминированная сборка визуализации.
# Валидирует arch-data.json (инварианты схемы) и инлайнит его в template.html
# -> один самодостаточный HTML. Никакого LLM: данные обновляет /arch-viz
# в сессии, сборка бесплатна и воспроизводима (и локально, и в CI).
#
# Использование:
#   build-arch-viz.sh [--data <path>] [--out <path>]
# Умолчания: данные docs/arch/arch-data.json, выход docs/arch/index.html
# (пути от корня git-репозитория; работает и в ките, и в вендоренной
# раскладке tools/prompt-kit/arch-viz/).
#
# Требует: python3 (stdlib). Выход 1 - битые данные, с перечнем проблем.

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
    *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
  esac
done

[ -f "$DATA" ] || { echo "нет данных: $DATA (сгенерируй командой /arch-viz)" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "нет шаблона: $TEMPLATE" >&2; exit 1; }

DATA="$DATA" OUT="$OUT" TEMPLATE="$TEMPLATE" python3 - <<'PY'
import json, os, sys

data_path, out_path, tpl_path = os.environ['DATA'], os.environ['OUT'], os.environ['TEMPLATE']
try:
    d = json.load(open(data_path, encoding='utf-8'))
except json.JSONDecodeError as e:
    sys.exit(f"битый JSON: {e}")

errs = []
def need(cond, msg):
    if not cond: errs.append(msg)

for key in ('meta', 'groups', 'nodes', 'edges', 'flows'):
    need(key in d, f"нет секции '{key}'")
if errs: sys.exit("схема:\n  " + "\n  ".join(errs))

gids = [g.get('id') for g in d['groups']]
nids = [n.get('id') for n in d['nodes']]
need(len(gids) == len(set(gids)), "id групп не уникальны")
need(len(nids) == len(set(nids)), "id нод не уникальны")
nset, gset = set(nids), set(gids)

for n in d['nodes']:
    need(n.get('label'), f"нода {n.get('id')}: нет label")
    need(n.get('group') in gset, f"нода {n.get('id')}: группа '{n.get('group')}' не объявлена в groups")
for i, e in enumerate(d['edges']):
    need(e.get('from') in nset, f"ребро #{i}: from '{e.get('from')}' не существует")
    need(e.get('to') in nset, f"ребро #{i}: to '{e.get('to')}' не существует")
for f in d['flows']:
    steps = f.get('steps') or []
    need(len(steps) >= 2, f"flow {f.get('id')}: меньше 2 шагов")
    for s in steps:
        need(s.get('node') in nset, f"flow {f.get('id')}: шаг ссылается на несуществующую ноду '{s.get('node')}'")

if errs:
    sys.exit("инварианты данных нарушены:\n  " + "\n  ".join(errs))

tpl = open(tpl_path, encoding='utf-8').read()
marker = '__ARCH_DATA__'
if marker not in tpl:
    sys.exit("в шаблоне нет плейсхолдера __ARCH_DATA__")
# </script> внутри строк данных разорвал бы inline-скрипт - экранируем.
payload = json.dumps(d, ensure_ascii=False).replace('</', '<\\/')
html = tpl.replace(marker, payload)

os.makedirs(os.path.dirname(out_path), exist_ok=True)
open(out_path, 'w', encoding='utf-8').write(html)
print(f"ok: {out_path} ({len(d['nodes'])} нод, {len(d['edges'])} рёбер, {len(d['flows'])} потоков)")
PY
