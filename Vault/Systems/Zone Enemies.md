---
description: Built 2026-11-03, not playtested - one personal enemy per zone, a scaled-up Common Pet; spam-click fights started only through EnemyService:RequestFight; server counts clicks and health, client draws the enemy and launches you if you lose.
type: system
---
# Zone Enemies

Step 6 of `ZoneGeodesPlan.md`, decision in [[Zone Geodes And Enemies]]. Built 2026-11-03, not playtested. All numbers are in `EnemyConfig` and are drafts. They still get the [[Balance Model]] pass.

## How it works
- **Call:** `EnemyService:RequestFight(player, zone, onResult): boolean`. It returns false below the zone's weakest rock, during another fight, during a cannon flight, or with no live character. `onResult` fires exactly once with `Won`, `Fled`, `Lost` or `Left`, always deferred, so `RequestFight` returns first. `Won` and `Fled` mean the geode is theirs.
- **Server:** `EnemyService` holds fights and sends only that player `EnemySpawned`, `EnemyFightStarted`, `EnemyFightHit`, `EnemyFightEnded` and `EnemyFled`. Others within 150 studs get `EnemyFightShown` (dust and sound, at most 4 a second), as with `RockChopShown`.
- **Client:** `EnemyController` draws all the enemies (`workspace.Enemies`, local only) and moves them in `Motion`: idle, charge, chase, slam, stagger, return, flee, defeat, rise. Enemies at home are skipped when you're far away.
- **Rules:** `Utils/EnemyRules` is shared, so the client's flee check and the server use the same numbers.
- **Home:** the floor under the zone's `ZoneGeodeRing` marker, or under `RockSpawnArea` if it has none.
- **Screen:** `StarterGui.EnemyFight` with `Screens/EnemyFight`: name, time left (turns red at 5 s), health bar and a hint for each input type.
- **Admin:** `Start Enemy Fight` in the Events tab, alias `fight`, choice of zone. It reports the result as a notification.

## Choices made while building
- Walking away is measured from where you stood when the fight started, not from the enemy's home. An admin fight or a geode at the edge of a ring would otherwise end at once. The distance is 60 studs x zone scale.
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
