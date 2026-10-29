---
description: Team Create is on for the place, so Studio edits save to Roblox as they're made; don't ask the user to Ctrl+S.
type: reference
---
# Team Create saves as you go

Team Create is on for the Chop a Rock place (user, 2026-10-29). Edits made in Edit mode, by the user or through the Studio MCP, save to Roblox's servers as they happen. A Studio restart before a manual save lost nothing: the toolbar session reopened Studio and found the final `StarterGui.Toolbar` and Roks panel there.

- Don't add "save the place in Studio" to-do items, or ask the user to save after Studio work.
- Changes made during a Play test never persist, Team Create or not.
- Edits could be lost only if Studio was disconnected from Team Create when they were made.
- Scripts come from Rojo and git, not from the place file.

Related: [[Studio Live Editing vs Rojo]], [[UI Built In Studio]]
