---
description: 2026-11-12 every custom ProximityPrompt draws from the one ChopPrompt template, restyled after the user's reference; green block key that fills white from the bottom, "[stat] Name" line on egg and Pet prompts only.
type: system
updated: 2026-11-12
---
# Interaction Prompts

`PromptController` draws every prompt whose `Style` is `Custom` (rocks, Diamond Rock, boss, training, shop pads, hatch pads, eggs, Pet pickups) from one template, `UI_ChopPrompt` (`ReplicatedStorage.Assets.VFX.Rock.ChopPrompt`). The name is historical; changing it changes every prompt.

## Reference (user, 2026-11-12)
![[Prompt Ref Idle.png]]
![[Prompt Ref Held.png]]
Take: no panel, a square key tile on the left, a small "[stat] Name" line above a big bold italic action word. Holding fills the key from the bottom (second image). The user wanted the key in our block-button style, filling with white, not the reference's rounded lime key.

## Built 2026-11-12, not playtested
- Template 340x76. `Root.Button` (64px) is a copy of the green Base teleport button: dark outline background, 3px black `OuterStroke`, `Track` inset 4px with `Fill` (studs 16px tile, no stripes), 3px `Bevel`, 6px `Lip` + `Highlight`; no `UICorner`. Old template in `ServerStorage.UIBackup["ChopPrompt.BeforeBlockKey"]`.
- `Track.HoldFill` is a white frame anchored at the bottom; `PromptController.setProgress` sets its height 0 to 1. Transparency is `ChopConfig.PromptFillTransparency` (0.25).
- `ObjectLabel`: 26px plain white, black stroke, `RichText` on. `ActionLabel`: 44px `Chrome`, italic, 4px black stroke.
- Stats come from `Utils/PromptStat` with colours in `PromptStatConfig` (money green, time white, luck gold):
  - Zone eggs: hatch time after base upgrades, `[2m] Forest Egg`.
  - Falling Egg: `[Rare+]` in gold.
  - Starter egg: `[15m] Mystery Egg`.
  - Pen Pet pickup: `[$5/s] Huge Shroomy` (size shown unless Normal).
  - Hatch pads stay name-only (the pad shows its own timer). The exclusive stand prompt uses the default Roblox style, so it isn't affected.

Related: [[Kid Friendly Pass]] (click icon on the key), [[Tile Style Reference]] (block button spec), [[UI Text Style]].
