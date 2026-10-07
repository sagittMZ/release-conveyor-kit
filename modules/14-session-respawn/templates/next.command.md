---
description: Handoff, then /clear and the kickoff line of the next session, in one go
argument-hint: "[a note for the handoff]"
---

Finish this session and start the next one in the same window, in one go.

1. Do the handoff exactly as `/handoff $ARGUMENTS` would, including any project
   rule about where the handoff and the session prompt live. Finish every
   write before step 2 - after it this conversation is gone.
2. Start the reset DETACHED, as the last tool call of the turn:

   ```bash
   systemd-run --user --collect --unit "next-session-$(date +%s)" \
     bash <path-to-kit>/modules/14-session-respawn/next-session.sh \
     --cwd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
   ```

   If it prints an error (no manifest entry, no kickoff line), report the error
   and stop: the session stays as it is.
3. Reply with two lines at most: where the handoff was written, and that the
   window will be cleared and given its kickoff line in about half a minute.
   Then end the turn. Do not call any other tool after step 2, and do not type
   /clear yourself.
