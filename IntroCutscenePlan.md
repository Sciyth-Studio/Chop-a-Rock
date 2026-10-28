# Intro Cutscene Plan: "The Master" (draft, waiting on the user)

Launch Checklist §1: a short cutscene on first load, then straight into tutorial step 1 (Train), under 20 s. Story from the user (2026-10-27): a giant boulder lands on the player's car, a sensei called the Master Master-chops it in two, the player is jealous, the Master tells them to go train, and they land on the map. Every time, look and line below is a draft.

## The story
The player is driving along a quiet country road, happy, music on. The ground rumbles and a shadow grows on the road. They look up: a boulder bigger than a house is falling out of the sky. It lands right on their car and squashes it flat. The player pops out through the roof like a cartoon, lands on their bum, and sees stars.

From the top of a cliff, someone jumps. The Master flips through the air and lands between the player and the boulder in a ring of dust. He's an old sensei: white gi, black belt, red headband, big grey moustache, calm. He takes the same stance players will learn and does a Master chop: the world goes dark, a gold glow, one strike, a white flash, and the boulder splits clean in two. The halves slide apart and the car pops back into shape with a boing.

The player stares, mouth open, sparkles around them. They want to do that. The Master turns, points at them and says "Go train, kid!". He points off into the distance, the camera whooshes past him into white, and the player is standing at their base, facing their training stand. The tutorial starts: "Break the boards!"

Why it works: the jealousy beat sells the Master chop as the thing to chase (it's the top chop quality in the game), and "Go train" is literally tutorial step 1.

## Shot list (about 18 s)

| # | Time | Shot | Camera | What happens | On screen (one line, ≤ 4 words) |
| --- | --- | --- | --- | --- | --- |
| 1 | 0.0–3.0 | Drive | Low front shot of the car coming toward camera, then a side tracking shot | Player's own avatar drives a small bright cartoon car down a country road. Engine hum, light music. Letterbox bars already in | — |
| 2 | 3.0–5.0 | Uh oh | Tilt up from the car to the sky | Rumble, camera shake builds, a shadow grows on the road, the boulder falls into view | "Uh oh!" |
| 3 | 5.0–7.0 | Crash | Wide shot from the side | Boulder lands on the car: car squashes flat, dust burst, big shake. Player boings out of the roof, lands sitting, circling stars over their head | — |
| 4 | 7.0–9.5 | The Master | Low hero shot from behind the player | The Master leaps off a cliff, flips, lands in a dust ring between player and boulder | "The Master" (Gold style, name card) |
| 5 | 9.5–13.0 | Master chop | The same moves as a real Master chop: side shot → face shot → wide | Darken, gold wind-up glow, `SFX_Chop_Master`, strike, white flash, shake, FOV punch. The boulder splits in two and the halves slide apart; the car pops back to shape | "Master!" (the game's rainbow Master result text) |
| 6 | 13.0–15.0 | Jealous | Slow push in on the player's face, then cut to the Master | Sparkles around the player. The Master turns and points at camera | "Whoa!", then the Master's speech bubble "Go train, kid!" |
| 7 | 15.0–17.0 | Whoosh | Fast push past the Master toward the horizon | Wind whoosh, screen goes white | — |
| 8 | 17.0–18.0 | Your base | White fades out behind the player's character at their base | Letterbox closes, HUD comes back, camera is the normal Custom camera **facing the training stand** | then the tutorial's "Break the boards!" |

Too long? Cutting shot 6's push-in and shortening shot 1 brings it to about 15 s.

Kid safety: slapstick only. The player is never shown hurt: they boing out, see stars and the car pops back.

## Where it happens
The whole road scene is one Studio model (`Assets/Models/Intro/IntroSet`) that is cloned on the player's screen only, far off the map, and removed after. Nothing on the real map changes, and nothing has to stream in. Contents, kept simple ([[Keep Decor Simple]]):
- a strip of road, grass, a few forest trees and rocks reused from the zone decor, a cliff for the Master to jump from;
- a small cartoon car made of parts (bright colour, studs), built so it can be squashed and popped back by scaling;
- camera marker parts for each shot, so shots can be adjusted in Studio by moving parts instead of editing code.

Lighting: the cutscene uses normal daytime lighting even if a weather event is on.

## Characters
- **The player:** a copy of their own avatar, so it's *their* car and *their* jealousy. Sitting pose in the car, then a sit-on-the-ground pose, then a look-up.
- **The Master:** an R15 rig (from `TemplateR15`) in Studio: white gi, black belt, red headband, grey moustache and eyebrows. His chop uses the game's existing chop clips (WindUp + Strike), so he moves exactly like the player will. The leap is a scripted arc; the point is a pose.

## The boulder
**Recommended:** a "Mega Boulder" that's never in the game: the forest boulder mesh at about 6x size, recoloured dark with glowing gold cracks so it reads as special. It splits with the existing split pieces. Alternative: a new boulder modelled in Blender (`rock-model` skill), which takes longer.

## Skip?
**Recommended: no Skip.** It plays once and it's 18 s, and the guide's reason for removing the tutorial Skip (kids tap it by accident) applies. Alternative: a small "Skip" that appears after 3 s.

## When it plays
- Once the player's data loads and the tutorial is at step 1 (Train) with no training rep yet.
- **Rejoining mid-tutorial** (any later step or any rep): no cutscene.
- **Rejoining at step 1 before training:** it plays again. Rare and harmless, and it avoids new saved data. Alternative: save an `IntroSeen` flag so it never repeats.
- Old players and admin presets are at Done and never see it. Reset Player Data brings it back for testing.

## Handoff to the tutorial
- The tutorial already pauses its line, arrows and spotlight while `Letterbox` is open. One extra check (`IntroController:IsPlaying()`) keeps it paused until the camera has settled at the base, so "Break the boards!" and its sound come right after.
- The real character waits at the base, frozen (`MovementLock`) and turned to face the stand. Nothing on the server changes and the funnel stays the same.

## Edge cases
- If anything is missing (set, Master rig, base plot, stand, character) it skips quietly and the tutorial starts as it does now.
- During it: movement locked, prompts off, normal notifications held, HUD and Roblox backpack/top bar hidden and restored after.
- Character dies or resets: it ends at once and gives the camera back.
- Low Graphics on: effects use their low-graphics counts.
- Phones: the caption and bubble use the house `ScreenScale`; nothing to tap.

## Sound
Existing: `SFX_Chop_Master`, rock break, flash. New (from the free Creator Store, imported into `Assets/Sounds/Intro`): car engine, rumble, crash, cartoon boing, whoosh, a short music sting.

## What gets built
Code:
- New `src/client/Controllers/IntroController/` — `init.luau` (when to play, timeline, cleanup), `Shots.luau` (camera moves between the set's markers), `Actors.luau` (avatar copy, Master, car squash, poses).
- New `src/shared/Config/IntroConfig.luau` — times, sizes and lines.
- New `Screens/IntroCaption.luau` — the one caption line.
- Small additions: `RockController:PlayBreak` (existing Master wind-up + split effects on a given part), a pause check in `TutorialController/init.luau`, registry and screen list entries.

Studio (the user saves the place after):
- `Assets/Models/Intro/IntroSet` (road, car, cliff, camera markers, Mega Boulder), `Assets/Models/Intro/Master` (rig and outfit), `Assets/Sounds/Intro`.
- `StarterGui.IntroCaption` (bottom caption, Chrome style with shadow) and a speech-bubble billboard for the Master.

## Decisions for the user
1. Story and shot list OK (or 15 s cut)?
2. Mega Boulder: scaled-up recoloured boulder (fast) or a new Blender model?
3. The Master's look: white gi, black belt, red headband, grey moustache?
4. No Skip, and replay before the first rep is fine?
5. Lines: "Uh oh!", "The Master", "Master!", "Whoa!", "Go train, kid!"?

## As built (2026-10-27, user approved the defaults; not playtested)
- About 17.2 s. Animations made by Claude (the animator fell through) and uploaded to the group: `assets/Animations/Intro/intro_clips.py`, ids in `ids.json`.
- Layout changed so the leap clears the boulder: the cliff is behind the boulder, the Master jumps 30 forward and 22 down over it, and the player boings 9 studs to the left. The Mega Boulder is the forest Boulder (`Second`) at 2x, dark grey with a gold outline.
- No new sounds: existing thunder, cannon boom, board throw, cannon land and whoosh sounds.
- No speech bubble: "Go train, kid!" is the caption line. "The Master" and "Master!" use the Gold style.
- No sparkles on the awe shot; the push-in carries it. Stars over the dazed player are three small neon balls.
- Details and the timeline: vault note Intro Cutscene.

Later idea, not in this plan: the Master could stand in the lobby or appear when a player hits their first real Master chop.
