---
description: Default to max-saturation colors for all player-facing UI/VFX unless the user specifies otherwise; includes the chop-quality palette.
type: preference
updated: 2026-09-28
---
Use high-saturation colors by default for any player-facing color choice (UI text, VFX tint, indicator zones, damage numbers, etc.).

**Why:** the game's visual direction is punchy, arcade-style feedback. A prior muted palette (RGB 240,220,60 for perfect, 80,200,80 for good, etc.) was rejected.

**How to apply:** without an explicit spec, reach for pure primaries/secondaries — e.g. yellow `Color3.fromRGB(255, 255, 0)`, green `Color3.fromRGB(0, 255, 0)`, red `Color3.fromRGB(255, 0, 0)`.

Chop-quality mapping (matches the meter zones and quality label):

| Quality | Color |
| --- | --- |
| Perfect | blue-green `RGB(0, 255, 180)` |
| Good | green `RGB(0, 255, 0)` |
| Sloppy | yellow `RGB(255, 255, 0)` |
| Crack/fail | red `RGB(255, 0, 0)` |

Only depart from max saturation when the user asks or a specific mood calls for it. See also [[UI Text Style]].

**Gradients must not wash out (2026-10-10):** a header or button gradient that blends the hue toward a pale centre (for example 70,200,0 to 210,255,90, or 255,110,0 to 255,205,120) reads desaturated. Keep both stops saturated and vary brightness only: a darker saturated edge to a brighter saturated centre (orange 235,85,0 to 255,160,0; blue 0,90,235 to 0,170,255; green 20,170,0 to 60,235,0; red 210,0,0 to 255,40,40; yellow 240,170,0 to 255,235,0). No near-white stops. The Lighting ColorCorrection (saturation 0.5) was not the cause. `Chrome` text is exempt: it is meant to be grey-white.

**Exception (2026-10-23):** chop rock bodies use realistic stone colours, not max saturation. The user asked for this; props on the rocks stay saturated. See [[Zones After Desert]].
