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
#   lt_find_files <days>        -> *.jsonl modified within N days (one per line)
#   lt_cmd_counts   <files...>  -> "<count> <command>" for slash commands, descending
#   lt_skill_counts <files...>  -> "<count> <skill>" for skills (Skill tool)
#   lt_agent_counts <files...>  -> "<count> <subagent_type>" for subagents
#   lt_typed_prompts <files...> -> prompts the user typed themselves (string
#                                  content), one per line, without wrapper lines
#
# Environment:
#   CLAUDE_PROJECTS_DIR  where the transcripts live. Several directories are
#                        separated by ":" - one per Claude Code config dir.
#   LT_DAYS              when set, the counters skip records older than N days
#                        (a long session's file holds more than the window).
#
# Names keep their namespace: a command installed in a subdirectory or shipped
# by a plugin is counted as "group:name", not folded into "group".

LT_PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

# Symbolic links are followed (a projects directory may link to another config
# dir's projects); a file reached twice is listed once, by its real path.
lt_find_files() {
  local days="${1:-7}" dirs=()
  IFS=: read -r -a dirs <<< "$LT_PROJECTS_DIR"
  [ "${#dirs[@]}" -eq 0 ] && return 0
  find -L "${dirs[@]}" -name '*.jsonl' -mtime "-${days}" 2>/dev/null \
    | while IFS= read -r f; do realpath "$f" 2>/dev/null || printf '%s\n' "$f"; done \
    | sort -u
}

# The counters read records, not raw text: a command is a user message, a skill
# or a subagent is a tool call of the assistant. So a name quoted in a tool
# result or in a pasted log is not an invocation, and a record copied into a
# resumed session's file is counted once. Without python3 they fall back to
# counting text matches, which is the looser of the two.
_lt_counts() {  # _lt_counts cmd|skill|agent <files...>
  local kind="$1"; shift
  [ "$#" -eq 0 ] && return 0
  if ! command -v python3 >/dev/null 2>&1; then
    local rx
    case "$kind" in
      cmd)   rx='<command-name>/[A-Za-z0-9:_-]*' ;;
      skill) rx='"skill":"[A-Za-z0-9:_-]*"' ;;
      *)     rx='"subagent_type":"[A-Za-z0-9:_-]*"' ;;
    esac
    grep -oh "$rx" "$@" 2>/dev/null \
      | sed 's#<command-name>/##;s#"[a-z_]*":"##;s#"##' | grep -v '^$' \
      | sort | uniq -c | sort -rn || true
    return 0
  fi
  python3 - "$kind" "${LT_DAYS:-}" "$@" <<'PY'
import collections, datetime, json, re, sys
kind, days, files = sys.argv[1], sys.argv[2], sys.argv[3:]
cut = None
if days.isdigit():
    cut = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=int(days))
needle = {"cmd": "<command-name>/", "skill": '"Skill"'}.get(kind, '"tool_use"')
cmd_rx = re.compile(r"<command-name>/([^<\s]+)</command-name>")
counts, seen = collections.Counter(), set()

def fresh(o):
    if cut is None:
        return True
    try:
        return datetime.datetime.fromisoformat(o["timestamp"].replace("Z", "+00:00")) >= cut
    except Exception:
        return True   # no usable time on the record: the file's mtime already let it in

for fp in files:
    try:
        f = open(fp, encoding="utf-8", errors="replace")
    except OSError:
        continue
    with f:
        for line in f:
            if needle not in line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            m = o.get("message")
            if not isinstance(m, dict) or not fresh(o):
                continue
            c = m.get("content")
            if kind == "cmd":
                if o.get("type") != "user":
                    continue
                if isinstance(c, list):
                    c = "\n".join(b.get("text", "") for b in c
                                  if isinstance(b, dict) and b.get("type") == "text")
                if not isinstance(c, str):
                    continue
                key = o.get("uuid")
                if key and key in seen:
                    continue
                seen.add(key)
                counts.update(cmd_rx.findall(c))
                continue
            if o.get("type") != "assistant" or not isinstance(c, list):
                continue
            for b in c:
                if not isinstance(b, dict) or b.get("type") != "tool_use":
                    continue
                if b.get("id") in seen:
                    continue
                inp = b.get("input") if isinstance(b.get("input"), dict) else {}
                if kind == "skill" and b.get("name") == "Skill":
                    name = inp.get("skill")
                elif kind == "agent" and b.get("name") in ("Task", "Agent"):
                    name = inp.get("subagent_type") or "(default)"
                else:
                    continue
                if isinstance(name, str) and name.strip():
                    seen.add(b.get("id"))
                    counts[name.strip().split()[0]] += 1

for name, n in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])):
    print(n, name)
PY
}

lt_cmd_counts() { _lt_counts cmd "$@"; }
lt_skill_counts() { _lt_counts skill "$@"; }
lt_agent_counts() { _lt_counts agent "$@"; }

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
