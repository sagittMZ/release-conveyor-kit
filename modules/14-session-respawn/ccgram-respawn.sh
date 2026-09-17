#!/usr/bin/env bash
# ccgram-respawn.sh - bring ccgram tmux windows and their claude sessions back
# after a reboot (or a tmux server crash) from a manifest, keeping the Telegram
# topic bindings intact.
#
# Usage:
#   ccgram-respawn.sh [--dry-run] [--only NAME]... [--fresh] [--no-report] [-h]
#
# Modes (chosen automatically):
#   cold  - none of the manifest windows exist: stop ccgram (nothing to lose),
#           create every window in manifest order, rewrite state.json bindings
#           to the new window ids, start ccgram, then launch claude per window.
#   warm  - some manifest windows already exist: ccgram is NOT stopped (it wipes
#           session_map on shutdown); only missing windows are created and only
#           windows without a live claude get one launched.
#
# Safety: never kills a window or a process; one run at a time (flock); refuses
# to launch more claude processes than the manifest lists; --dry-run prints the
# plan and touches nothing.
set -euo pipefail

CCGRAM_DIR="${CCGRAM_DIR:-$HOME/.ccgram}"
MANIFEST="${CCGRAM_RESPAWN_MANIFEST:-$CCGRAM_DIR/respawn-manifest.json}"
LOCK="$CCGRAM_DIR/respawn.lock"
LOG="$CCGRAM_DIR/respawn.log"
ENV_FILE="$CCGRAM_DIR/.env"
STATE="$CCGRAM_DIR/state.json"
SESSION_MAP="$CCGRAM_DIR/session_map.json"
EVENTS="$CCGRAM_DIR/events.jsonl"

DIALOG_WAIT=40      # seconds to wait for the resume dialog / prompt per window
MAP_WAIT=20         # seconds to wait for the session_map entry per window
BETWEEN_WINDOWS=4   # pause between launches (SessionStart hook race)
CCGRAM_SETTLE=12    # seconds for ccgram to finish startup cleanup

DRY=0; FRESH=0; NO_REPORT=0; ONLY=()
usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --fresh) FRESH=1 ;;
        --no-report) NO_REPORT=1 ;;
        --only) shift; ONLY+=("${1:?--only needs a window name}") ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG" >&2; }
die() { log "FATAL: $*"; exit 1; }

expand_home() { printf '%s' "${1/#\~/$HOME}"; }

# ---------------------------------------------------------------- lock ----
exec 9>"$LOCK"
if ! flock -n 9; then
    die "another respawn run holds $LOCK - refusing to run twice"
fi

# ------------------------------------------------------------ manifest ----
[ -r "$MANIFEST" ] || die "manifest not found: $MANIFEST"

mapfile -t MROWS < <(python3 - "$MANIFEST" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
for w in m["windows"]:
    # "|" as separator: tab is IFS whitespace and an empty field would collapse
    print("|".join([
        w["name"], w["cwd"], str(w["thread_id"]), w.get("config_dir", ""),
        w["model"], w.get("resume", "summary"), w.get("group", "default"),
    ]))
PY
)
[ "${#MROWS[@]}" -gt 0 ] || die "manifest has no windows"

read_manifest_key() {
    python3 - "$MANIFEST" "$1" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
v = m
for part in sys.argv[2].split("."):
    v = v.get(part, "") if isinstance(v, dict) else ""
print(v if not isinstance(v, bool) else str(v).lower())
PY
}
SESSION="$(read_manifest_key tmux_session)"; SESSION="${SESSION:-ccgram}"
CLAUDE_BASE="$(read_manifest_key claude_command)"
CLAUDE_BASE="$(expand_home "$CLAUDE_BASE")"
SUMMARY_THREAD="$(read_manifest_key report.summary_thread_id)"
PER_TOPIC="$(read_manifest_key report.per_topic_line)"

declare -a M_NAME M_CWD M_THREAD M_CFG M_MODEL M_RESUME M_GROUP
for row in "${MROWS[@]}"; do
    IFS='|' read -r n c t cfg mo r g <<<"$row"
    M_NAME+=("$n"); M_CWD+=("$(expand_home "$c")"); M_THREAD+=("$t")
    M_CFG+=("$(expand_home "$cfg")"); M_MODEL+=("$mo"); M_RESUME+=("$r"); M_GROUP+=("$g")
done
COUNT=${#M_NAME[@]}

wanted() {  # is window NAME selected by --only (or everything when no --only)
    [ "${#ONLY[@]}" -eq 0 ] && return 0
    local o; for o in "${ONLY[@]}"; do [ "$o" = "$1" ] && return 0; done
    return 1
}
for o in "${ONLY[@]:-}"; do
    [ -z "$o" ] && continue
    found=0; for n in "${M_NAME[@]}"; do [ "$n" = "$o" ] && found=1; done
    [ $found = 1 ] || die "--only $o: not in manifest"
done

# ------------------------------------------------------------ env/creds ----
env_val() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true; }
BOT_TOKEN="$(env_val TELEGRAM_BOT_TOKEN)"
GROUP_ID="$(env_val CCGRAM_GROUP_ID)"
USER_ID="$(env_val ALLOWED_USERS | cut -d, -f1)"
[ -n "$USER_ID" ] || die "ALLOWED_USERS missing in $ENV_FILE"
[ -n "$GROUP_ID" ] || die "CCGRAM_GROUP_ID missing in $ENV_FILE"

# ------------------------------------------------------------- helpers ----
claude_count() { pgrep -fc -- "--settings $CCGRAM_DIR/no-telegram.json" || true; }

tmux_alive() { tmux list-sessions >/dev/null 2>&1; }

# name -> window_id for live windows of $SESSION; and id -> current command
declare -A WIN_ID WIN_CMD
scan_windows() {
    WIN_ID=(); WIN_CMD=()
    tmux_alive || return 0
    tmux has-session -t "$SESSION" 2>/dev/null || return 0
    while IFS=$'\t' read -r id name cmd; do
        WIN_ID["$name"]="$id"; WIN_CMD["$id"]="$cmd"
    done < <(tmux list-windows -t "$SESSION" -F $'#{window_id}\t#{window_name}\t#{pane_current_command}')
}

resolve_sid() {  # $1 config_dir ('' = ~/.claude), $2 cwd -> newest session id or ''
    local cfg="${1:-$HOME/.claude}" slug dir
    slug="$(printf '%s' "$2" | sed 's|/|-|g')"
    dir="$cfg/projects/$slug"
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -name '*.jsonl' -printf '%T@ %f\n' 2>/dev/null | sort -rn \
        | grep -E ' [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jsonl$' \
        | head -1 | sed 's/^[^ ]* //; s/\.jsonl$//' || true
}

send_line() { tmux send-keys -t "$SESSION:$1" C-u; tmux send-keys -t "$SESSION:$1" -l -- "$2"; tmux send-keys -t "$SESSION:$1" Enter; }

# Wait for the resume dialog (answer it) or for the prompt; $1 id, $2 want (summary|full)
handle_startup_dialog() {
    local id="$1" want="$2" i pane hl
    for ((i = 0; i < DIALOG_WAIT; i++)); do
        sleep 1
        pane="$(tmux capture-pane -p -t "$SESSION:$id" 2>/dev/null || true)"
        if grep -q 'Resume from summary' <<<"$pane"; then
            hl="$(grep -E '^[[:space:]]*(❯|>)' <<<"$pane" | head -1 || true)"
            if [ "$want" = full ]; then
                if grep -qi 'summary' <<<"$hl"; then tmux send-keys -t "$SESSION:$id" Down; fi
            else
                if ! grep -qi 'summary' <<<"$hl"; then tmux send-keys -t "$SESSION:$id" Down; fi
            fi
            sleep 0.5; tmux send-keys -t "$SESSION:$id" Enter
            echo "dialog:$want"; return 0
        fi
        if grep -q 'Yes, I accept' <<<"$pane"; then echo "needs-attention:bypass-permissions-consent"; return 0; fi
        if grep -qi 'trust the files' <<<"$pane"; then echo "needs-attention:trust-dialog"; return 0; fi
        if grep -qE 'for shortcuts|for agents' <<<"$pane"; then echo "prompt"; return 0; fi
    done
    printf '%s\n' "--- pane $id after ${DIALOG_WAIT}s ---" "$pane" >>"$LOG"
    echo "timeout"
}

# Wait for session_map entry; repair from events.jsonl if the hook race lost it.
verify_session_map() {  # $1 id, $2 cwd, $3 start-ts -> prints sid or ''
    local id="$1" cwd="$2" since="$3" i out
    for ((i = 0; i < MAP_WAIT; i++)); do
        out="$(python3 - "$SESSION_MAP" "$SESSION:$id" "$cwd" <<'PY'
import json, sys
try:
    m = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
e = m.get(sys.argv[2])
if e and e.get("cwd") == sys.argv[3]:
    print(e.get("session_id", ""))
PY
)"
        [ -n "$out" ] && { echo "$out"; return 0; }
        sleep 1
    done
    # repair from the latest SessionStart for this window newer than $since
    out="$(python3 - "$EVENTS" "$SESSION_MAP" "$CCGRAM_DIR/session_map.lock" "$SESSION:$id" "$cwd" "$since" <<'PY'
import json, sys, fcntl
events, mapf, lockf, key, cwd, since = sys.argv[1:7]
since = float(since); best = None
for line in open(events, errors="ignore"):
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get("event") == "SessionStart" and d.get("window_key") == key and d.get("ts", 0) >= since \
            and d.get("data", {}).get("cwd") == cwd:
        best = d
if not best:
    sys.exit(0)
entry = {"schema_version": 1, "session_id": best["session_id"], "cwd": cwd,
         "window_name": best["data"].get("window_name", ""),
         "transcript_path": best["data"].get("transcript_path", ""),
         "provider_name": best["data"].get("provider_name", "claude")}
with open(lockf, "w") as lf:
    fcntl.flock(lf, fcntl.LOCK_EX)
    try:
        m = json.load(open(mapf))
    except Exception:
        m = {}
    m[key] = entry
    tmp = mapf + ".respawn.tmp"
    json.dump(m, open(tmp, "w"), indent=2)
    import os; os.replace(tmp, mapf)
    fcntl.flock(lf, fcntl.LOCK_UN)
print("repaired:" + best["session_id"])
PY
)"
    echo "$out"
}

rewrite_state() {  # cold mode: bind manifest windows to their fresh ids
    local mapping="$1"   # JSON array of {name,id,thread_id,cwd,fresh}
    python3 - "$STATE" "$USER_ID" "$GROUP_ID" "$mapping" "$DRY" <<'PY'
import json, sys, shutil, time
state_path, user_id, group_id, mapping, dry = sys.argv[1:6]
mapping = json.loads(mapping); dry = dry == "1"
try:
    s = json.load(open(state_path))
except Exception:
    s = {}
old_names = s.get("window_display_names", {})
old_by_name = {v: k for k, v in old_names.items()}
new_bind, new_names, new_ws, new_off = {}, {}, {}, {}
ws = s.get("window_states", {})
offs = s.get("user_window_offsets", {}).get(user_id, {})
chat = s.setdefault("group_chat_ids", {})
for w in mapping:
    new_bind[str(w["thread_id"])] = w["id"]
    new_names[w["id"]] = w["name"]
    chat[f"{user_id}:{w['thread_id']}"] = int(group_id)
    old = old_by_name.get(w["name"])
    if old and not w["fresh"]:
        if old in ws:
            new_ws[w["id"]] = dict(ws[old]); new_ws[w["id"]]["window_name"] = w["name"]
            new_ws[w["id"]].pop("panes", None)
        if old in offs:
            new_off[w["id"]] = offs[old]
# ccgram 4.9+ keys bindings by "user:chat:thread" in chat_thread_bindings and
# lets a chat-scoped row win over the legacy thread_bindings row, so a stale
# chat-scoped id would silently survive a legacy-only rewrite. Rewrite whichever
# schema the file already uses.
if "chat_thread_bindings" in s:
    prefix = f"{user_id}:{group_id}:"
    old_chat = s.get("chat_thread_bindings", {})
    dropped = sorted(k[len(prefix):] for k in old_chat if k.startswith(prefix)
                     and k[len(prefix):] not in new_bind)
    kept = {k: v for k, v in old_chat.items() if not k.startswith(prefix)}
    kept.update({prefix + tid: wid for tid, wid in new_bind.items()})
    s["chat_thread_bindings"] = kept
    s.get("thread_bindings", {}).pop(user_id, None)
else:
    dropped = sorted(set(s.get("thread_bindings", {}).get(user_id, {})) - set(new_bind))
    s.setdefault("thread_bindings", {})[user_id] = new_bind
s["window_display_names"] = new_names
s["window_states"] = new_ws
s.setdefault("user_window_offsets", {})[user_id] = new_off
print(f"bindings: {json.dumps(new_bind)}; dropped threads: {dropped}; window_states kept: {len(new_ws)}")
if dry:
    sys.exit(0)
bak = f"{state_path}.bak-respawn-{time.strftime('%Y%m%d-%H%M%S')}"
try:
    shutil.copy2(state_path, bak); print("backup:", bak)
except FileNotFoundError:
    pass
tmp = state_path + ".respawn.tmp"
json.dump(s, open(tmp, "w"), indent=2)
import os; os.replace(tmp, state_path)
PY
}

tg_send() {  # $1 thread_id, $2 text
    [ "$NO_REPORT" = 1 ] && return 0
    [ -n "$BOT_TOKEN" ] || { log "no TELEGRAM_BOT_TOKEN - report skipped"; return 0; }
    curl -s -m 15 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=$GROUP_ID" --data-urlencode "message_thread_id=$1" \
        --data-urlencode "text=$2" >/dev/null 2>&1 || log "telegram send failed (thread $1)"
}

# --------------------------------------------------------------- plan -----
log "=== respawn start (dry=$DRY fresh=$FRESH only=${ONLY[*]:-all}) manifest=$MANIFEST"
tmux_alive || {
    log "tmux server not running - starting tmux-keeper"
    [ "$DRY" = 1 ] || systemctl --user start tmux-keeper
    sleep 2
}
scan_windows
OWN_ID=""
[ -n "${TMUX_PANE:-}" ] && OWN_ID="$(tmux display -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null || true)"

existing=0
for n in "${M_NAME[@]}"; do [ -n "${WIN_ID[$n]:-}" ] && existing=$((existing + 1)); done
if [ "$existing" -eq 0 ]; then MODE=cold; else MODE=warm; fi
BEFORE="$(claude_count)"
log "mode=$MODE existing_windows=$existing/$COUNT claude_procs=$BEFORE own_window=${OWN_ID:-none}"

if [ "$BEFORE" -ge "$COUNT" ] && [ "$existing" -eq "$COUNT" ]; then
    all_live=1
    for n in "${M_NAME[@]}"; do [ "${WIN_CMD[${WIN_ID[$n]}]:-}" = claude ] || all_live=0; done
    if [ "$all_live" = 1 ]; then log "all $COUNT windows alive with claude - nothing to do"; exit 0; fi
fi

# ------------------------------------------------------- cold: rebuild ----
if [ "$MODE" = cold ]; then
    if systemctl --user is-active --quiet ccgram; then
        log "stopping ccgram (no manifest windows exist, nothing to lose)"
        [ "$DRY" = 1 ] || systemctl --user stop ccgram
    fi
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        log "creating tmux session $SESSION with __main__"
        [ "$DRY" = 1 ] || tmux new-session -d -s "$SESSION" -n __main__ -c "$HOME"
    fi
    mapping="["
    for ((i = 0; i < COUNT; i++)); do
        n="${M_NAME[$i]}"; c="${M_CWD[$i]}"
        [ -d "$c" ] || log "WARN: cwd missing for $n: $c (window still created)"
        if [ "$DRY" = 1 ]; then id="@dry$i"; else
            id="$(tmux new-window -d -P -F '#{window_id}' -t "$SESSION:" -n "$n" -c "${c:-$HOME}")"
        fi
        WIN_ID["$n"]="$id"; WIN_CMD["$id"]="bash"
        log "window $n -> $id"
        fresh=false; { [ "$FRESH" = 1 ] || [ "${M_RESUME[$i]}" = fresh ]; } && fresh=true
        mapping+="{\"name\":\"$n\",\"id\":\"$id\",\"thread_id\":${M_THREAD[$i]},\"cwd\":\"$c\",\"fresh\":$fresh},"
    done
    mapping="${mapping%,}]"
    log "state.json: $(rewrite_state "$mapping")"
    log "starting ccgram, settling ${CCGRAM_SETTLE}s"
    if [ "$DRY" = 0 ]; then
        systemctl --user start ccgram
        sleep "$CCGRAM_SETTLE"
        systemctl --user is-active --quiet ccgram || die "ccgram failed to start"
    fi
else
    # warm: create only missing windows; ccgram rebinds topics by window name
    for ((i = 0; i < COUNT; i++)); do
        n="${M_NAME[$i]}"
        [ -n "${WIN_ID[$n]:-}" ] && continue
        wanted "$n" || continue
        c="${M_CWD[$i]}"
        if [ "$DRY" = 1 ]; then id="@dry$i"; else
            id="$(tmux new-window -d -P -F '#{window_id}' -t "$SESSION:" -n "$n" -c "${c:-$HOME}")"
        fi
        WIN_ID["$n"]="$id"; WIN_CMD["$id"]="bash"
        log "window $n -> $id (warm; topic rebinds by name)"
    done
fi

# ------------------------------------------------------ launch claude -----
declare -a R_LINE
launched=0; failed=0
for ((i = 0; i < COUNT; i++)); do
    n="${M_NAME[$i]}"; id="${WIN_ID[$n]:-}"
    wanted "$n" || { R_LINE+=("skip  $n: not selected"); continue; }
    [ -n "$id" ] || { R_LINE+=("skip  $n: no window"); continue; }
    if [ "${WIN_CMD[$id]:-}" = claude ]; then
        [ "$id" = "$OWN_ID" ] && R_LINE+=("keep  $n ($id): own window") || R_LINE+=("keep  $n ($id): claude alive")
        continue
    fi
    # loop guard: never more launches than manifest entries, and no claude
    # processes appearing that this run did not start (something else spawning)
    cur="$(claude_count)"
    if [ "$launched" -ge "$COUNT" ] || [ "$cur" -gt $((BEFORE + launched)) ]; then
        R_LINE+=("STOP  $n: loop guard (launched=$launched/$COUNT, claude_procs=$cur, expected<=$((BEFORE + launched)))")
        failed=$((failed + 1)); break
    fi
    resume="${M_RESUME[$i]}"; [ "$FRESH" = 1 ] && resume=fresh
    sid=""; [ "$resume" != fresh ] && sid="$(resolve_sid "${M_CFG[$i]}" "${M_CWD[$i]}")"
    [ -z "$sid" ] && resume=fresh
    cmd="$CLAUDE_BASE --model ${M_MODEL[$i]}"
    [ -n "$sid" ] && cmd="$cmd --resume $sid"
    [ -n "${M_CFG[$i]}" ] && cmd="CLAUDE_CONFIG_DIR=${M_CFG[$i]} $cmd"
    if [ "$DRY" = 1 ]; then
        R_LINE+=("plan  $n ($id): $cmd  [resume=$resume]")
        continue
    fi
    start_ts="$(date +%s)"
    log "launch $n ($id): $cmd"
    send_line "$id" "$cmd"
    launched=$((launched + 1))
    d="$(handle_startup_dialog "$id" "$resume")"
    map="$(verify_session_map "$id" "${M_CWD[$i]}" "$start_ts")"
    if [ -n "$map" ]; then
        R_LINE+=("ok    $n ($id): model=${M_MODEL[$i]} resume=$resume sid=${sid:0:8} dialog=$d map=${map:0:17}")
    else
        R_LINE+=("FAIL  $n ($id): model=${M_MODEL[$i]} resume=$resume sid=${sid:0:8} dialog=$d map=missing")
        failed=$((failed + 1))
    fi
    [ "$PER_TOPIC" = true ] && tg_send "${M_THREAD[$i]}" "respawn: $n restored (model=${M_MODEL[$i]}, resume=$resume, sid=${sid:0:8}, ${map:+session_map ok}${map:-session_map MISSING})"
    sleep "$BETWEEN_WINDOWS"
done

# ----------------------------------------------------- diversity check ----
scan_windows
diversity="$(python3 - "$MANIFEST" "$(for n in "${!WIN_ID[@]}"; do [ "${WIN_CMD[${WIN_ID[$n]}]:-}" = claude ] && printf '%s\n' "$n"; done)" <<'PY'
import json, sys
m = json.load(open(sys.argv[1])); live = set(sys.argv[2].split())
groups = {}
for w in m["windows"]:
    if w["name"] in live:
        groups.setdefault(w.get("group", "default"), set()).add(w["model"])
out = []
for g, models in sorted(groups.items()):
    out.append(f"{g}: {'/'.join(sorted(models))} {'ok' if len(models) > 1 else 'ONE MODEL ONLY'}")
print("; ".join(out) or "no live windows")
PY
)"
# A window that already existed carries ccgram's in-memory "dead" flag from the
# SessionEnd of the claude we replaced; relaunching in the same pane does not
# clear it, so Telegram answers that topic with the recovery UI instead of
# reaching the live session. Cold mode starts ccgram fresh, so only warm needs it.
# ponytail: blunt - ~10s of bridge downtime for all topics. Narrow it only if
# ccgram ever exposes a per-window "unmark dead" command.
if [ "$MODE" = warm ] && [ "$launched" -gt 0 ] && [ "$DRY" = 0 ]; then
    log "warm relaunch: restarting ccgram to clear dead-window flags"
    systemctl --user restart ccgram && sleep 8
    systemctl --user is-active --quiet ccgram || { log "WARN: ccgram failed to restart"; failed=$((failed + 1)); }
fi

AFTER="$(claude_count)"
if [ "$AFTER" -gt $((BEFORE + launched)) ]; then
    log "WARN: $AFTER claude processes, expected at most $((BEFORE + launched))"; failed=$((failed + 1))
fi

# --------------------------------------------------------------- report ----
status="OK"; [ "$failed" -gt 0 ] && status="PROBLEMS: $failed"
summary="ccgram respawn $status ($MODE, $(ts))
launched=$launched claude_procs=$BEFORE->$AFTER
models: $diversity
$(printf '%s\n' "${R_LINE[@]}")"
log "$summary"
if [ "$DRY" = 1 ]; then
    log "dry-run: no report sent, nothing changed"
else
    [ -n "$SUMMARY_THREAD" ] && tg_send "$SUMMARY_THREAD" "$summary"
fi
[ "$failed" -eq 0 ]
