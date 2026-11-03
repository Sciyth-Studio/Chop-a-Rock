---
description: Zone chop rock bodies are realistic muted stone tones (greys, tans, browns, slightly tinted); only the props are saturated. Read the Studio templates for current colours, not recipes.md.
type: preference
---
# Realistic rock bodies

After importing the Desert to Snow rocks, the user retinted every rock body in Studio to a realistic stone colour. The props stayed bright. Claude's first proposal for zones 6-10 (2026-10-31) used max-saturation bodies again, and the user corrected it.

- **Bodies:** muted, natural stone. Each zone's three rocks usually go mid, then darker, then lighter or warmer. For example Snow is 128,138,150 / 88,98,115 / 150,165,180, Jungle is 112,128,96 / 88,98,90 / 150,112,72, and Desert is 222,180,115 / 196,105,55 / 160,78,48. All use Plastic with `2022 Inlet`.
- **Props:** saturated, as before (cactus 60,200,60, coral 255,90,170, flowers 255,220,40), all Plastic.
- The colours in `rock-model/references/recipes.md` are the old saturated ones. Read `ReplicatedStorage.Assets.Models.Rocks.<Zone>.Model_Rock_*` in Studio for the real values.
- This overrides [[High Saturation Colors]] for rock bodies only.

Related: [[Zone Rocks Reference]], [[World 1 Plan]]
