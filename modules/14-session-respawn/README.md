# Module 14 - session-respawn

Bring a fleet of agent sessions back after a reboot, with their chat bindings
intact, from one manifest. Built for the setup where every project runs as a
`claude` process in its own tmux window and a Telegram bridge
([ccgram](https://github.com/alexei-led/ccgram)) maps one forum topic to one
window. After a reboot the bridge and the tmux server come back on their own;
the windows and the sessions in them do not, and re-creating eight of them by
hand in the right order is a ten-minute ritual with three known traps.

Stack-independent and machine-level: it is about the workstation that hosts the
sessions, not about any one repository. One manifest per machine lists every
window, whichever project it belongs to.

## Origin

Added by the kit - no donor. Distilled from a manual recovery procedure that
was run several times on the owner's machine (the traps below are all things
that actually happened). **Proven in part.** What has run for real: the warm
path, and one cold start from the unit after a power loss, which brought every
window, binding and session back. What has not: a cold start that ends with
every window live and nobody at the keyboard (checks 6 and 7 of the
checklist). This section changes to "verified" when one passes. The history,
in order.
First real reboot with the unit enabled (2026-09-17) did not pass: the unit
had `Requires=ccgram.service`, so when the script stopped the bridge in cold
mode systemd stopped the script with it, and the bridge stayed down. Fixed
(`Wants=`), together with the bindings schema of ccgram 4.9+ (trap 7). The
fleet was brought back by hand that day with the warm path of the script.
First real cold run from the unit after a power loss (2026-10-02): every
window, binding and session came back, but the bridge treated more than half
of the windows as dead (trap 10) and the summary report was lost to a network
error. A manual restart of the bridge cleared it. The script now does that
restart itself, checks the result and retries the report; those three changes
have passed syntax, shellcheck and a harness over the real state files, and
have **not** yet run in a real cold start.
The bridge-state snapshot and the `offsets:` line (trap 11, 2026-10-03) have
passed syntax, shellcheck and a harness over a copy of the real state files
with the bridge stop stubbed out; they have **not** run in a real restart.

## Files

| File | What |
|---|---|
| `ccgram-respawn.sh` | the script; copy to `~/bin/` (or anywhere on PATH) |
| `templates/respawn-manifest.example.json` | the manifest; copy to `~/.ccgram/respawn-manifest.json` and fill in |
| `templates/ccgram-respawn.service` | systemd user unit; copy to `~/.config/systemd/user/` |
| `dismiss-cards.sh` | closes keyboard-only cards in the session windows; see [Cards nobody can answer](#cards-nobody-can-answer) |
| `next-session.sh` | clears one session and types its kickoff line; see [Handoff, clear, kickoff](#handoff-clear-kickoff) |
| `templates/next.command.md` | a slash command that does the handoff and then starts `next-session.sh`; copy to your user commands and fill in the path |
| `context-meter.sh` | saves each session's context usage to a file a hook can read; see [Context usage for hooks](#context-usage-for-hooks) |
| `relay.sh` | turns a relay run on and off for a project and keeps its state; see [Relay](#relay) |
| `relay-stop-hook.sh` | the Stop hook that pushes a relay session to the next task or to a hand-over |
| `checklist.md` | what "applied" means |

Requirements: bash 4+, tmux 3.0+, python3 (3.8 is enough, no packages),
`curl`, `flock`, ccgram 4.x with its hooks installed (`ccgram hook --install`),
a `tmux-keeper.service` that owns the tmux server (so restarting the bridge
never kills the sessions), linger enabled for the user.

## The manifest

```json
{
  "tmux_session": "ccgram",
  "claude_command": "claude --settings ~/.ccgram/no-telegram.json --dangerously-skip-permissions",
  "report": { "summary_thread_id": <thread-id>, "per_topic_line": true },
  "windows": [
    { "name": "<topic-name>", "cwd": "~/projects/<repo>", "thread_id": <thread-id>,
      "model": "<model>", "resume": "summary", "group": "default" },
    { "name": "<other-topic>", "cwd": "~/<second-root>/<repo>", "thread_id": <thread-id>,
      "model": "<model>", "resume": "full", "group": "second",
      "config_dir": "~/.claude-second" }
  ]
}
```

- **Order matters.** Windows are created top to bottom. After a reboot tmux
  numbers windows from `@2` again, so the order is what lines the new ids up
  with the topics. The script rewrites the bindings anyway, but keeping the
  order stable means nothing moves in the bridge's eyes.
- `name` must equal the topic name; the bridge's rebind-by-name is the fallback
  in warm mode.
- `effort`: optional, passed to the agent as `--effort <level>`; left out, the
  session keeps the model's default.
- `enabled`: optional; `false` parks the entry. The run treats it as absent -
  no window, no session, and in cold mode its topic binding is dropped like
  any binding outside the manifest - and lists it on the `parked:` line of
  the report. `--only <name>` overrides it for one run; bringing a parked
  window back that way is a warm run for a window without a binding, so
  trap 8 applies. Not verified in a real cold start.
- `resume`: `summary` (cheap, loses detail), `full` (expensive), `fresh` (a
  new session). The session id is never stored - it is the newest transcript in
  `<config_dir>/projects/<cwd-slug>/`, resolved at run time.
- `config_dir`: a separate `CLAUDE_CONFIG_DIR` for windows that must not share
  the default account or settings (a second account, for example).
- `group`: the model-diversity check needs at least two distinct models per
  group, so one provider-side incident does not take the whole group down.
  The check only reports; it never blocks.
- Paths are written with `~`; the script expands `$HOME`, so the manifest
  survives a restore onto another machine with the same user name.

## What the script does

```text
ccgram-respawn.sh [--dry-run] [--only NAME]... [--fresh] [--no-report]
```

Mode is chosen from what exists:

- **cold** (no manifest window exists - the reboot case): stop the bridge
  (there is nothing to lose yet), create the tmux session and every window in
  manifest order, rewrite `state.json` so each topic points at its new window
  id (display names, per-window offsets and resumable window states move with
  it; bindings to threads not in the manifest are dropped and logged), start
  the bridge, wait for its startup cleanup, then launch the sessions, then
  restart the bridge once more (trap 10).
- **warm** (some windows exist): the bridge is not touched - it wipes its
  session map on shutdown when windows are alive. Missing windows are created,
  windows without a live session get one, live windows are kept. `--only`
  limits which windows get a session; in cold mode all windows are still
  created so the ids line up. After a warm relaunch the bridge is restarted
  once: it keeps an in-memory "dead" flag for a window whose session ended,
  and a new session in the same pane does not clear it.

After that restart, in either mode, the script reads the bridge's state file
and counts the windows it lists as live (a pane record and the manifest's
binding); a window that is running a session but is missing there is a
reported problem.

Every time the script stops the bridge it first copies `monitor_state.json`
and `session_map.json` into `~/.ccgram/pre-restart/<timestamp>/`, copies
`monitor_state.json` again once the bridge has saved it on stop, and logs who
asked for the stop (own window and the parent process). The ten newest
snapshots are kept. It then compares each saved transcript offset with the
size of that transcript: a session with more than 64 KB unread, or an offset
past the end of the file, goes into the log and into the `offsets:` line of
the summary. This is a warning, not a failure (trap 11).

Per window, one at a time with a pause between: send the launch line, watch
the pane for the "Resume from summary / full" dialog and answer it as the
manifest says, or for the prompt; then wait for the bridge's session-map entry
and repair it from the hook event log if the SessionStart race lost it. A
consent or trust dialog is reported as "needs attention", never answered.

At the end: the model-diversity check per group, a process-count sanity check,
the bridge check, a summary line per window. The summary goes to
`summary_thread_id` and, with `per_topic_line`, one line goes into each
restored topic (Bot API, token read from `~/.ccgram/.env`). The summary is
retried with a growing pause, because the network is often not up yet right
after a boot; the per-topic lines are sent once. `--dry-run` prints all of
this and changes nothing.

## Loop protection

An auto-restart that goes wrong multiplies processes until the machine is out
of memory - the owner has been there with another tool. So:

- one run at a time (`flock` on `~/.ccgram/respawn.lock`);
- the script never kills a window or a process, in any mode;
- it launches at most as many sessions as the manifest lists, and stops if
  processes appear that it did not start;
- the unit is `Type=oneshot` with `RemainAfterExit=yes` and no `Restart=`: one
  run per boot, a second `systemctl start` is a no-op, `TimeoutStartSec`
  bounds the whole run;
- a run when everything is already alive exits early with "nothing to do".

## Cards nobody can answer

A session driven through a chat bridge has nobody at its keyboard. Now and
then the agent's TUI raises a card that waits for a key press - the one seen
so far is the feedback draft, a framed box that ends in
`1 to review · 2 to send · 0 to dismiss`. From the chat there is nothing to
press, so the card stays and covers the status line.

`dismiss-cards.sh` looks at every window of the bridge's tmux session and
presses the dismissing key where it sees such a card:

```bash
dismiss-cards.sh --dry-run        # what it would dismiss, nothing pressed
dismiss-cards.sh                  # every window
dismiss-cards.sh --only <window>  # one window, repeatable
```

It never sends anything anywhere: dismissing a feedback draft folds the card
away and leaves the draft queued on the machine, unsent. It presses one key
per card and never Enter. A card is recognised only by its framed lines at
the bottom of the pane, so the same words quoted in a conversation do not
match. If the key lands in the input line instead of the card, it is erased
again and the window is reported as still showing the card. The exit code is
non-zero when a card survived.

To call it from the chat, wrap it in a slash command of your own that runs the
script and reports its output; the bridge puts such a command into the chat
menu.

**Added by the kit, proven in part.** The key itself was pressed by hand in
two real sessions (2026-10-07) and the card went away. The script has passed
syntax, shellcheck and three fake screens - a card that takes the key, a card
that ignores it, and the card's words quoted without a frame - and has **not**
yet met a real card. Known cards live in the `CARDS` table at the top of the
script; add a row only for a card seen for real.

## Handoff, clear, kickoff

The routine after a handoff never changes: wait for the session to finish,
type `/clear`, wait again, type the line that makes the fresh session read its
rules file and its session prompt. From a chat that is three messages and two
waits per session, and with five sessions it is fifteen.

`next-session.sh` does the routine for one window:

```bash
next-session.sh --window <window> --dry-run   # the plan, nothing pressed
next-session.sh --window <window>
next-session.sh --cwd <project-dir>           # find the window by its project
```

1. waits until the agent is idle, then a little longer so the bridge delivers
   the last reply;
2. types `/clear`;
3. points the bridge's session map at the new transcript - repairing it when
   the agent's hook was lost - and marks the entry `replay_from_start`;
4. types the window's `kickoff` line from the manifest (or `--kickoff`).

Step 3 comes before the kickoff on purpose. After a clear the bridge can keep
the previous conversation as the window's session for up to a minute: it
treats the new one as nested while the old transcript is still fresh. When it
finally switches, it starts reading the new transcript at its end, and the
session's first reply - the answer to the kickoff - never reaches the chat.
With the mark, a bridge that switches late reads the new conversation from its
first line; a bridge that already follows it ignores the mark.

A session cannot clear itself, so the script runs outside it.
`templates/next.command.md` is the other half: a slash command that makes the
session write its handoff and then start the script detached, as the last
action of its turn. One message in the chat replaces the whole routine.

It refuses to start when the window has no agent running, has no kickoff
line, or is still busy after fifteen minutes; text is always typed before
Enter; one run per window at a time. A known card on screen is folded away
first with `dismiss-cards.sh`.

**Added by the kit, not verified.** The script has passed syntax, shellcheck
and an end-to-end run against a fake terminal with a temporary manifest and
session map (idle wait, `/clear`, kickoff, map repair), and its busy/idle
reading was compared with nine live windows. It has **not** yet reset a real
session. The `replay_from_start` mark is newer still: the function that writes
it was run against a temporary map, and the bridge's own parser was checked to
accept the marked entry for this agent, but a late switch has not been caught
live with the mark in place.

## Context usage for hooks

The agent tells its status line how full the context window is and tells its
hooks nothing of the kind. A hook that has to decide whether a session should
hand over and start clean has no number to decide on.

`context-meter.sh` sits in front of the status line command. It reads the JSON
the agent pipes in, saves the few numbers a hook needs, and runs the real
status line with the same input:

```json
"statusLine": { "type": "command",
  "command": "context-meter.sh <your status line command>" }
```

One file per session, `~/.ccgram/context/<session_id>.json` (or
`$CONTEXT_METER_DIR`), mode 600, replaced atomically:

```json
{"ts": 1791873102, "session_id": "<id>", "used_percentage": 18,
 "tokens": 180000, "window_size": 1000000, "rate_5h": 7}
```

A hook gets the same `session_id` in its own input, so it knows which file is
its session's. Three things to keep in mind when reading it:

- a value the agent did not send is `null`. Before the first reply of a
  conversation `used_percentage` is `null` - that is "unknown", not "empty";
- the file is as fresh as the last redraw of the status line: check `ts`
  before trusting it;
- `used_percentage` is a share of that session's own window, so the same
  percentage means five times more tokens on a 1M window than on a 200k one.
  `tokens` and `window_size` are there for a rule that needs the size.

The meter never fails the status line: without python3, with an unwritable
directory or with input that is not JSON it leaves the file as it was and the
status line still runs. A session id that is not a plain id is not used as a
file name. Old files are not removed; each is about 120 bytes.

**Added by the kit, proven in part.** The script has passed syntax, shellcheck
and nine runs on made-up input (full input, `null` percentage, tokens derived
from the percentage, input that is not JSON, a hostile session id, an
unwritable directory, the exit code and the output of the wrapped command),
and costs about 30 ms a call on the owner's machine. It has run as the status
line of a throwaway session across four conversations and of one long-lived
session: the file matched the footer each time, and a new conversation after
`/clear` got its own file under its new session id. **Not verified:** a hook
that reads the file - none exists yet.

## Relay

A relay run is a session working through a plan of several tasks on its own.
At the end of every turn a hook decides: push the session to the next task,
let it finish and hand over to a clean conversation because the context has
filled up, or stop the run and ask a person. The hand-over is the routine
above - handoff, `/clear`, kickoff - so the next conversation picks the plan up
where the previous one left it.

**Not finished.** What exists: the switch, the state and the Stop hook that
decides. What does not: the hand-over does not yet tell the run it has started
or count itself, nothing carries the plan into the new conversation, a reply
cut off by an API error is not picked up (the agent raises `StopFailure` for
it, not `Stop`), and background work that never ends is noticed only at the
next end of turn. Until those exist a run can push a session through tasks
but cannot take it across a reset on its own.

```bash
relay.sh on --plan docs/plan.md      # start a run for this project
relay.sh status                      # where it stands; --all for every project
relay.sh wait --reason "asked about naming"   # let one end of turn through
relay.sh off --reason "plan finished"
```

One run per project directory. The state is one file,
`~/.ccgram/relay/<project>-<hash>.json` (or `$RELAY_DIR`), mode 600, replaced
atomically under a lock; `relay.log` next to it records every switch.

| Setting | Default | What it limits |
|---|---|---|
| `--soft` | 35 | context %, from which no new task is started: finish, wait for background work, hand over |
| `--hard` | 45 | context %, from which the session hands over without waiting |
| `--max-resets` | 6 | hand-overs in one run |
| `--max-stalls` | 2 | pushes in a row that changed neither the commit nor the plan file - the session is spinning |
| `--rate-max` | 85 | 5-hour usage %, above which the run stops |
| `--bg-wait` | 30 | minutes to wait for background work before handing over anyway |
| `--handover` | `/next` | the command the session runs to hand over and start clean |

The thresholds are a share of the session's own context window, read from the
file `context-meter.sh` writes. Two rules are built into the switch rather
than left to the caller: the ceiling on hand-overs is always set and cannot be
zero, and `on` refuses to replace a run that is already on, so a session
cannot reset its own counters by starting the run again.

### What the hook decides

`relay-stop-hook.sh` is installed as a Stop hook of the agent, next to any
hook already there. It reads its input, the run's state and the meter's file,
and either lets the turn end or refuses the stop with a reason the session
reads as its next instruction. It presses nothing and sends nothing.

| At the end of a turn | The hook |
|---|---|
| no run is on for this project | says nothing (about 7 ms) |
| a hand-over is already running | lets the turn end |
| the session declared `wait` | lets this one turn end |
| context below the soft limit | "take the next unfinished task of the plan" |
| between the limits, first time | "start no new task, finish the current one" |
| between the limits, background work running | lets the turn end: the work wakes the session when it finishes |
| between the limits, nothing running | "hand over now" |
| at or above the hard limit | "hand over now", without waiting |
| a limit is used up | turns the run off and tells the session to report it in one line |

The limits that turn a run off: hand-overs used up, pushes without progress,
the 5-hour usage ceiling, three requests to hand over that were not followed,
a plan file that cannot be read, and a context reading that is missing or
older than fifteen minutes - without the number the hook cannot decide, so it
stops instead of guessing. The stop is reported by the session itself in its
own chat, so the hook needs no way to send a message.

Three facts about the agent that shape the table, each observed on a
throwaway session (Claude Code 2.1.296): a finished background task wakes the
session and the hook runs again with an empty list; scheduled tasks and
background shell commands survive `/clear` and keep running in the new
conversation, so the hook asks for them to be listed in the handoff instead of
restarted; and `/clear` typed while a turn is running is queued until the turn
ends. Background agents were not checked.

One run belongs to a project directory, not to a session: every session whose
working directory is inside the project is driven by it.

**Added by the kit, not verified.** The switch has passed syntax, shellcheck
and a run of every subcommand and every refusal against a temporary
directory. The hook has passed syntax, shellcheck and a harness of 29 cases on
made-up input - every row of the table, every limit, a session in a
subdirectory and in another project, input that is not JSON. No session has
been driven by either.

## Traps this closes

1. Windows created in the wrong order bind topics to the wrong projects, or
   make the bridge open a new, duplicate topic.
2. The resume dialog blocks the window until someone presses Enter.
3. Two SessionStart hooks in the same second overwrite each other's session-map
   entry; the window then receives messages but its replies never reach the
   topic.
4. Sessions created before the bridge finished its startup cleanup get swept
   away as stale.
5. Stopping the bridge while windows are alive wipes the session map.
6. A unit with `Requires=ccgram.service` dies together with the bridge the
   moment the script stops it in cold mode; `Wants=` keeps the ordering
   without the coupling.
7. ccgram 4.9+ stores bindings as `chat_thread_bindings` (`user:chat:thread`
   -> window id) and its startup re-resolution by name does not touch that
   map, so after a tmux server restart every topic points at a window id
   that no longer exists (or, worse, at a new window with a reused id). The
   cold rewrite handles both schemas.
8. **Open, not closed.** A warm run for a window whose binding is missing
   from the state file (for example after a cold recovery that dropped idle
   topics) creates the window, and the bridge auto-creates a fresh topic with
   the window's name within a second, before the script's restart of the
   bridge. The manifest's `thread_id` is not applied. Recovery by hand: stop
   the bridge, back up the state file, rename the new thread's keys in
   `chat_thread_bindings` and `group_chat_ids` to the manifest's thread id,
   start the bridge, delete the empty topic. The fix (write the manifest
   binding before the bridge sees the window) is on the backlog.
9. Launching the agent by hand in a bound window, without restarting the
   bridge, brings the session back but not the topic: the bridge keeps a
   "dead window" flag from the moment the previous agent exited and answers
   every message in that topic with its recovery menu instead of forwarding
   it. This is why the warm path restarts the bridge after a launch. Restart
   the bridge, or use `--only`; never the bare command.
10. A cold start has the same flag problem as trap 9, from the other side.
    The bridge has to be running before the sessions (traps 3 and 4), so when
    it starts, every window holds a bare shell. For a window whose carried-over
    state says an agent ran there, the bridge logs "agent exited to shell" and
    keeps it dead even after the session comes up in that pane; a window whose
    state says it started as a shell is corrected by the SessionStart hook and
    is fine. The run reports success, the sessions are alive, and those topics
    answer with the recovery menu. The script restarts the bridge once after
    the launches in cold mode as well, then checks that every live window has
    a pane record. Not verified in a real cold start yet; the manual restart
    it automates did clear the state.
11. **Open, cause not established.** After a restart the bridge once sent
    several hours of one topic's conversation again, in one burst. The
    suspected cause is a stale saved transcript offset, but once the burst is
    over the offset equals the file size and nothing is left to check. The
    script does not prevent this. It keeps the state files from before and
    after each bridge stop it performs and reports offsets that are behind,
    so the next occurrence can be examined. A stop made by anything else (a
    manual `systemctl restart`, the bridge's own crash) leaves no snapshot.

## Rollout

1. Copy the script to `~/bin/`, the manifest to `~/.ccgram/`, fill in windows.
2. `ccgram-respawn.sh --dry-run` - read the plan.
3. In a quiet hour, with the windows idle: restart the tmux server
   (`systemctl --user restart tmux-keeper`, this kills every window), then run
   the script. Every topic should answer; no new topic should appear.
4. Only then copy the unit, `systemctl --user daemon-reload`,
   `systemctl --user enable ccgram-respawn`.
5. Reboot in a quiet hour. Sessions come back on their own.
   `systemctl --user start ccgram-respawn` afterwards must be a no-op.

Manual fallback when the bridge is already down and one window is yours
(what 2026-09-17 looked like): back up `state.json`, create the missing
windows with `tmux new-window -d -P -F '#{window_id}' -t ccgram: -n <topic>
-c <cwd>`, rewrite `chat_thread_bindings`, `window_display_names` and
`window_states` to the new ids (drop the ones you are not bringing back),
start the bridge, then run the script with `--only` per window - it is warm
mode from there.

Log: `~/.ccgram/respawn.log`. Backups of `state.json` before a rewrite:
`~/.ccgram/state.json.bak-respawn-<timestamp>`.
