---
description: Stale packet-name attributes saved on ReplicatedStorage.Packet made clients pick a channel that doesn't exist and hang ("Infinite yield ... Packet:WaitForChild("EquipAura")"); clear them in Edit.
type: reference
---
# Packet channel attributes

Found 2026-11-12 during an aura Play test: the client never printed "Client controllers ready" and Output showed `Infinite yield possible on 'ReplicatedStorage.Packet:WaitForChild("EquipAura")'`.

- At startup the server sets one attribute per packet on the `Packet` ModuleScript (name = id) and picks the live channel from its own remotes. The client rebuilds the list from **all** attributes on the script (`src/shared/Packet/init.luau`, near line 666) and picks by the same seed.
- The saved place still had 43 old attributes (`EquipAura`, `BuyArm`, `Rebirth`, ...) whose ids collided with current packets, so some starts made the client wait on a remote that no longer exists. Random per server start, so it can hit live servers too.
- Fixed 2026-11-12 by clearing every attribute on `ReplicatedStorage.Packet` in Edit (the server writes the real ones at runtime). Team Create saved that edit; live servers pick it up when the place is published.
- If it comes back: clear the attributes again. A code guard (server clearing attributes before defining packets) would stop it for good; not done, since the user hasn't asked.

Related: [[Team Create Saves]]
