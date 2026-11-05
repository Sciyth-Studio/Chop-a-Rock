---
description: 2026-10-30, approved, not built - to make breaking rock more potent, every zone scales up x1.15 (rocks, floor, terraces, decor; character stays), resetting each world; visible resistance per hit; overkill shatter at 10x strength; RockBreakingPlan.md
type: decision
---
# Rock breaking scale (2026-10-30)

**Status: approved 2026-10-30. Map scaled the same day (zones, boss arena, markers; see [[Zone Line]]), then rocks, the Diamond rock, snap and chop camera (`ZoneScaleConfig` Growth 1.15 over `Order`; `Utils/ZoneScale.Apply` scales a template and its child parts in `RockTemplate.Build`; split pieces, effects, prompts, snap and camera already follow rock size). Resistance and overkill not built.** Full plan: `RockBreakingPlan.md` (D1-D10). Logged in the Master Game Plan's Decision Log.

**Changed 2026-11-04:** the user found the wider, taller zones ugly. Zones now only grow in length, with fewer rocks later on; rocks, enemies and geodes still scale. See [[Zone Line]].

An experienced dev told the user that breaking rock, the core fantasy, wasn't potent enough. The user picked three fixes: scale, visible resistance and overkill shatter.

**Scale, and why not pillars:** a first draft kept zones the same size by making later rocks tall pillars. The user turned it down: pillars aren't the play, leaning on the cannon "isn't the worst thing ever", and auras already give more walk speed as you progress (+2 to +28 on base 25). So everything in a zone scales by one zone scale (x1.15 per zone, draft; Ruins 3.5x), the character doesn't, and the scale resets each new world. The line goes from about 1,700 to 3,400 studs, which max aura speed walks in about the time base speed walks today's line.

**User answers:**
- The chop camera and snap scale with the rock.
- The boss arena is at least the Ruins' scale.
- Chunks knocked off by a hit stay on the ground until the rock you're working on is destroyed.
- Whether far zones load is a performance call. The user may add a camera pan over the zones right after the first intro cutscene, then back into the player's head ([[Intro Cutscene]]).

Related: [[Zone Line]], [[Rock Spawning]], [[Chop Effects]], [[Hot Streak]], [[Cannon Shop]], [[Auras]]
