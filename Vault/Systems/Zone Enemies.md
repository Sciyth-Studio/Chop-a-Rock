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

- 2026-11-11: each Guardian now has its own Call (replaces `SFX_Enemy_Roar` at fight start) and Hurt on each hit, see [[Guardian Sounds]].

## Harder Guardians (user 2026-11-12: "way too easy, doesn't feel tense, losing needs to be an actual possibility"; drafts, not playtested)
- **Why they were easy:** the fight's bar used your strength over the zone's weakest rock, and `ChopZones` widens the coloured zones with that ratio. Near 25x (where a Guardian starts fleeing) about 70% of the bar was Great or better. Now `Fight.New` caps it with `ChopZones.CappedRatio(..., EnemyConfig.MaxPerfectShare)` 0.12 (bosses use 0.17), and the client gets the capped ratio through `EnemyChopStart`.
- **Misses heal it:** a Bad or OK chop heals the Guardian by `MissHeal` 1 (up to full; not in the tutorial fight).
- **Hits to win:** `FightHits` 7 (was 6), still 12 s, Good 1 / Great 2 / Perfect 3.
- **No outline:** the black `EnemyOutline` Highlight is gone (user), with its config.

## Knocked-out Guardian (user 2026-11-12: testers found fighting for every egg annoying; built, not played)
- **Rule:** winning a Guardian fight (not the tutorial one) knocks that Guardian out for `KnockoutSeconds` 60 + `KnockoutPerPerfectSeconds` 5 per Perfect in the fight, up to `KnockoutMaxSeconds` 90 (user said yes to both). While it's out, every egg you grab in that zone goes straight to your hand with no fight (`ZoneGeodeService` checks `EnemyService:IsKnockedOut(player, zone)`). One zone at a time per player; winning in another zone wakes the old one.
- **Server (`EnemyService`):** `knockouts[player][zone]` = os.clock wake time, ticked in `checkFights`. The timer pauses while you're in a boss fight (it's pushed back each tick). On waking: "The <Zone> Guardian woke up!".
- **Attributes on the player:** `GuardianWakesAt<Zone>` (server time) drives the client; `BoostEndsGuardianOut` / `BoostPausedGuardianOut` drive a "Free eggs!" label (Green, egg icon) at the top of the bottom-right boost stack (`Screens/BoostPills`).
- **Client (`EnemyController`):** after the win flight the Guardian goes to a new `Out` state instead of `Gone`: lying on its back where it landed (pivot is at the feet, so it's lifted by its radius, +90 degrees about X since Pet faces are -Z), breathing slightly. Its name label shows "Zzz 0:42" in Sky, Red for the last 10 s (`SleepFormat`, `SleepWarnSeconds`), and goes back to "<Zone> Guardian" in Chrome when it wakes and rises at home.
- Not done: the egg prompt says "Grab" in both cases (it already did), so there's no Fight/Grab swap; no wake-up stir animation.

## Hurry-up cues on the knockout (user 2026-11-12, "all the stuff from 1"; built, partly checked)
- **Stages by time left** (`EnemyConfig.StirSeconds` 20, `RollSeconds` 10, `SitSeconds` 3; pose in `Motion` "Out", sounds in new `EnemyController/Sleep.luau`, 3D on the Guardian, 12-140 studs):
  - over 20 s: looped snore.
  - 20-10 s: the snore speeds up 1.15x and every 3 s it twitches with a snort.
  - 10-3 s: no snore; it rolls onto its side (1.1 rad) and grumbles every 1.6 s (its own `SFX_Guardian_<Pet>_Hurt` at 0.8x speed), twitching each time.
  - last 3 s: it sits up halfway (0.8 rad) and growls once (its own Call at 0.7x).
  - last 5 s: `SFX_Enemy_Tick` once a second (2D).
- **Sounds:** `SFX_Guardian_Snore` = ProSoundEffects "Comic Snoring Male Vocals Steady Pace 4" (9113862741, looped); `SFX_Guardian_Snort` = "Comic Snoring Female Vocals Snorting 2" (9113861687). Roblox's licensed library, free to use. Picked by description only: Creator Store audio can't be downloaded for earshot, and two snores made in code didn't read as snoring (best z +1.7, no match), so they weren't used. Not heard by anyone yet.
- **Bug found:** `SFX_Enemy_Roar/Miss/Win/Lose/Tick` were in Studio but never in `AssetRegistry`, so they all played a placeholder (silence) since 2026-11-09. Registered 2026-11-12.
- **Bar:** the "Free eggs!" boost label has a `Progress` bar (Studio, in `BoostPills.Stack.PillTemplate`, hidden on every other label) that drains over the knockout (`GuardianOutTotal` attribute = its length). At 10 s or less the bar and text turn red and the label pulses (`FreeEggsPulse*`). Checked in Play with attributes set on the client: 00:30 left = half bar; 00:07 = red text, red bar.
- Not seen: the stages and sounds on a real knocked-out Guardian.

## Guardian bar replaces the "Free eggs!" label (user 2026-11-13: "should work like a boss hp bar"; built, checked in Play)
![[Boss Bar Look For Guardian Bar.png]]
- `StarterGui.GuardianBar` is a copy of `BossBar` (hearts, halfway divider and Enraged labels removed; the fill's lip made neutral black/white so it suits every colour). `Screens/GuardianBar` + `GuardianBarConfig`.
- Shows while you stand in the zone whose Guardian you knocked out (`Utils/ZoneAt` on your root, `GuardianWakesAt<Zone>`), title "<Zone> Guardian", timer "Free eggs! 0:54" under it. Pops in and out like the boss bar.
- Waits until the zone banner is gone when you've just walked in (`ZoneBannerConfig` fade in + hold + fade out, about 3.9 s), so the two never overlap. Right after a win you're already in the zone, so it shows at once.
- Drains with the time left (`GuardianOutTotal`), and changes colour by share: green over 50%, gold over 20%, then red (`Stages`); the title takes the same text style, and each change flashes the bar. Last 10 s: the timer turns red and the bar shakes harder as time runs out (2 to 9 px).
- Pauses with the knockout during a boss fight (reads `BoostPausedGuardianOut`).
- The "Free eggs!" boost label and its progress bar are gone (`BoostPills` no longer adds it; `Progress` frame deleted from `PillTemplate`).
- Checked in Play with attributes set on the client: hidden 1.5 s after walking in, shown at 5 s; 0:40 = 65% green; 0:06 = red title, red fill, red timer.
