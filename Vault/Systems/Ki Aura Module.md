---
description: 2026-11-12 reusable client-side ki aura (`ReplicatedStorage.Utils.KiAura`) built in code on any R15 character; recoloured, scaled and toggled only through attributes on the HumanoidRootPart (AuraColor, AuraAccentColor, AuraIntensity, AuraEnabled). AuraController uses it for every aura tier.
type: system
---
# Ki Aura Module

Built 2026-11-12 at the user's request ("we're restarting" after [[DBZ Ki Aura]] was wiped). Wired into [[Auras]] the same day: `AuraController` attaches it per tier (see there).

- Code: `src/shared/Utils/KiAura/` (`init` = Attach and runtime loop, `Layers` = builds every instance, `Palette` = colour ramps from one colour, `Types`), tunables in `src/shared/Config/KiAuraConfig.luau` (attribute names, intensity floors, pulse period, pop, flicker, texture ids).
- `KiAura.Attach(character)` returns `{ SetEnabled, Destroy }`. It builds on the client (run it from a controller for every character); the server only sets attributes on the HumanoidRootPart, which replicate. It cleans up when the character is destroyed.
- Attributes on the HumanoidRootPart, all live: `AuraColor` (Color3, default gold), `AuraAccentColor` (optional Color3, outer edge + sparks), `AuraIntensity` (0-1: rate x0.4-1, size x0.78-1, wisp height x0.65-1, light x0.45-1, shockwave every 2 s down to 1.1 s), `AuraEnabled` (bool; on = burst + 1.6x size pop + 2.5x light pop over 0.4 s, off = emitters stop, light fades 0.3 s).
- Layers: inner glow emitter in every R15 body part (volume, locked) + core glow; wisps = 567395887 flame on the root plus smaller 567395887 flame tongues rising from both feet and shoulders, each with a dark low-LightEmission edge twin so the shape reads on bright skies; flat 7083340510 shockwave ring emitted by timer + floor glow; 6679618752 sparks + 13771290435 crackle; flickering PointLight.
- Colour: `Palette.Derive` makes core (white 18% tinted), hot, main, dark, edge and edge-dark from one colour (value-before-hue rules from the aura skill). All textures are white, so any colour works.
- Budget measured in Play: ~102 live particles steady at intensity 1, plus a one-off burst of 106.

## Lessons
- Studio `screen_capture` freezes particles, so `VelocityParallel` streaks show at random angles and look like blobs. The wisps use `FacingCameraWorldUp` with positive Squash instead: always upright, reads correctly in game and in captures.
- 567395887 only fills the middle of its frame: Size ~4.5-5.6 to get a flame wider than an R15 body.
- Beam columns inside the body width read as stripes over the torso: keep them at radius ~1.9 x root scale, behind.

## Usage
```lua
local KiAura = require(ReplicatedStorage.Utils.KiAura)
local aura = KiAura.Attach(character)
local root = character.HumanoidRootPart
root:SetAttribute("AuraColor", Color3.fromRGB(220, 20, 50))
root:SetAttribute("AuraAccentColor", Color3.fromRGB(255, 180, 40))
root:SetAttribute("AuraIntensity", 0.35)
aura:SetEnabled(true)
aura:SetEnabled(false)
aura:Destroy()
```

Related: [[Auras]], [[DBZ Ki Aura]]

## Changes
- 2026-11-12 user: "the vertical lines in the aura look bad, and the lower levels of auras are too weak visually". Removed the Beam columns and the 15695676700 spike wisps (they read as thin lines); the feet/shoulder wisps are now taller flame tongues of the main flame texture (positive Squash, feet speed 13-17, shoulders 8-11). Raised the intensity floors (rate 0.4, size 0.78, height 0.65, light 0.45) and the tier stages (Spark 0.5, Flare 0.62, Surge 0.75, Overdrive 0.88, Ascended 1). Checked in Play on Silver, Phoenix and Frost.
