---
description: Built 2026-11-03, not playtested - one personal enemy per zone, a scaled-up Common Pet; spam-click fights started only through EnemyService:RequestFight; server counts clicks and health, client draws the enemy and launches you if you lose.
type: system
---
# Zone Enemies

Step 6 of `ZoneGeodesPlan.md`, decision in [[Zone Geodes And Enemies]]. Built 2026-11-03, not playtested. All numbers are in `EnemyConfig` and are drafts. They still get the [[Balance Model]] pass.

## How it works
- **Call:** `EnemyService:RequestFight(player, zone, onResult): boolean`. It returns false below the zone's weakest rock, during another fight, during a cannon flight, or with no live character. `onResult` fires exactly once with `Won`, `Fled`, `Lost` or `Left`, always deferred, so `RequestFight` returns first. `Won` and `Fled` mean the geode is theirs.
- **Server:** `EnemyService` holds fights and sends only that player `EnemySpawned`, `EnemyFightStarted`, `EnemyFightHit`, `EnemyFightEnded` and `EnemyFled`. Others within 150 studs get `EnemyFightShown` (dust and sound, at most 4 a second), as with `RockChopShown`.
- **Client:** `EnemyController` draws all the enemies (`workspace.Enemies`, local only) and moves them in `Motion`: idle, charge, chase, slam, stagger, return, run away, knocked away on a win, rise. Enemies at home are skipped when you're far away.
- **Rules:** `Utils/EnemyRules` is shared, so the client's flee check and the server use the same numbers.
- **Home:** the floor under the zone's `ZoneGeodeRing` marker, or under `RockSpawnArea` if it has none.
- **Too strong for it (2026-11-03, user's call, numbers are drafts):** an enemy you've outgrown (25x its zone's weakest rock) no longer vanishes. When you come within 60 studs x zone scale, it runs to the corner of the zone's `RockSpawnArea` furthest from you, inset by its radius plus 10 studs x zone scale, and idles there. The corner is picked when the run starts, and it only sets off if the new spot is at least 20 studs x zone scale away, so a cornered enemy doesn't keep twitching. It goes home once you're no longer too strong for it. `Fled` still gives you the geode.
- **Flow (2026-11-03, drafts, from [[Fight Flow Reference]]):** a 1.4 s banner while the enemy charges, a 0.6 s count on each of 3-2-1 with camera cuts (`Shots`), then the fixed side camera. The bar shows on "1" and only moves after 3.2 s; the server ignores clicks until then. Your movement is locked, the HUD is hidden (`HiddenScreens`), each click plays your chop strike, and the scene tints red as you drop below half (`Sequence`). The result banner holds for 1.2 s on a win and 1.6 s on a loss. A loss adds the launch trail, a dent where you land and red arrows back to where you fought (`Arrows`).
- **Screen:** `StarterGui.EnemyFight` with `Screens/EnemyFight`: tug-of-war bar in `Container` (916x96 at 83.5% height, the same as `ChopBar.Bar`, at the user's request), plus `Banner`, `Count`, `Result`, and `Words` with a hidden `WordTemplate`. Text and word lists are in `EnemyConfig`.
- **Name (2026-11-03, user's call):** each enemy is "<Zone> Guardian", on a `UI_PedestalInfo` billboard over its head and on the fight bar (`EnemyConfig.GuardianText`).
- **Bar (2026-11-05, user's call):** same red and green as the chop bar, read from the `Bad` and `Good` colours in `ChopStyleConfig`, and the same see-through finish. `StudTexture`, `Shade`, `Bevel` and `Lip` are copies of `ChopBar.Bar.Track`'s and sit once in `Track`, above both flat fills. Don't put them back inside the fills: `EnemyFill`'s lip and bevel have a higher ZIndex than `Fill`, so they draw over your green side as a red border.
- **Sound (2026-11-03, user's call):** fight hits play `SFX_Enemy_Hit` (sound 139795256698131), and `Assets.Sounds` holds the instance.
- **Facing (2026-11-05, user's call):** at home an enemy faces `EnemyConfig.HomeFacing` (-Z), towards the zone's entrance, since zones run along +Z. Pet models' faces are on -Z. It turns back to this when it respawns or gets home after a fight, but stays as it ran when it flees to a corner.
- **Admin:** `Start Enemy Fight` in the Events tab, alias `fight`, choice of zone. It reports the result as a notification.

## Choices made while building
- Movement is locked in a fight, so the distance check now only catches teleports and respawns. It's measured from where you stood when the fight started, 60 studs x zone scale.
- Starting a fight ends chops and training through `TeleportService:EndActivities` and puts away the held Pet.
- Prompts are off on the client during a fight (`ProximityPromptService.Enabled`), so you can't start a chop mid-fight. `RockService` itself doesn't check for a fight.
- Input: left click and screen taps anywhere, plus E, Space, R2, X and an on-screen Hit button on touch.
- Launch: the client does it, because it owns the character's physics: `PlatformStand` with a velocity. Horizontal speed scales with the zone, height doesn't, because scaling both made Ruins throw you about 760 studs. If there's no ground where you'd land, it throws you the other way.
- Zones 6-10 use Bloky through `EnemyConfig.FallbackPetKey` until their Common Pets exist. Add them to `EnemyConfig.PetKeys`.
- Effects reuse existing templates (`VFX_Rock_Dust`, `VFX_Chop_Hit`, `VFX_Chop_Break` and their sounds). The plan's new launch, defeat and flee effects through the `vfx` skill are not made.

## Gotchas
- Rock strength goes past 2^53 in the later zones, so 40 subtractions from health can leave a sliver and take 41 clicks (seen on Bamboo). `Fight.Hit` treats anything under a billionth of max health as dead.
- `RateLimit.new(count, window)` starts full, so its burst is `count`. The click limit uses 5 per 1/3 s: 15 a second with a burst of 5.

Related: [[Rock Spawning]], [[Zone Geodes And Enemies]], [[Admin Panel]], [[Movement Lock]]

- 2026-11-05: fight side shot zoomed in at the user's ask: `SideShotSpan` 1.1 → 0.75, `SideShotMinStuds` 24 → 16.
- 2026-11-09 (user's ask, not playtested, numbers draft):
  - **Outline:** every enemy model gets a black `Highlight` named `EnemyOutline`, outline only, `Occluded`.
  - **Wander:** idle enemies pause 2-5 s, then walk at 8 studs/s x zone scale with a small hop to a random point within 40 studs x zone scale of home. The point is clamped inside the zone's `RockSpawnArea` (inset by radius + 6 studs). It's rejected unless the ground under it is within 1.5 studs of home height (so not on rocks or decor), and a spherecast from the enemy to it hits nothing that collides (`Wander.luau`). An enemy more than 55 studs x zone scale from home goes back. Outgrown enemies don't wander; they keep hiding in corners. A fight's charge starts wherever the enemy is.
  - **Audio:** fight music is a drop-in folder, `Assets.Sounds.Enemy.FightMusic`, with "Boss Fight" (132347366936691) and "Boss Battle Burnout" (139997523791273), both DistrokidOfficial. One plays looped in the `Music` group for the fight while background music is held (`MusicController:Hold`). An optional `StartSeconds` attribute on a track skips its intro. New sounds in `Sounds.Enemy`: `SFX_Enemy_Roar` on fight start (71120404192383), `SFX_Enemy_Miss` on Bad/OK chops (93311226362113), `SFX_Enemy_Win` (9067124098, zapsplat) and `SFX_Enemy_Lose` (sad trombone, 138116340). These sit in Studio, not in git. Ripped game audio (Sonic, FF7, MKX) was skipped on purpose.
  - **Speed-up (idea A from [[Fight Tension Research]], user's pick):** each fight round the chop bar cursor sweeps 12% faster, up to 1.5x (`SweepSpeedUpPerRound`, `SweepMaxSpeed`, `EnemyRules.SweepSpeed(round)`). The server judges each release at that round's speed (`fight.Round`). The client passes the same function to `ChopController:BeginExternal` and counts `ChopRoundStart`s, so rocks keep a 1x bar. Once half the fight timer is gone, the fight music rises 2 semitones in 0.4 s (`MusicSpeedUp*`; PlaybackSpeed, so tempo rises too). The tutorial's untimed fight never speeds the music up.
  - **Final seconds (idea D, user's pick):** at 3, 2 and 1 s left (`FinalSeconds`) a clock tick plays (`SFX_Enemy_Tick`, 119133534035860, in Studio) and the camera FOV kicks in by 4 and eases back over 0.25 s. On the first tick the fight music gets muffled: an `EqualizerSoundEffect` on the track tweens high gain to -24 dB and mid to -6 dB (`Muffle*`). The chop bar's `TimerText` turns `TimerWarnColor` red at 3 s or less; only enemy fights set a timer, so rocks never see it. Not on the tutorial's untimed fight.
  - **Hitstop (idea G, user's pick):** a Great chop freezes the enemy and your character's playing animation tracks for 70 ms, Perfect and Master for 110 ms (`HitstopSeconds`, keyed by `ChopQuality`). The enemy holds full stagger tilt while frozen (`Motion.Hitstop`), then recovers. The bar and server timing aren't paused; the freeze lands in the round pause.
