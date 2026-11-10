---
description: 2026-11-09 web research on adding tension to short timing-based fights (Undertale, WarioWare, Blade Ball, Punch-Out, Paper Mario, Rhythm Heaven, Sekiro, Expedition 33, Fisch, Stardew, Mario Party, hitstop, adaptive music, near misses) and the ideas drawn from it for the enemy fight.
type: reference
---
# Fight tension research

Asked for in item 6 of the user's 2026-11-09 list: fights "lack considerable tension" but "length of fight matters". The fight is a 3.2 s intro, then up to 12 s on the chop bar for 6 hits (Good 1, Great 2, Perfect 3). Target: about 12 s or less overall, never over 15. Mario Party minigames run 3-60 s, usually about a minute, so ours are already at the short end.

## What other games do
| Game | Mechanic | What makes the tension |
|---|---|---|
| Undertale / Deltarune | Sliding cursor stopped on a mark, damage by closeness | Easy enough not to slow the turn, critical on the mark |
| WarioWare | 3-5 s microgames, "Speed Up!" steps | Each step shortens the window and raises music pitch about 2 semitones; resets after the boss |
| Blade Ball (Roblox) | Parry a ball that speeds up each rally | Speed climbs, the ball turns red, audio escalates |
| Punch-Out | Read the opponent's tell, then counter | Clear wind-up before every punch; counter-punching rewarded |
| Paper Mario / Mario & Luigi | Timed hits mid-attack | Two tiers ("Ok!" vs "Excellent!", 1.5x vs 2x damage), bonus for any Excellent |
| Rhythm Heaven | Sound carries the timing | The cue is a sound before the action; a slightly-off tap gets a softer "click" but still counts |
| Sekiro | Deflect blows to break posture | Pressure builds then releases; the deflect window is generous, a miss becomes a block |
| Clair Obscur: Expedition 33 | Turn-based with real-time parry/dodge | Enemy turns are a timing test too; "PERFECT" on a last-moment dodge; readable wind-ups were hard to get right |
| Fisch (Roblox), Stardew fishing | Keep a bar on a moving target to fill progress | Constant push-pull; Stardew's dev said the starting bar was too small (too hard early) |

## Feel and audio
- **Hitstop:** freeze both attacker and target briefly on impact. Guides give 30-50 ms light, 60-100 ms heavy, 100-150 ms crits; past ~120 ms it reads as lag. An academic study found hitstop, matching sound and camera most shape "impact feel".
- **Adaptive music:** add layers as stakes rise; at low health, a heartbeat/tension layer or a low-pass filter on the music. Eon Altar sped up its tempo and filtered SFX in its low-health state.
- **Near misses:** a near miss drives the urge to play again more than a clear loss (Waterloo Candy Crush study), and is also the most frustrating outcome. Ours is skill-based, not chance, so it's fair to show it, but don't fake near misses.

## Ideas for our fight (none lengthen it)
A. Bar speeds up each round (WarioWare, Blade Ball), music pitch up at half time.
B. Enemy wind-up tell between rounds; a Bad/OK chop after it costs 1 s of timer (Punch-Out).
C. "So close!" on a chop just outside Good (near misses).
D. Last 3 s: tick or heartbeat each second, FOV pulse, red timer, music low-pass (adaptive music).
E. Last hit left: enemy shakes, "Finish it!", slow-mo final hit (Punch-Out KO).
F. Enemy counter in the round pause: a flash, release on cue to block (Expedition 33, Sekiro); uses the pause, so no extra time.
G. Hitstop on Great and better: 60-120 ms freeze of you and the enemy.
H. Rising tick at the start of each sweep, pitch climbing per round (Rhythm Heaven, WarioWare).
I. Enemy pushes back: a Bad chop heals it 1 hit (Fisch/Stardew push-pull). Risky: can make fights longer, so only with a hard timer.

2026-11-09: the user picked A alone to try first, then added D and G; all three built, not playtested. The rest wait on the playtest. Related: [[Zone Enemies]], [[Fight Flow Reference]], [[Chop Minigame]]
