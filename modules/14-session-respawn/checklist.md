# Module 14 - applied means

1. `~/.ccgram/respawn-manifest.json` lists every window that must survive a
   reboot, in the order of their current tmux window ids, with `thread_id`,
   `model`, `resume` and (where needed) `config_dir`.
2. `ccgram-respawn.sh` is on PATH, executable, `bash -n` and shellcheck clean.
3. `ccgram-respawn.sh --dry-run` on a healthy machine ends with "nothing to
   do"; with one window closed it plans exactly that window.
4. A cold run after `systemctl --user restart tmux-keeper` brings every topic
   back and creates no new topic; every window has a session-map entry.
5. `ccgram-respawn.service` is installed and enabled only after check 4.
6. A real reboot brings the sessions back without a hand on the keyboard, and a
   manual `systemctl --user start ccgram-respawn` afterwards is a no-op.
7. The report arrived: summary in the summary topic, one line per restored
   topic, model-diversity line shows every group with at least two models,
   `bridge:` line shows every window live. A message sent to a restored topic
   reaches its session instead of the recovery menu.
8. After a run that restarted the bridge, `~/.ccgram/pre-restart/` holds a
   snapshot for it and the `offsets:` line of the summary says "all current";
   if it names a session, look at that topic for a replayed burst before the
   snapshot rotates out.
