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
  "report": { "summary_thread_id": 9, "per_topic_line": true },
  "windows": [
    { "name": "<topic-name>", "cwd": "~/projects/<repo>", "thread_id": 9,
      "model": "<model>", "resume": "summary", "group": "default" },
    { "name": "<other-topic>", "cwd": "~/work/<repo>", "thread_id": 17354,
      "model": "<model>", "resume": "full", "group": "work",
      "config_dir": "~/.claude-work" }
  ]
}
```

- **Order matters.** Windows are created top to bottom. After a reboot tmux
  numbers windows from `@2` again, so the order is what lines the new ids up
  with the topics. The script rewrites the bindings anyway, but keeping the
  order stable means nothing moves in the bridge's eyes.
- `name` must equal the topic name; the bridge's rebind-by-name is the fallback
  in warm mode.
- `resume`: `summary` (cheap, loses detail), `full` (expensive), `fresh` (a
  new session). The session id is never stored - it is the newest transcript in
  `<config_dir>/projects/<cwd-slug>/`, resolved at run time.
- `config_dir`: a separate `CLAUDE_CONFIG_DIR` for windows that must not share
  the default account or settings (a corporate context, for example).
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
  the bridge, wait for its startup cleanup, then launch the sessions.
- **warm** (some windows exist): the bridge is not touched - it wipes its
  session map on shutdown when windows are alive. Missing windows are created,
  windows without a live session get one, live windows are kept. `--only`
  limits which windows get a session; in cold mode all windows are still
  created so the ids line up.

Per window, one at a time with a pause between: send the launch line, watch
the pane for the "Resume from summary / full" dialog and answer it as the
manifest says, or for the prompt; then wait for the bridge's session-map entry
and repair it from the hook event log if the SessionStart race lost it. A
consent or trust dialog is reported as "needs attention", never answered.

At the end: the model-diversity check per group, a process-count sanity check,
a summary line per window. The summary goes to `summary_thread_id` and, with
`per_topic_line`, one line goes into each restored topic (Bot API, token read
from `~/.ccgram/.env`). `--dry-run` prints all of this and changes nothing.

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

Log: `~/.ccgram/respawn.log`. Backups of `state.json` before a rewrite:
`~/.ccgram/state.json.bak-respawn-<timestamp>`.
