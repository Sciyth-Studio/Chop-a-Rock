---
description: The KarateChop place uses Team Create live editing; when Rojo adds new instances but existing script edits never land in Studio, it's the cloud live-scripting session, not Rojo.
type: reference
updated: 2026-10-02
---
The place (placeId 81877269405934) runs in a Team Create live editing session, so Rojo's writes to existing scripts go through Roblox's servers. On 2026-10-02 a flaky wifi connection left Studio with Rojo's new instances created but none of the edits to existing script `Source` applied. The log showed "Internal server error." and "Kicked from Live Scripting Session: Script was deleted", and Rojo's websocket kept dropping.

**Why:** restarting `rojo serve` didn't help, because the server was serving the correct tree all along (`/api/read` showed it). Restarting Studio once the connection steadied fixed it.

**Port:** `default.project.json` sets `servePort` 34872, so `rojo serve` listens there. AGENTS.md still says 34873; trust the project file. If new scripts are missing from Studio, first check that Rojo is running at all (`/api/rojo` on 34872).

**How to apply:** before a playtest, confirm the sync by reading a changed script's `Source` in Edit mode (per the `studio-playtest` skill). If new instances arrive but edits don't, check Rojo's served tree, then suggest restarting Studio rather than poking at Rojo. See [[Chop a Rock]].
