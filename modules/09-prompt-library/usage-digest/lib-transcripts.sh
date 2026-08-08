#!/bin/bash
# lib-transcripts.sh - reusable reading of Claude Code transcripts
# (~/.claude/projects/*.jsonl). One source for usage-digest (module 09),
# command-evals (module 11) and memory-consolidation (module 12), so the
# history-reading logic is not duplicated in three places.
#
# Contains no secrets. This is a sourced library: it defines functions, prints
# nothing when sourced, and does not set -e. Source it with:
#   source "<path>/lib-transcripts.sh"
#
# Functions:
#   lt_projects_dir             -> the projects directory (env CLAUDE_PROJECTS_DIR)
#   lt_find_files <days>        -> *.jsonl modified within N days (one per line)
#   lt_cmd_counts   <files...>  -> "<count> <command>" for slash commands, descending
#   lt_skill_counts <files...>  -> "<count> <skill>" for skills (Skill tool)
#   lt_agent_counts <files...>  -> "<count> <subagent_type>" for subagents (Task)
#   lt_typed_prompts <files...> -> prompts the user typed themselves (string
#                                  content), one per line, without wrapper lines

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

# Extract what the user typed themselves (the string content of user messages),
# dropping tool results, command stdout and wrapper lines. Requires python3;
# without it this returns empty silently (module 12 degrades, the digest does
# not depend on it).
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
