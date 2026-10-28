# Chop a Rock: intro cutscene animation brief

> Superseded 2026-10-27: Claude made the clips from this brief (`assets/Animations/Intro/intro_clips.py`). Two distances changed: Boing Out travels 9 left (not 5), and the Leap goes 30 forward and 22 down from a cliff behind the boulder (not 16 and 14).

Thanks for taking this on! This is everything you need to animate the characters in the game's ~18 s intro. The game programmer (Claude) handles the camera, the car, the boulder, effects, sound and text, and plays your clips at the right moments, so you only animate the two characters.

## The story in one breath
A kid is driving down a country road. A giant boulder falls from the sky and squashes their car. They boing out of the roof and land dazed. **The Master**, an old sensei, flips off a cliff, lands like a hero, and splits the boulder in two with one karate chop. The kid stares in awe and wants to do that. The Master points at them: "Go train, kid!" Then the kid wakes up in the game.

Audience: kids 6–12. Style: cartoony and snappy. Big anticipation, fast action, overshoot, clear silhouettes. Think Saturday-morning cartoon, not realistic mocap.

## You only animate rigs
Every clip here is a character rig: the player dummy and the Master. You never move a model. The car, boulder, cliff, dust, stars and camera are all moved by code. Even the two travel clips (P3 Boing Out, M2 Leap) move the body through the rig's `LowerTorso`, not by moving a model.

The easiest tool is Roblox Studio's own Animation Editor, or Moon Animator, on an R15 dummy (Avatar → Rig Builder). Publishing to the group is built in there. Blender works too, but then the clip has to be exported as FBX and imported in Studio's Animation Editor before it can be published.

If a beat is too hard (the flip in M2, say), make a simpler version that keeps the frame timing and events, and say so. A simple clip that hits the timing is better than a fancy one that's late.

## Ground rules (read first)
- **Rig:** R15. Test on the standard R15 dummy (Avatar → Rig Builder → Block, R15) **and** on one tall Rthro body. The player clips play on every player's own avatar, so they must look OK on all body shapes.
- **No body contact on player clips.** A hand touching your own head, belt or face will clip or float on other body shapes. Hands *near* the face are fine. Hands on the ground are fine. The Master is one fixed rig, so contact is OK on his clips.
- **No fingers.** R15 hands are one piece, so a "point" is a straight arm with the hand forward.
- **Frame rate:** 60 fps. All frame numbers below are at 60 fps (f60 = 1 s).
- **Facing:** the rig faces −Z (its front). "Forward", "left" and "right" below are the character's own forward, left and right.
- **Root:** don't move `HumanoidRootPart`. Move the body from `LowerTorso` / the root joint. Most clips stay **in place**. Only the two travel clips (Boing Out, Leap) move the body away from the root, by the exact distances given. When a travel clip ends, the code moves the root to where the body ended, and the next clip starts with the body back over the root.
- **Matching poses:** where a clip says "starts from X's last frame", copy that pose exactly into frame 0 so the handover doesn't pop.
- **Priority:** Action on every clip.
- **Looping:** only the clips marked Loop have Looped on, and their first and last frames must match.
- **Animation events:** add the named events (Animation Editor → ⋯ → Animation Events) at the frames given. Spell them exactly as written. The code listens for them to fire the flash, dust, bubble and sounds.
- **Timing:** keep each clip within about ±10% of its length. The whole cutscene must stay under 20 s. If a beat needs more or less time, tell us. Don't silently stretch it.
- **Faces:** the player's face can't be animated (every avatar's face is different), so the player's feelings must read from the **body**. The Master can have face animation if his head supports it (optional, see M3 and M4).

## Delivery
- **Publish every clip to the Sciyth Studio group, not your own account.** Clips on a personal account won't play in the group's game. In the publish dialog, pick Sciyth Studio as the creator.
- Use these exact names, for example `Intro_Player_Drive`.
- Send the asset ID of each clip, plus the rig and KeyframeSequences as one `.rbxm`, so small tweaks are possible later.
- If you make a custom Master rig (an extra bone for a beard or belt tail, say), send the rig model too.

## Scene layout (so poses aim the right way)
All in studs. An R15 character is about 5 studs tall.
- **Car seat:** the player sits with hips about 1.5 studs above the road. The steering wheel is about 1.2 studs in front of the chest at chest height.
- **Boulder:** huge, about 30 studs tall and 30 wide. It lands on the car.
- **Player after the crash:** sitting on the road about 5 studs to the car's left, facing the boulder.
- **Cliff:** 14 studs tall, beside the road. The Master starts at its edge.
- **The Master's landing spot:** 16 studs forward of the cliff edge and 14 studs down, between the player and the boulder, about 8 studs in front of the player.
- **The Master's chop:** he stands about 6 studs from the boulder's face and chops at his own chest height.

## Timeline (how your clips fit the cutscene)

| Time (s) | Shot | Player clip | Master clip |
| --- | --- | --- | --- |
| 0.0–3.0 | Driving | P1 Drive (loop) | — |
| 3.0–5.0 | "Uh oh!" boulder falling | P2 Look Up | — |
| 5.0–7.0 | Crash | P3 Boing Out | — |
| 7.0–9.5 | The Master arrives | P4 Dazed (loop) | M1 Idle (0.3 s at the cliff top), then M2 Leap |
| 9.5–13.0 | Master chop | P4 Dazed (loop, mostly off camera) | M3 Chop |
| 13.0–15.0 | Awe, then "Go train, kid!" | P5 Awe | M4 Point (starts at about 13.8 s) |
| 15.0–18.0 | Whoosh to the game | (hold last frame) | (hold last frame) |

---

## Player clips (played on every player's own avatar)

### P1 `Intro_Player_Drive` (Loop, 2.0 s / 120 f)
Happy kid driving, without a care.
- **Base pose:** seated, thighs level, knees bent about 90°, feet forward. Spine upright with a slight relaxed lean back. Both hands on an imaginary wheel 1.2 studs in front of the chest, at 10 and 2 o'clock, elbows bent and relaxed.
- **f0–f120:** road bumps. The whole body bobs down 0.1 stud and back up every 30 f (4 bumps per loop), with the head lagging 3–4 frames behind each bump.
- **Wheel:** the hands steer gently left (about 10° wheel turn) over f0–f60 and back right over f60–f120.
- **Happy beat:** the head tilts side to side to the "music": about 8° right at f30, 8° left at f90.
- **Seen from:** a low front shot, then a side tracking shot. Make it read clearly from the side too.
- **Check:** frame 120 = frame 0 exactly.

### P2 `Intro_Player_LookUp` (one-shot, 1.0 s / 60 f)
They hear the rumble, look up, and see the boulder. Fear.
- **f0:** starts from P1's frame 0 pose.
- **f0–f8:** freeze. A tiny startled pop: shoulders up 0.1 stud, head turns 10° to the side (hearing it).
- **f8–f26:** head tilts back about 40° and the upper torso leans back about 15° to look straight up. Ease out, quick start, soft stop.
- **f20–f30:** both hands leave the wheel and come up beside the face, palms out, elbows bent, in a "yikes" pose. The hands don't touch the head.
- **f30–f60:** hold the yikes pose with a fast tremble (±2° on the arms and head, about 15 shakes per second), building slightly.
- **Seen from:** low in front of the car, tilting up toward the sky. The upward head tilt is the key read.

### P3 `Intro_Player_BoingOut` (one-shot, travel, 1.2 s / 72 f)
The boulder squashes the car and the kid pops out the roof like a spring, all slapstick.
- **f0:** starts from P2's last frame (yikes pose, seated).
- **f0–f6:** squash. The whole body compresses down 0.3 stud, arms tuck in, head ducks: the moment the boulder hits.
- **f6:** event **`Boing`**. The body launches up.
- **f6–f30:** flight. The body rises 6 studs above the seat and travels 5 studs to the character's **left**. Starfish pose: arms and legs spread wide, flailing (arms windmill half a turn). While flying, rotate the body 90° to face back toward the car (turning toward its right side).
- **f30–f52:** fall. Arms still flailing, legs come forward into a sitting shape.
- **f52:** event **`Touchdown`**. Lands sitting on its bum on the road, 1.5 studs below the seat height (on the ground), legs out in front.
- **f52–f64:** one cartoon bounce: up 0.5 stud, then down again.
- **f64–f72:** settle into P4's start pose.
- **End position:** body 5 studs left of the start and 1.5 studs lower, turned 90° to face the car, sitting.
- **Seen from:** a wide side shot. Big shapes; the starfish silhouette should be clear.

### P4 `Intro_Player_Dazed` (Loop, 1.5 s / 90 f)
Sitting on the road, seeing stars. Cartoon stars spin over the head; that's an effect, not part of the clip.
- **Base pose:** sitting on the ground, legs out in front and a bit apart, knees slightly bent. Arms propped behind the hips with the hands on the ground. Torso leaning back slightly.
- **f0–f90:** the head makes one slow wobbly circle per loop (about 10° tilt each way, like it's swimming). The torso sways the opposite way, about 4°, half a beat behind.
- Keep it in place, with no travel.
- **Check:** frame 90 = frame 0.

### P5 `Intro_Player_Awe` (one-shot, 1.5 s / 90 f)
They just watched the Master split a mountain. Mouth-open awe, then "I want that!" This is the most important acting beat: the whole cutscene exists to make players feel this.
- **f0:** starts from P4's frame 0 pose.
- **f0–f10:** the wobble stops. The head snaps toward the Master: forward and up about 10°, because he's standing and they're sitting.
- **f10–f35:** the whole upper body leans forward toward him about 20°. The hands come off the ground and up in front of the chest and face, palms facing each other, fingers up. Big wonder, no contact with the face.
- **f35–f55:** hold, with a tiny excited vibrate (±1°).
- **f55–f70:** "I want that!": both fists pump down hard to the chest (stop just in front of it, don't touch), shoulders up, a small bounce up off the ground of 0.2 stud.
- **f70–f90:** settle, leaning forward and staring, fists still near the chest.
- **Seen from:** a slow push-in on the face and upper body from the front. The camera is close, so the upper body carries everything.

---

## The Master's clips (one fixed rig, only in the cutscene)

**Who he is:** an old sensei, calm and kind and a bit of a show-off. White gi, black belt, red headband, big grey moustache and eyebrows. He moves very little until he moves very fast. Calm → explosive → calm is his whole character. Contact poses are fine on him.

### M1 `Intro_Master_Idle` (Loop, 3.0 s / 180 f)
- **Pose:** standing tall, feet shoulder width, hands clasped behind his lower back, chin slightly up, confident.
- **f0–f180:** slow breathing: the upper torso rises 0.03 stud and the shoulders 1° over f0–f90, then back over f90–f180. A single slow blink of the head (a tiny nod down 2°) around f120.
- Used for a moment at the cliff top and as a fallback in any gap.

### M2 `Intro_Master_Leap` (one-shot, travel, 2.5 s / 150 f)
He jumps off a 14-stud cliff with a flip and lands like a superhero.
- **f0:** starts from M1's frame 0, standing at the cliff edge facing forward (toward the road, the player and the boulder).
- **f0–f20:** anticipation. A deep crouch, arms swing back, weight forward over the toes.
- **f20:** takeoff. The arms swing forward and up.
- **f20–f90:** the arc. The body travels 16 studs forward overall, rising to 4 studs above the cliff top at about f45, then dropping 18 studs to the road (14 below the start).
  - **f30–f75:** one full forward somersault (360° around his left-right axis), tucked tight in the middle of the flip (knees to chest) and opening out by f75.
  - **f75–f90:** falling feet first. Arms out for balance, gi-flapping energy.
- **f90:** event **`Land`**. A three-point hero landing: right knee down, left foot planted, right fist on the ground, left arm out behind, head down. Code fires a dust ring and a thud here.
- **f90–f108:** hold the landing, with slight compression into the ground over the first 6 frames, then still. Let it breathe; it's the cool moment.
- **f108–f150:** rise slowly to standing, then the head comes up last, looking straight forward at the player. End in a relaxed standing pose with hands at his sides.
- **End position:** body 16 studs forward and 14 studs below the start, facing the same direction as at the start, standing. The player is about 8 studs in front of him.
- **Seen from:** a low hero angle from behind the player, looking up at the cliff and the Master coming toward camera.

### M3 `Intro_Master_Chop` (one-shot, 3.5 s / 210 f)
The money shot: a Master chop that splits the boulder. The in-game Master chop darkens the screen for 3 s before the hit, and this matches that drama.
- **f0:** starts from M2's last frame, facing the player.
- **f0–f20:** a calm turn of 180° on the spot to face the boulder (a small step turn, not a spin). Don't hurry; he's unbothered.
- **f20–f40:** sinks into a wide horse stance. The right hand rises high above his head as an open hand blade (karate chop), palm facing left. The left hand points forward at the boulder, open, as a guard and aim.
- **f40–f150:** the wind-up hold (about 1.8 s). The camera cuts to a side shot, then to his face, so this has to read in close-up.
  - **f40–f150:** he slowly rises about 0.2 stud in his stance as he gathers power, and the chop hand pulls back a further 15° behind his head.
  - **From f80:** a power tremble builds (small, fast, ±1° growing to ±2°).
  - **Optional face (if his head supports face animation):** brows down and eyes narrow from f40, jaw clenched.
- **f150–f162:** the strike, only 12 frames. A fast diagonal downward chop from above his head to waist height, ending in front of him. The body drops into a deeper stance, the left hand snaps back to his hip, the head stays locked forward.
- **f160:** event **`Impact`**. The hand passes the boulder face here. Code fires the white flash, shake and split.
- **f162–f185:** hold the follow-through frozen, as a hit stop. Code shakes the camera over this.
- **f185–f210:** calm returns. He stands up straight, hands come together in front of his chest, and he gives a small respectful bow (head and upper torso 15°) to the split boulder. *Optional face: a small proud smile.*
- **Seen from:** side, then face close-up, then wide for the split.

### M4 `Intro_Master_Point` (one-shot, 2.5 s / 150 f)
"Go train, kid!"
- **f0:** starts from M3's last frame, facing the boulder.
- **f0–f20:** turns 180° back to face the player and the camera, with a little confident hop-step.
- **f20–f38:** the right arm shoots straight out at the camera in a point. The left hand goes to his hip and the chest puffs.
- **f38:** event **`Point`**. The speech bubble "Go train, kid!" pops up here.
- **f38–f90:** hold the point with one firm nod (head down 8° and back up) around f50–f65. *Optional face: a grin.*
- **f90–f110:** the pointing arm sweeps up and to his left, about 30° above horizontal, as if pointing at a far-off goal on the horizon. His head turns to look there too.
- **f110–f150:** hold. Code starts the camera whoosh toward where he's pointing at f110.
- **Seen from:** front, at about chest height, close enough that the point aims right at the viewer.

---

## Event summary

| Clip | Event | Frame | What the code does |
| --- | --- | --- | --- |
| P3 Boing Out | `Boing` | f6 | boing sound, car squash |
| P3 Boing Out | `Touchdown` | f52 | thud, small dust puff, stars start |
| M2 Leap | `Land` | f90 | dust ring, thud, small shake |
| M3 Chop | `Impact` | f160 | white flash, shake, boulder splits |
| M4 Point | `Point` | f38 | "Go train, kid!" bubble |

## Final checklist
- [ ] 9 clips, exact names, all Priority Action, 60 fps.
- [ ] Loops (P1, P4, M1): first frame = last frame.
- [ ] Handovers match: P1 → P2 → P3 → P4 → P5, and M1 → M2 → M3 → M4.
- [ ] Travel only in P3 (5 left, 1.5 down, 90° turn) and M2 (16 forward, 14 down).
- [ ] Player clips: no hand-to-body contact; checked on Block R15 and on a tall Rthro.
- [ ] Events added with exact names and frames.
- [ ] Published to the **Sciyth Studio** group. Sent the IDs and the `.rbxm`.

Questions about a beat, or a better idea for one? Just ask. If a beat lands better a little longer or in a different way, tell us before you change it, so the timing can be adjusted.
