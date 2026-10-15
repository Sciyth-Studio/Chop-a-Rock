---
description: Auras (built 2026-10-09) - bought at the red lobby Aura Shop, unlocked by rebirth count, worn on arms + legs with a trail, add walk speed; data, code, templates, showcase.
type: system
---
# Auras

Design is in the Master Game Plan Decision Log, 2026-10-09: 5 auras (Leaf, Wind, Thunder, Spirit, Dragon), aura N unlocks at Rebirth N, +10 / +20 / +30 / +40 / +50 walk speed, $10k / $75k / $400k / $2M / $10M. One worn at a time. Bought auras survive rebirth. Aura speed stacks with the Hot Streak. All values [PLAYTEST].

## Data and server
- `PlayerData`: `Auras` (owned flags by key) and `EquippedAura` (`""` = none). Admin reset clears both. Rebirth doesn't touch them.
- `AuraService`: `Buy(player, key)` (rebirths, cash, not owned; auto-equips) and `Equip(player, key)` (`""` unequips). Packets `BuyAura`, `EquipAura`. It sets `WalkSpeedService:SetBonus(player, "Aura", speed)` and the player attribute `Aura` (key), which every client reads to draw it.
- Numbers in `AuraConfig`, shop text and button colours in `AuraShopConfig`.

## Client
- `AuraController` watches every player's `Aura` attribute. Each template `VFX_Aura_<Key>` (in `ReplicatedStorage.Assets.VFX`) is a Model with two invisible parts: `Limb`'s attachments, Beams and Trails are copied onto `LeftLowerArm`, `RightLowerArm`, `LeftLowerLeg`, `RightLowerLeg`; `Body`'s onto `HumanoidRootPart`. ParticleEmitters and PointLights placed directly on `Limb` or `Body` are copied onto the part itself, so they emit from the whole limb or torso volume. Beam/Trail attachment links are remapped to the copies. Attachments with `SpinDegreesPerSecond` orbit the part's Y axis every frame (orbiting trails, Thunder arcs, Dragon ribbons and coils). Other players' emitter rates are scaled by Low Graphics.
- `Screens/AuraShop.luau` + `StarterGui.AuraShop`: a red copy of the Arm Shop panel. The row's `Preview` ViewportFrame became an `Icon` ImageLabel (particles don't show in ViewportFrames). Button states: price (green / grey), `Rebirth N` (grey, locked), `Equip` (blue), `Equipped` (red, glow on; click unequips).

## World
- `Workspace.AuraShop`: clone of the Sell Shop 16 studs right (x = 66 since the 2026-10-10 recentring), red `230,0,0` stripes, pad and outline, sign `Red` text style. Shopkeeper `AuraKeeper` (user 169380679 since 2026-10-15, was 4512760450; R6), standing pose kept by copying the old keeper's part offsets from its HumanoidRootPart (see [[Shopkeeper Avatar]], [[Sell Shop]]). Pad `Screen = AuraShop`, `ShopName = Aura Shop` ([[Shop Pads]]).

## Textures
- Drawn 2026-10-09 into `assets/VFX/Aura/` (Leaf, Gust, Bolt and Flame 4x4 loop sheets, Glint, Dot, TrailSoft, TrailBolt, TrailScales, Ring, Streak, Orb) and used as `rbxasset://textures/vfx-preview/...` local previews, in the templates and in `AuraConfig.Icon`. Signed off and uploaded under the group 2026-10-13 (Open Cloud, Image); every address in the templates, showcase and `AuraConfig.Icon` is now `rbxassetid://`.
- Showcase stands "Aura Leaf" ... "Aura Dragon" in [[VFX Showcase]] (`Mode = Aura`): a copy of the dummy walks back and forth so the trail shows.

## Gotcha
- Stacked glow layers blow out on this place: Dragon's coil-head orbs (Size 2, Brightness 4, Rate 40) plus gold body flames at Brightness 4.5 made two white blobs that hid the coils. Heads now Size 1.1 at Brightness 2, flames 2.8 to 3, coil Beams LightEmission 0.2. Spirit's flame body read as flat magenta paint until it got a smaller white-pink `LightEmission` 1 core layer in front.
- Side by side with the user's reference aura ([[VFX Reference Folder]]), the 2026-10-09 rebuild falls short. Spirit is a white glow blob over the body, and Dragon's coils read as orange slabs. The reference uses 3 layers of detailed textures around the feet and none on the body. Rebuilt that way on 2026-10-10 (Layer kit below).
- Rebirths come from formulas since 2026-10-10 (`Utils/RebirthStats`, no cap), so auras 2 to 5 are reachable. Admin `SetRebirths` is capped at `RebirthConfig.MaxAdminRebirths` (100).

Related: [[Hot Streak]], [[Shop Pads]], [[Sell Shop]], [[VFX Showcase]]

## Layer kit (rebuilt 2026-10-10 after studying [[VFX Reference Folder]])
One hue per aura. The spectacle sits around and under the player, and limbs keep only a light accent plus a short trail. Every aura has a detailed ground circle (a flat particle at the feet, Speed 0, Rate 1.5, Lifetime 1, fading in and out), a main trail, limb trails and a soft PointLight.
- Leaf: a wreath circle of leaves with a vine and spokes, a spinning leaf ring, two leaf-ring funnels rising around the body, and loose leaves drifting up.
- Wind: a spiral wind circle, a churning swirl at the feet, and a tornado of three swirl-ring textures rising and widening (the reference tornado technique).
- Thunder: a crackle circle, flat ground crackles flashing, three orbiting lightning strikes (a 4x4 OneShot sheet, upright) beside the body, and flickering arcs on the limbs.
- Spirit: a runic hexagram circle plus a widening halo copy, five streaked light-pillar Beams of different heights orbiting slowly, three orbiting soul-wisp emitters, and glints.
- Dragon: a dragon circle (curling flame crown, scale band, three magatama), a spinning flame swirl, six orbiting cel-fire flames (LE 0, painted shading), a rising flame swirl, and embers.
New textures in `assets/VFX/Aura/` (preview suffix `-1791613049`): LeafCircle, LeafRingA/B, WindCircle, SwirlA/B/C, ThunderCircle, Strike, Crackle, SpiritCircle, Pillar, DragonCircle, CelFire. Still used from before: Leaf, Gust, Bolt, Flame, Glint, Dot, TrailSoft, TrailBolt. Shop icons are the five circles.
- Body wrap, added 2026-10-10 after the user said the auras lacked substance and should go around the body:
  - Every aura gets 2 or 3 spiral ribbons: orbiting `HelixA/B` attachment pairs with Trails.
  - Leaf, Thunder, Spirit and Dragon get a rear flame aura: `AuraRoot` attachments with `AuraFlame`, `ZOffset` -1.6 to -1.8. Leaf and Thunder use CelFire; Spirit and Dragon use the reference cel fire.
  - Leaf, Wind, Spirit and Dragon get rising `Streaks` (reference lines).
  - Wind gets two reference wind-swirl funnels plus a camera-facing `WrapSwirl` on the body.
  - Thunder gets flickering reference electric arcs on the body and limbs, plus rising spark sheets.
  - Dragon's ribbons are wide scale-textured coils with glowing heads.
- Second pass, 2026-10-10, all five seen running:
  - Wind got two camera-facing swirls wrapping the body (`WrapSwirl`, `WrapSwirl2`).
  - Leaf got a camera-facing leaf ring (`WrapLeaves`).
  - Spirit got a rune sphere (`WrapRunes` and `WrapGlyphs`, reference rune textures), and its pillar Beams now use `PillarV`, drawn vertically.
  - Earlier "missing" layers were frozen: particles only simulate near the real Edit camera.
- Flat ground layers need Speed 0.001. At 0 they drew nothing on the moving walkers.

## Third pass (2026-10-10, after the second reference batch)
- **Ground circles removed:** the user said there was enough going on. `Circle`, `CircleLeaves` and `Halo` are gone from all five; the circle textures stay as the shop icons.
- **All rear `AuraFlame`s** now shoot up and stop: Speed 8 to 12, Drag 5, Squash to 0.4, twice the rate (from CurseFlameAura).
- **Spirit darkness**, the user's request:
  - A `DarkFlame` black twin behind each flame.
  - `DarkStreaks` black twins.
  - The runes are now LE 0.5, so they stay saturated over the dark.
- **Thunder:** `Dots` fizz on every limb (from LightningAuraKillua).
- **Dragon:** dark `Smoke` streaks rise among the fire streaks.
- **Leaf:** its flames are now LE 0.3, so they read as green, not white.
- Spirit follow-up (2026-10-10): the user disliked the purple-black `DarkCore` blob, so it was removed. The darkness now comes only from the black `DarkFlame` tongues behind the flames, plus `DarkStreaks`. Spirit's flames went back to our greyscale CelFire sheet at LE 0.8, Brightness 1.6, colour 255,60,230. The reference fire sheet has orange baked in, and magenta over it rendered red.

## Rebuild (2026-10-10, user request)
- **Dragon:** the cartoon fires at the base are removed (`Flame1`..`Flame6`).
- **Spirit, rebuilt from scratch** on CurseFlameAura and ChainBeamAura. Colour 230,40,255.
  - On a `Ground` attachment: a rising `SpiritSwirl` ring (RotSpeed 600, LE 0), `SpiritFlame` and `SpiritFlameThin` sheets that shoot up and stop (Speed 23 to 25, Drag 5, Squash to 0.41), a black `SpiritFlameDark` behind them, and a soft `GroundGlow`.
  - Four `StreakRoot`s with streaks, black twins and embers.
  - Four chain Beams from the body to the floor 6 studs out, with star flares at the ends.
  - Limb embers.
- **Thunder, rebuilt from scratch** on LightningAuraKillua, ElectrocutedBody and PurpleEnergyAura. Colour 255,220,30.
  - Snap arcs on the body and every limb: 3 behind and 2 in front. They use our own Bolt and Crackle textures, because the reference snaps are blue.
  - `Fizz` dots on every part.
  - Five flash sprites, a big arc flipbook and a faint flat shockwave.
  - Five scrolling lightning Beams from above the head to the feet (TextureSpeed -3.5, curved).
- Seen running: both read like their references.
- **Spirit chains**, changed at the user's request (2026-10-10): they now circle the body instead of running to the floor.
  - Two tilted rings, `ChainRingA` and `ChainRingB`: radius 2.4 and 2.7, Y 0.4 and -1.6, tilt 18° and -14°.
  - Each ring is 10 orbiting `Point` attachments joined by chain Beams. Texture Wrap, length 1.8, width 0.95, pale pink 255,175,255 so they read against the magenta flame.
  - The rings spin at 70 and -55 degrees a second.
  - Building a ring from orbiting attachments joined by Beams works: each point spins about Y, so a tilted ring turns as a rigid ring.
- **Thunder, rebuilt a second time** (2026-10-10): the user said there were too many competing particle effects. It now has one hero layer and two small supports, colour 255,220,30:
  - Hero: five scrolling lightning Beams from head to feet (reference 6262372113). Width 4.2 to 6.5, Brightness 2.6, TextureSpeed -3.5, visible from 30% to 75% of their length.
  - Support: `Fizz` dots on the limbs only (Rate 50).
  - Support: one `Arc` flipbook on the torso (Rate 4).
  - Plus the trails and a light.
  - All snaps, flashes, the shockwave and the big arc are gone.
- **Thunder, third rebuild** (2026-10-10): the user said "this version stinks" about the bolt-beam version, so it was redone on ElectrocutedBody and LightningAuraKillua.
  - Hairline lightning snaps on the torso and every limb, using our own greyscale textures `Hairline1-3` (`assets/VFX/Aura/`):
    - three layers behind (Rate 40 on the torso, 30 on limbs, ZOffset -2, gold 255,225,60) and two in front (Rate 5, ZOffset 2, pale 255,245,190);
    - Size 2.7 to 0.62 to 2.12 (scaled 0.7 on limbs), Lifetime 0.2 to 0.3;
    - not locked to the part, so they stream behind a running player.
  - `Dots` fizz on every part (Rate 120, locked).
  - Five faint `Strand` Beams from the Killua reference (6262372113, Brightness 1.2, scrolling -3.5).
  - Trails and a light (Brightness 2, Range 6).
  - The lesson: thin, fine lightning tight to the body read as electric. Chunky bolt sprites read as cartoon.
- Thunder follow-up (2026-10-10): the user said the curving arcs looked odd, so the five `Strand` Beams were removed. Thunder is now hairline snaps, dots, trails and a light only.
