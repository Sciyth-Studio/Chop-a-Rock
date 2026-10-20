---
description: Auras since 2026-10-18 replace arms - cash tiers bought in order at the red Aura Shop, each multiplies training (the old arm numbers) and adds a little walk speed; one shared VFX_Aura template tinted by tier colour; AuraService, AuraController, AuraConfig, Screens/Shop.
type: system
---
# Auras

Merged with arms on 2026-10-18 ([[Cannons And Auras Replace Arms]]). The five hand-made auras of 2026-10-09 (Leaf, Wind, Thunder, Spirit, Dragon) are scrapped; their templates, the `Aura Dragon` showcase stand and `Model_ArmPreview` sit in `ServerStorage.AuraBackup`. The effect lessons from building them are in the vfx skill's `LESSONS.md` and `references/studied.md`.

## Tiers (`AuraConfig.Tiers`)
| # | Name | Price | Training | Speed | Colour |
|---|---|---|---|---|---|
| 1 | No Aura | free | x1 | +0 | none (nothing drawn, no shop row) |
| 2 | Silver Aura | $150 | x1.25 | +2 | 200,205,215 |
| 3 | Green Aura | $2,400 | x1.5 | +4 | 0,255,0 |
| 4 | Lime Aura | $19,200 | x2 | +6 | 150,255,0 |
| 5 | Yellow Aura | $153,600 | x2.5 | +8 | 255,255,0 |
Later tiers continue the user's colour order (silver, then the rainbow in half steps from true green): amber, orange, red-orange, red. Adding one is a config row.

## Data and server
- `PlayerData.AuraTier` (was `ArmTier`; `PlayerData.Migrate` copies `ArmTier` over and drops `ArmTier`, `Auras`, `EquippedAura`). Bought in order, highest owned is always worn, nothing to equip. Kept through rebirth (`RebirthConfig.ResetAuraTier` false).
- `AuraService` (took over `ArmService`): `GetTier`, `GetTrainingMultiplier` (read by `TrainingService`), `BuyTier` (next tier only, cash, tutorial step check), `SetTier` (admin "Set Aura"). Packet `BuyAura(tierIndex)`. It sets `WalkSpeedService:SetBonus(player, "Aura", speed)` and the player attribute `AuraTier` (only for tiers with a colour), which every client reads.

## Client
- `AuraController` watches `AuraTier`, clones the one template `VFX_Aura` (`ReplicatedStorage.Assets.VFX.Aura`) onto the limbs (`Limb`) and root (`Body`) as before, and multiplies every ParticleEmitter, Beam and Trail colour keypoint by the tier colour (PointLights take the colour). The template is authored in white so the tint is the colour; give an instance the attribute `Tint = false` to keep it untinted. Spinning attachments and Low Graphics scaling as before.
- Hidden while cracking a geode (2026-10-19, user): `GeodeService` sets the player attribute `CrackingGeode` (`GeodeConfig.CrackingAttribute`) from the pit prompt through the hatch reveal lock, cleared on leave or teleport. `AuraController` treats it as no colour, so every client drops the aura and puts it back after.
- `VFX_Aura` is built on the user's reference `CurseFlameAura` (user request 2026-10-18), in white: one `Body` part with an `AuraEffects` attachment at Y -3 (the feet) holding its five emitters unchanged apart from colour (`Aura`, `Aura2` rising flame sheets, `S` swirl ring, `G1`, `G2` ground glows), six `TraceRoot` attachments in a 2.5-stud ring at the feet sharing its `GroundPart` streaks (`Trace`, Rate 45 split six ways, because an attachment can't emit from a disc), and a `Glow` PointLight. No limb layers. The reference ran at Brightness 2 to 5 in purple; yellow and silver may blow out (vfx `LESSONS.md` 3), so the user checks the colours. The Leaf-based first version is `ServerStorage.AuraBackup.VFX_Aura_LeafCut`.
- Shop: the old Arm Shop screen (`Screens/Shop.luau`, `StarterGui.Shop`, screen name `Shop`), retitled "Aura Shop" with the Aura Red header icon. Header recoloured red 2026-10-20 (user: "red header thing like rebirth"), copied from `Rebirth.PopRoot.Panel.Header`: fill 255,145,136 / 230,0,0, frame 63,0,0, studs 140,0,0, lip 172,0,0, highlight 255,155,147, bevel 255,206,202. Rows skip the colourless tier, so row names stay `Tier<index>` (the tutorial spotlights `Tier2`). Each row's `Icon` ImageLabel (replaced the arm `Preview` ViewportFrame) is a greyscale copy of the header icon (`assets/Icons/AuraTint/AuraTint.png`) tinted by `ImageColor3`. **It still uses a local preview address** (`rbxasset://textures/vfxpreview/...`) because the upload was blocked; upload it and swap the id before publishing. Old panel in `ServerStorage.UIBackup.Shop.BeforeAuraMerge`, old Aura Shop panel in `UIBackup.AuraShop.BeforeAuraMerge`.

## World
- The red `Workspace.AuraShop` stall (moved by the user 2026-10-20: right side of the centre aisle, pad at (63.35, -269.36), facing -X) opens `Shop` (its pad's `Screen`). The Arm Shop stall was deleted 2026-10-18 (user); the Cannon Shop got its own stall beside it on the same side (see [[Cannon Shop]]).
- Showcase stands `Aura Silver`, `Aura Green`, `Aura Lime`, `Aura Yellow` (`Effect = VFX_Aura`, `Color` attribute). The showcase plugin tints the walker from the stand's `Color` since 2026-10-18 (takes effect after a Studio restart).

Related: [[Cannons And Auras Replace Arms]], [[Balance Pass Oct 18]], [[Shop Pads]], [[Tutorial]], [[VFX Showcase]]
