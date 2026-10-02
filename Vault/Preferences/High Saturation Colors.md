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
