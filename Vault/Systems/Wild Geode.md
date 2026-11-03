---
description: Wild Geodes (built 2026-10-29, reworked the same day, not playtested) - after 4-6 min of chopping, the next rock you break had a geode hidden in it; the break goes straight into the hatch reveal, luck from that breaking chop, Uncommon or better, pity counts; no tell; GeodeService/Wild, WildGeodeConfig, admin Ctrl+Shift+J.
type: system
---
# Wild Geode

Design and the user's answers: [[Wild Geodes]]. All numbers are drafts in `WildGeodeConfig`.

## Rules as built
- **Hidden in the rock (user, 2026-10-29):** the first version spawned a geode in place of a broken rock that you walked to and chopped. The user changed it to: the break itself opens the geode, "like the rock had a geode hidden in it", and the last chop is what the luck comes from. **No tell** (user): a geode rock looks like any other rock until it breaks.
- **Timer:** `RockService.Chopped` fires on every rock chop release. `GeodeService` adds the gap since the last chop if it was 8 s or less (`ActiveWindowSeconds`). It's due after a random 240-360 s (`MinSeconds`/`MaxSeconds`), rolled again after each geode. This is a variable-interval schedule counted in active chopping time.
- **Crack:** `RockService.RockBroken(player, zone, ground, quality)` fires on a normal break and on a Master. If it's due, `GeodeService` puts a `WildGeodeSpot` Attachment in `workspace.Terrain` at the rock's ground point, facing the player, and runs `Cracking.Finish` with that break's quality and a session with `IsWild` and no pit model. `Finish` then uses up no geode and rolls `HatchOdds.Roll(..., luck, "Uncommon")`. Luck comes from `Luck.Total` with the breaking chop's quality, so a Perfect or Master helps. Pity counters and guarantees, weather modifiers and the Legendary/Secret announcement work like a bought crack. It skips its own `ChopResult`, hit sounds and Master announcement, because RockService already sent those for the break. The reveal is the normal `GeodeHatched` scene at the spot, and the rock's own break and split play as usual. The pit lock (`releaseLock`) and the hidden aura (`CrackingGeode`) last through the reveal.
- **Skipped (stays due):** tutorial, Backpack full, a Rush Rock out or scheduled by this break (`RockService:IsRushOut`), Best Strength below that zone geode's gate, Robux-only geodes, a pit crack or Auto Open running or revealing.
- **Shared changes:** `HatchOdds.Chances` / `Roll` take an optional `minRarity` that overrides the geode's own floor. `GeodeService` `Session.Model` / `Part` are optional now; `Cracking` hides the model and plays pit sounds only when there is one.
- **Admin:** "Next Rock: Wild Geode" (Events tab, Ctrl+Shift+J, alias `wildgeode`) fills the timer, so the next rock you break hides one.

## Checked
`check.ps1` passes (format, types, build). Not playtested. Watch whether the hatch reveal camera and the chop camera's exit fight each other on a break, and how it looks next to a Master's strike hold.

Related: [[Wild Geodes]], [[Geode Shop]], [[Geode Fall]], [[Golden Rocks]], [[Rock Spawning]], [[Admin Panel]]
