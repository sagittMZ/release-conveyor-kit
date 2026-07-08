#!/bin/bash
# lib-transcripts.sh - переиспользуемое чтение транскриптов Claude Code
# (~/.claude/projects/*.jsonl). Единый источник для usage-digest (модуль 09),
# command-evals (модуль 11) и memory-consolidation (модуль 12) - чтобы логика
# чтения истории не дублировалась в трёх местах.
#
# Секретов не содержит. Это sourced-библиотека: определяет функции и НЕ печатает
# ничего при подключении, не выставляет set -e. Подключение:
#   source "<путь>/lib-transcripts.sh"
#
# Функции:
#   lt_projects_dir             -> каталог проектов (env CLAUDE_PROJECTS_DIR)
#   lt_find_files <days>        -> *.jsonl, изменённые за N дней (строка на файл)
#   lt_cmd_counts   <files...>  -> "<count> <command>" слэш-команд, убыв.
#   lt_skill_counts <files...>  -> "<count> <skill>" скиллов (Skill tool)
#   lt_agent_counts <files...>  -> "<count> <subagent_type>" субагентов (Task)
#   lt_typed_prompts <files...> -> user-печатанные промпты (строковый content),
#                                  по строке, без служебных враппер-строк

LT_PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

lt_projects_dir() { printf '%s\n' "$LT_PROJECTS_DIR"; }

lt_find_files() {
  local days="${1:-7}"
  find "$LT_PROJECTS_DIR" -name '*.jsonl' -mtime "-${days}" 2>/dev/null
}

lt_cmd_counts() {
  [ "$#" -eq 0 ] && return 0
  grep -oh '<command-name>/[a-z0-9-]*' "$@" 2>/dev/null \
    | sed 's#<command-name>/##' | sort | uniq -c | sort -rn || true
}

lt_skill_counts() {
  [ "$#" -eq 0 ] && return 0
  grep -oh '"skill":"[a-z0-9-]*"' "$@" 2>/dev/null \
    | sed 's#"skill":"##;s#"##' | sort | uniq -c | sort -rn || true
}

lt_agent_counts() {
  [ "$#" -eq 0 ] && return 0
  grep -oh '"subagent_type":"[a-z0-9_-]*"' "$@" 2>/dev/null \
    | sed 's#"subagent_type":"##;s#"##' | sort | uniq -c | sort -rn || true
}

# Извлечь то, что пользователь печатал сам (строковый content user-сообщений),
# отсекая tool-результаты, стдаут команд и служебные врапперы. Требует python3;
# без него молча возвращает пусто (модуль 12 деградирует, digest не зависит).
lt_typed_prompts() {
  [ "$#" -eq 0 ] && return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$@" <<'PY'
import json, sys
skip=("<command-name","<command-message","<command-args","<local-command",
      "<bash-","Caveat:")
for fp in sys.argv[1:]:
    try:
        with open(fp, encoding="utf-8") as f:
            for line in f:
                if '"type":"user"' not in line:
                    continue
                try:
                    o=json.loads(line)
                except Exception:
                    continue
                if o.get("type")!="user":
                    continue
                c=o.get("message",{}).get("content")
                if isinstance(c,str):
                    t=c.strip()
                    if t and not t.startswith(skip):
                        print(t.replace("\n"," "))
    except Exception:
        pass
PY
}
