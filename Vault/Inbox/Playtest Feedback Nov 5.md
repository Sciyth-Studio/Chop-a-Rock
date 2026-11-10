---
description: 2026-11-05 outside playtest feedback from a successful Roblox dev and a regular player - onboarding clutter, no board-break feedback, rock fight HUD, and the big one - eggs and rocks are two unconnected loops; triage and proposals, nothing approved yet.
type: feedback
---
# Playtest feedback 2026-11-05

Two outside testers, shared by the user in Discord screenshots. The user weights the successful dev's notes over the regular player's.

## Successful dev
- First join: spawn in front of the training board, not to the side. Zoom the camera out a bit.
- Hide the top HUD (Base / Shops / Rocks teleport bar) during onboarding. Today the tutorial keeps `TeleportBar` visible on purpose (2026-10-19, "use teleport buttons as much as possible"), so this conflicts with that call.
- Breaking boards gives no visual feedback. No strength popups appeared. Checked: no strength pop exists in code.
- During the chop minigame hide other BillboardGuis (rock labels, shop signs) for a cinematic look. Make the rock health bar at the top bigger and put the HP number inside it.
- "Why am I hitting rocks? Why can't I just grab the eggs?" His fix: **put the eggs in the rocks; break a rock, get an egg.**

## Regular player
- Lock the character while on the training board.
- Eggs and rocks are two separate mechanics: money comes from chopping and from Pets, so with Pets you can AFK and chopping is pointless.
- Huge Foxes earn the same as normal ones. Checked: [[Pet Sizes]] are looks only by design.
- Rebirth panel: the "Play!" button overlaps the Rebirth button (screenshot).

## The core issue
Both testers hit the same thing: rocks don't feed the egg loop. Eggs are free pickups gated only by Strength ([[Zone Geodes And Enemies]]), so rocks only give cash, and Pets give cash too.

Related: [[Tutorial]], [[Chop Minigame]], [[Zone Geodes]], [[Pet Sizes]], [[Training Stand Reference]]
