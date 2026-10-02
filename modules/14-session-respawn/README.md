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
that actually happened). **Not verified**: the script has passed syntax,
shellcheck and dry-runs in all three modes (nothing to do, warm, cold), but a
real cold run after a tmux server restart and a real reboot with the unit
enabled are still pending. This section changes to "verified" when they pass.
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

## Files

| File | What |
|---|---|
| `ccgram-respawn.sh` | the script; copy to `~/bin/` (or anywhere on PATH) |
| `templates/respawn-manifest.example.json` | the manifest; copy to `~/.ccgram/respawn-manifest.json` and fill in |
| `templates/ccgram-respawn.service` | systemd user unit; copy to `~/.config/systemd/user/` |
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
