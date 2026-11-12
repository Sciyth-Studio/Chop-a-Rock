---
description: Auras since 2026-10-18 replace arms - cash tiers bought in order at the red Aura Shop, each multiplies training and adds walk speed; one white ki-flame VFX_Aura template painted per tier from a themed palette and intensity stage (2026-11-12); AuraService, AuraController (+ Paint), AuraConfig, Screens/Shop.
type: system
---
# Auras

Merged with arms on 2026-10-18 ([[Cannons And Auras Replace Arms]]). The five hand-made auras of 2026-10-09 (Leaf, Wind, Thunder, Spirit, Dragon) are scrapped; their templates, the `Aura Dragon` showcase stand and `Model_ArmPreview` sit in `ServerStorage.AuraBackup`. The effect lessons from building them are in the vfx skill's `LESSONS.md` and `references/studied.md`.

## Tiers (`AuraConfig.Tiers`)
Since 2026-11-12 each tier has a themed palette (Core, Main, Edge, Accent, optional Inner) and an intensity stage instead of one rainbow tint (user: "a gradient for aura level scaling was boring"). Names changed with it; Keys changed too (only the index is saved).

| # | Name | Price | Training | Speed | Stage | Palette (core / main / edge, accent) |
|---|---|---|---|---|---|---|
| 1 | No Aura | free | x1 | +0 | - | none (nothing drawn, no shop row) |
| 2 | Silver Aura | $150 | x1.25 | +2 | Spark | white / silver / slate, pale blue |
| 3 | Jade Aura | $2,400 | x1.5 | +4 | Spark | mint / green / teal, gold |
| 4 | Volt Aura | $19,200 | x2 | +6 | Spark | pale lime / electric lime / green, white |
| 5 | Solar Aura | $153,600 | x2.5 | +8 | Flare | white / yellow / amber, orange |
| 6 | Golden Aura | $3M | x2.6 | +12 | Flare | white / gold / orange, cyan |
| 7 | Blaze Aura | $250M | x2.7 | +18 | Flare | yellow / orange / red, yellow |
| 8 | Inferno Aura | $20B | x2.8 | +23 | Surge | orange / red-orange / crimson, gold |
| 9 | Phoenix Aura | $1.5T | x2.9 | +35 | Surge | cream / crimson / wine, gold |
| 10 | Rose Aura | $100T | x3.0 | +40 | Surge | white / hot pink / magenta, gold |
| 11 | Nebula Aura | $8Qa | x3.1 | +46 | Overdrive | pink / magenta / indigo, cyan |
| 12 | Void Aura | $600Qa | x3.2 | +54 | Overdrive | inverted: black flame, purple outer flame and waves, white |
| 13 | Abyss Aura | $45Qi | x3.3 | +63 | Overdrive | cyan / blue / navy, white |
| 14 | Frost Aura | $3.3Sx | x3.4 | +72 | Ascended | white / ice blue / blue, white; inner blue |
| 15 | Celestial Aura | $25Sx | x3.5 | +80 | Ascended | white flame, edge cycles cyan, pink, gold over each particle's life; inner cyan |

The user approved this ladder 2026-11-12 after swapping two drafts: "Toxic" (tier 4) became Volt and "Blood" (tier 9) became Phoenix. `Color` is still set (the palette's main) for the shop icon tint and the training slash colour.

Speeds from Golden (tier 6) up are drafts, raised 2026-11-04 for the longer zones ([[Zone Line]]): each zone takes about 5-11 s to cross with its own aura. Not playtested. The balance model still has the old +2 per tier.

World 1 is 10 zones (user, 2026-10-28), so tiers 6-15 were added 2026-10-28 for it. The rule: from the Desert, one aura per zone priced at about 2.5 min of that zone's income (income grows about x75-85 per zone), plus a zone 10 capstone at about 20 min; training +0.1 per tier so stands keep setting the pace ([[Balance Pass Oct 18]]); speed +2 per tier at first (see the table for the current numbers). Prices for zones 6-10 (Rose on) are extrapolated, so recheck them when those zones are modelled. In balance model v10. `NumberFormat` gained `Qi` and `Sx` for these prices, and the shop row price uses `NumberFormat.Compact` (Commas printed `1e+16` above about 1e15). Adding a tier is a config row.

## Data and server
- `PlayerData.AuraTier` (was `ArmTier`; `PlayerData.Migrate` copies `ArmTier` over and drops `ArmTier`, `Auras`, `EquippedAura`). Bought in order, highest owned is always worn, nothing to equip. Kept through rebirth (`RebirthConfig.ResetAuraTier` false).
- `AuraService` (took over `ArmService`): `GetTier`, `GetTrainingMultiplier` (read by `TrainingService`), `BuyTier` (next tier only, cash, tutorial step check), `SetTier` (admin "Set Aura"). Packet `BuyAura(tierIndex)`. It sets `WalkSpeedService:SetBonus(player, "Aura", speed)` and the player attribute `AuraTier` (only for tiers with a colour), which every client reads.

## Client
- `AuraController` watches `AuraTier`, clones the one template `VFX_Aura` (`ReplicatedStorage.Assets.VFX.Aura`) onto the limbs (`Limb`) and root (`Body`), and hands each copy to `AuraController/Paint` (2026-11-12). Paint reads attributes on the template: `MinStage` (layer only shows from that stage up), `Ramp` (comma list of palette slots, e.g. `Core,Main,Edge`, made into the ColorSequence), `Inverse` (used instead of `Ramp` on inverted tiers like Void; `Black` = dark flame, LightEmission 0) and `Tint = false` (left as authored: black twins, backdrop). Each stage in `AuraConfig.Stages` scales Rate, Size and light brightness (Spark 0.7/0.85/0.6 up to Ascended 1.5/1.1/1.4). Layers without `Ramp` still get the old multiply by `Color`. Spinning attachments and Low Graphics scaling as before.
- Hidden while cracking a geode (2026-10-19, user): `GeodeService` sets the player attribute `CrackingGeode` (`GeodeConfig.CrackingAttribute`) from the pit prompt through the hatch reveal lock, cleared on leave or teleport. `AuraController` treats it as no colour, so every client drops the aura and puts it back after.
- `VFX_Aura` since 2026-11-12 is the white Dragon Ball style ki aura from [[DBZ Ki Aura]] (user: "the new base aura that gets recoloured"): `Body` with `KiFlame` (y 0.75: `Ki_Flame`, `Ki_Outer`, black twin `Ki_Black`, `Ki_Inner` from Ascended), `Waves` (y 0.5: `Wave_Shell` pulsing flame outlines from Surge, `Wave_Shell2` from Ascended), `Core` (`Backdrop`), `Light` (`Glow` PointLight) and body-volume emitters `Wave_Arcs` and `Sparks` (Flare+), `Speed_Lines` and `Lightning` (Surge+). Every texture is white so palettes tint cleanly; the gold and cyan baked textures of the showcase were swapped out. Nothing on the ground (user removed floor layers). The previous CurseFlame template is `ServerStorage.AuraBackup.VFX_Aura_CurseFlame`, the Leaf one `VFX_Aura_LeafCut`. `Workspace.AuraTierPreview` (StudioOnly) holds six R15 rigs painted at build time (Jade, Golden, Phoenix, Nebula, Void, Celestial); it doesn't update when the template changes.
- Shop: the old Arm Shop screen (`Screens/Shop.luau`, `StarterGui.Shop`, screen name `Shop`), retitled "Aura Shop" with the Aura Red header icon. Header recoloured red 2026-10-20 (user: "red header thing like rebirth"), copied from `Rebirth.PopRoot.Panel.Header`: fill 255,145,136 / 230,0,0, frame 63,0,0, studs 140,0,0, lip 172,0,0, highlight 255,155,147, bevel 255,206,202. Rows skip the colourless tier, so row names stay `Tier<index>` (the tutorial spotlights `Tier2`). Each row's `Icon` ImageLabel (replaced the arm `Preview` ViewportFrame) is a greyscale copy of the header icon (`assets/Icons/AuraTint/AuraTint.png`) tinted by `ImageColor3`. It used a local preview address (`rbxasset://textures/vfxpreview/...`), which only loads in Studio, so the tinted icons were blank in game (user, 2026-10-20). Uploaded 2026-10-20 through Open Cloud under the group as `rbxassetid://117629056330338` (`assets/Icons/AuraTint/assets.json`) and set on `Shop...List.RowTemplate.Icon`; `PreloadAsync` returned Success. The two CannonShop backups in `UIBackup` still have the old address. Old panel in `ServerStorage.UIBackup.Shop.BeforeAuraMerge`, old Aura Shop panel in `UIBackup.AuraShop.BeforeAuraMerge`.

## World
- The red `Workspace.AuraShop` stall (moved by the user 2026-10-20: right side of the centre aisle, pad at (63.35, -269.36), facing -X) opens `Shop` (its pad's `Screen`). The Arm Shop stall was deleted 2026-10-18 (user); the Cannon Shop got its own stall beside it on the same side (see [[Cannon Shop]]).
- Showcase stands `Aura Silver`, `Aura Green`, `Aura Lime`, `Aura Yellow` (`Effect = VFX_Aura`, `Color` attribute). The showcase plugin tints the walker from the stand's `Color` since 2026-10-18 (takes effect after a Studio restart).

Related: [[Cannons And Auras Replace Arms]], [[Balance Pass Oct 18]], [[Shop Pads]], [[Tutorial]], [[VFX Showcase]]
