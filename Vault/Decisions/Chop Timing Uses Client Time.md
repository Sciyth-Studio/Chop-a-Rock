---
description: 2026-10-21 chop meter quality is judged on the client's elapsed time, clamped by ping on the server
type: decision
---
# Chop Timing Uses Client Time

**2026-10-21.** Players said chopping felt ping-based, and it was. The server judged the release by its own clock, so it saw the cursor one full round trip later than the player did. The fixed 0.05 s compensation covered only very low ping. The Perfect zone is passed in about 70 ms (1.5 s cycle, 0.09 wide), so at 150 ms ping a hit that looked perfect was judged Great or worse.

**Now:** `ChopRelease` carries the client's elapsed time since its round started (the same number that freezes the cursor). `ServerScriptService.Utils.ChopTiming.Elapsed` accepts it only between `server elapsed - MaxLatencySeconds` (0.4, draft) and `server elapsed`.
- Don't size the window from `Player:GetNetworkPing()`. The first version did, and Studio's Incoming Replication Lag test gave mostly Mid hits: the reported ping ignores simulated lag, and it can understate real delay, so honest presses were clamped late. The server still decides quality, master rolls, damage and payout.

- Used by all four chop flows: `RockService`, `DiamondRockService`, `GeodeFallService`, `GeodeService/Cracking`. A new chop flow should call `ChopTiming.Elapsed` too, not read `os.clock()` itself.
- This doesn't make scripted perfect timing any easier. The cursor is deterministic on the client, so a script could already press at exactly the right moment.
