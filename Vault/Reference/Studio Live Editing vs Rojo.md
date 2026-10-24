---
description: The KarateChop place uses Team Create live editing; when Rojo adds new instances but existing script edits never land in Studio, it's the cloud live-scripting session, not Rojo.
type: reference
updated: 2026-10-22
---
The place (placeId 81877269405934) runs in a Team Create live editing session, so Rojo's writes to existing scripts go through Roblox's servers. On 2026-10-02 a flaky wifi connection left Studio with Rojo's new instances created but none of the edits to existing script `Source` applied. The log showed "Internal server error." and "Kicked from Live Scripting Session: Script was deleted", and Rojo's websocket kept dropping.

**Why:** restarting `rojo serve` didn't help, because the server was serving the correct tree all along (`/api/read` showed it). Restarting Studio once the connection steadied fixed it.

**Port:** `default.project.json` sets `servePort` 34872, so `rojo serve` listens there. AGENTS.md still says 34873; trust the project file. If new scripts are missing from Studio, first check that Rojo is running at all (`/api/rojo` on 34872).

**One edit dropped (2026-10-22):** several quick edits to one file (`GeodeService/Cracking.luau`) synced all but the last, so Studio ran a version missing `require(ReplicatedStorage.HatchPity)` and the first pity crack errored and froze the player mid-crack. `touch` didn't resync it; appending a newline, waiting 3 s, then restoring the file did. After a build, compare each changed script's `#Source` in Edit with its size on disk (`wc -c`), not just one script.

**How to apply:** before a playtest, confirm the sync by reading a changed script's `Source` in Edit mode (per the `studio-playtest` skill). If new instances arrive but edits don't, check Rojo's served tree, then suggest restarting Studio rather than poking at Rojo. See [[Chop a Rock]].
