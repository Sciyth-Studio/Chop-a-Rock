---
description: 2026-11-13 Discord tester (Vito_Corleone) - cutscene "peak"; chop too long (hold to start, then a skill check "for no reason"), strong enough should just break, only fight the bunny; triage only, nothing decided
type: reference
---
# Playtest feedback, 2026-11-13

One tester on Discord, replying to the user's feedback request. Not decided or built.

- Liked: the intro cutscene ([[Intro Cutscene]]).
- "Make chopping the rock to reveal the egg instant." Too long: hold down click to start (not tap), then a skill check "for seemingly no reason". "If I'm strong enough to break a rock it should just break."
- "Make the only encounter the bunny" (the forest Guardian, i.e. the tutorial fight), so no Guardian fights after it.
- Frame of reference: Steal a Brainrot style, where the stat alone is progress.

## What the code does now (checked 2026-11-13)
- Starting a chop is a 0.5 s hold (`ChopConfig.PromptHoldSeconds`).
- Rock health = `StrengthRequired x HitsAtMinStrength` (4) (`RockService/Session`), damage = strength x quality multiplier. At 4x a rock's requirement one Good chop breaks it, so strong players already one-round rocks, but still sit through the prompt and one bar.
- Chop quality already pays (money, egg type and luck odds, Hot Streak), but nothing on screen says so before the bar.

## Triage (Claude, 2026-11-13)
- Second outside report that fighting for eggs is annoying (after the 2026-11-12 testers that led to the knockout in [[Zone Enemies]]).
- Matches [[Playtest Feedback Nov 5]] on onboarding length.
- Cutting the skill check entirely would remove the game's core (Perfect/Master, [[Eggs From Rocks]] luck, [[Block Rounds]], [[World Bosses]]); the friction points are separable from it.
