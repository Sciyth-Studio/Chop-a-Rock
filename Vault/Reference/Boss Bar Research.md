---
description: 2026-11-11 how well-known games show a boss's health (Souls, Hollow Knight, Zelda, Monster Hunter, Terraria, Hades, Cuphead, Roblox) and the design taken for the world boss bar and hearts.
type: reference
---
# Boss bar research

Done 2026-11-11 for the world boss bar ([[World Bosses]], `WorldBossPlan.md` 4.8 and 4.9). Most of this is from knowing the games; web searches gave little beyond a DevForum thread that says a top-of-screen boss bar is easier to read in a fight than one over the boss.

## What other games do
| Game | Where and how | Worth taking |
|---|---|---|
| Dark Souls / Elden Ring | Long thin bar at the bottom centre, name above it on the left, damage number to the right of the name. A chunk of the lost health stays lit and drains after a short delay. Several bosses get stacked bars. | The **delayed "ghost" chunk**: you see how big a hit was. A damage number is noise for kids. |
| Hollow Knight | No boss bar at all. A big title card names the boss when the fight starts; you read its health from how it acts. | A **big name entrance**. Hiding health is wrong for a 9-minute group event. |
| Zelda (BotW / TotK) | Bar at the top of the screen with the name under it. It fills up from empty when the fight starts and flashes on hits. | **Fill-up entrance** and a white **hit flash**. |
| Monster Hunter | No bar. A limp and a skull icon on the map tell you it's weak. | A **low-health tell** that isn't a number: our Finish it! phase. |
| Terraria | Bottom bar with the boss's head icon and HP numbers. Calamity's mod bar adds a delayed chunk and phase-coloured text. | An icon or colour per boss. |
| Hades | Top bar with the name; bosses change look and moves at health thresholds, and the bar shows where they are. | **Threshold markers on the bar**: our halfway (mad) line. |
| Cuphead | No bar in the fight. On a loss it shows a progress line with phase flags. | Phase markers make a long fight feel like it has stages. |
| Roblox (Tower Defense Simulator, raid bosses) | Top-centre bar with the name in big text and the HP inside the bar; shakes on big hits. | **Top centre**, readable at a glance. |

## Common rules
- **Name:** big and above the bar, at the top centre in most action games; it comes in with an entrance (slam or fill-up).
- **Phase markers:** a tick or line at each threshold so players see the next stage coming.
- **Ghost chunk:** lost health first turns light and drains after about 0.4-0.8 s.
- **Hits:** a white flash on the fill, a small shake on big hits only (constant shake is unreadable with 8 players hitting).
- **Low health:** the fill pulses or changes colour.
- **Enraged:** the colour changes, and the change happens with a beat (flash, shake, sound).
- **Leaving:** a defeated boss's bar drains to empty and pops away; a boss that leaves fades its bar out.

## Our design (approved by the user 2026-11-11)
![[Boss Bar Mockup.png]]
Top: outside a chop, under the teleport buttons. Bottom: while chopping, at the top of the screen, mad, with the hearts above the chop bar.
- `StarterGui.BossBar`: name ("Big Croc"), red stud bar with a 4 px black outline and a black **halfway divider**, white m:ss **timer** under it (red, with a pulse, in the last 10 s), and the **hearts** under the timer when you're not chopping.
- **Title:** in all caps ("BIG CROC", user's pick over Title Case; see [[No All Caps In UI]]), two-tone like the reference (hard split, top darker, bottom lighter), coloured per boss in `BossConfig`; turns red and orange when mad.
- **Ghost chunk:** light yellow, drains 0.5 s after a hit. **Hit flash** on every drop; **shake** only on drops over 3% or on crossing the divider.
- **Mad:** title red, bar shakes and flashes, the fill goes deep red and pulses slowly, the timer pops when it jumps to 5:00.
- **Finish it!:** the fill turns gold and pulses.
- **Enter:** the title pops in, then the bar fills from empty. **Defeated:** drains to empty and pops away. **Leaving:** fades out.
- **Who sees it:** everyone inside the Boss Arena (by the arena floor's footprint) or chopping the boss. While chopping, it moves to the top of the screen and replaces the chop bar's own health bar.
- **Hearts:** 5 hearts, 20 HP each, from the `BossHP` attribute. They only show after your first boss chop. An emptied heart turns to a broken heart that pops and fades. The last full heart flashes. Above the chop bar's left end while chopping.
- **Icons:** the user's icon pack (`Main/Heart` 1st, `Main/Broken Heart` 1st, `Heart White` tinted dark for an empty heart), with 7% outlines baked in, in `assets/Icons/Hearts/`.

## Built (2026-11-11)
- `StarterGui.BossBar` > `Root` (960x250, `ScreenScale`) > `Body` (`PopScale`): `Title` / `TitleShadow`, `Bar` > `Track` > `Ghost`, `Fill` (`UIGradient`, `StudTexture`, `Lip`, `Shine`, `Flash`), `Divider`; `Timer` (`PulseScale`) / `TimerShadow`; `Hearts`. `ChopBar.Bar.Hearts` is a 56 px copy above the chop bar's left end. Each heart: `HeartN` > `Holder` (`PopScale`) > `Empty`, `Clip` (`ClipsDescendants`; its width is how full the heart is, so a mad 30 HP hit shows half a heart) > `Full`, `Broken`.
- Code: `Screens/BossBar.luau` (polls each Heartbeat; arena = inside `BossArena.Floor`'s footprint plus 6 studs), `UIController/BossHearts.luau` (used by both screens), `BossBarConfig` (colours per boss, timings), `ChopController:GetTarget()` (the part being chopped). `ChopBar` hides `HealthBar` and shows its hearts when the target has a `BossSpot` attribute.
- Heart icons: `Heart` 71553527648842, `BrokenHeart` 137893606921304, `HeartEmpty` 132000032869615 (`assets/Icons/Hearts/assets.json`). The full heart showed blank in Edit for a while after upload (Studio cached the failed fetch while it was in review); it loaded in Play.
- **Playtest (Claude, 2026-11-11, Big Croc, Play shared with other sessions):** seen: the bar under the teleport buttons with "Wakes up in 0:23", BIG CROC green; -25% from the admin gives a flash, a small shake and the yellow chunk draining after 0.5 s (fill 0.75, ghost 1.0 to 0.75 over about 1 s); crossing half turned the title red and the timer jumped to 5:00; while chopping the bar moves to the top, the chop bar's `HealthBar` hides and the hearts show above the chop bar; missed Block rounds took `BossHP` 100 to 70 to 40 and the hearts read 1 1 0 0 0. Not seen: the knock-out, the last-heart flash, Finish it!'s gold fill, the Defeated drain, and hiding the hearts before your first chop (fixed after the run, not replayed).
- **Notifications move below the bar (user, 2026-11-11):** they used to draw over it while chopping ("Weak spot moved!"). While the bar shows, `Screens/BossBar` writes the screen Y of its lowest visible part (bar, timer or hearts) to the `CoverBottom` attribute on the `BossBar` ScreenGui; `Screens/Notifications` moves `Container` to 8 px below that when it is lower than the container's normal spot (15% down), and back when the attribute clears.

## Diamond Rock (2026-11-11)
The user: "diamond rock is technically a boss so it should have a lot of the same stuff as the rest of them". The bar also shows for `Workspace.DiamondRock` (tag `DiamondRock`, attributes on its `Rock` part) while it is out: "DIAMOND ROCK" in its cyan `TextMain` / `TextLight` / `TextDark`, a cyan fill (`BossBarConfig.DiamondFill`), the timer (red under `DiamondRockConfig.WarningSeconds`), the ghost chunk, flash and shake. No halfway divider, mad look or hearts. Broken (health 0) drains and pops away; timed out pops away. A boss takes priority if both exist (they can't share `DiamondSpot`). It replaced the Diamond's `DiamondLabel` billboard (the `UI_DiamondLabel` asset stays, Geode Fall and the Starter Egg still use it) and hides `ChopBar.HealthBar` while chopping the Diamond. Unused label fields left `DiamondRockConfig`. Not playtested by Claude; the user tests it.

## Signature overlays on the chop bar (2026-11-11)
The user: much stronger effects on `ChopBar` while a boss's signature move is on you, drawn **over the bar's outlines** so it's obvious the boss is messing with you, but still playable. Their ideas:
- Frost Yeti: irregular rectangular ice chunks with icicles, frozen onto the bar.
- Big Croc: a maw clamping in.
- Boulder Crab: stone slabs covering parts.

The user wants **image-generation prompts, not drawn art** ("dont draw them, give me detailed prompts"). The prompts are in `assets/Icons/BossOverlays/Prompts.md`, waiting on the images.

**How the moves work** (from the boss-abilities session's code):
- The server fires `Packets.ChopModifier` with each round start. `ChopController:GetModifier()` returns the kind and 4 values, or `None` in Block rounds.
- A signature lasts `BossConfig.Signature.Rounds` (3) rounds. So an overlay comes in when the kind changes from None to a move, stays across those rounds, and leaves when it goes back to None.
- **Frost:** two patches, each 0.2 of the bar wide (`values[1]`, `values[2]`, width in `values[3]`), drawn today as plain `Track.IcePatch` frames. They move each round.
- **Chomp:** the zone jumps 4 times per round, every half cycle (`ChopZones.ChompCenter`). Today the bar shakes on each jump.
- **Shell:** anything below Great counts as nothing and is coloured grey (`BossFxConfig.Signature.ShellColor`).

**Research:** there are few published write-ups. What carries over:
- **Status should change the meter itself, not just add an icon.** Minecraft's frozen hearts are a separate heart look, and players asked for an even more distinct one. A Path of Exile thread found bleed punishing when you can't tell you're bleeding.
- **Debuffs read as bad by colour and by breaking the frame.** Dead by Daylight uses yellow for buffs and red for debuffs. Overlays that cross the bar's border read as outside interference, not part of the meter.
- **Petrify is a natural "locked out" look.** The Final Fantasy and Bloodstained stone statuses are shown as the thing turned to stone, and breaking free is its own moment. So: stone on the parts that can't score.
- **Removal is a beat of its own.** Crack, then shatter into pieces that fly and fade, the same as the hearts.
- **Keep it consistent.** Every overlay comes in and leaves with the same rhythm: slam in about 0.15 s with overshoot, shake, crack, shatter.

**Design:**
- **Layering:** the overlays sit above `OuterStroke`, `Lip` and `Bevel` (a ZIndex above the Track's 7), but below `CursorLane` and `Cursor` (8 to 9). The cursor always shows. The timer and badge stay on top.
- **Frost:** one ice chunk per patch, a little wider and taller than the patch so it laps over the black outline, with icicles hanging below the bar.
  - In: it drops in at 1.3x scale and settles, frost-white flash, small shake.
  - When the patch moves to a new round: cracks show, it shatters into shards, and a new chunk drops in at the new spot.
  - Out: cracks, then shatter.
- **Chomp:** an upper jaw above the bar and a lower jaw below it, along the whole bar. The teeth bite about 20 px into the 88 px track from the top and bottom, so the middle stays readable.
  - In: the jaws snap shut from off-bar.
  - On each zone jump: the jaws chomp (close deeper for about 0.12 s, then reopen), replacing today's plain shake.
  - Out: they open wide and fly off up and down.
  - This is top-and-bottom rather than left-and-right, because the zone can be anywhere and side jaws would hide it.
  - **Agreed with the user (2026-11-11), visual only:** it's option A plus the "eat". The jaws frame the bar for the whole move. On each zone jump they chomp, the old zone spot flashes dark as if bitten, and the new spot pops in bright.
    - The bite has to be quick (about 0.15 s) so it never hides the new spot.
    - Rejected: jaws closing in from the ends to shrink the bar. That's a gameplay change and unfair when the zone lands under a jaw.
    - The user wants art for the bite too, not just a dark flash. There are two more prompts: `BiteMark` (a chunk bitten out of the bar, over the zone's old spot) and `ChompBurst` (an impact burst where the jaws snap, and a small one where the zone lands).
    - Defaults Claude picked: the teeth bite about 20 px of the 88 px track, and a small bar shake stays on each chomp. They're easy to change.
- **Shell:** slabs slam down over the grey (below-Great) parts on both sides of the Great window, built from the three slab widths. Only the Great and Perfect window stays open. They cover nothing you could score on, so it's harder but fair.
  - In: they drop with a thud and dust.
  - When the window moves: they slide.
  - Out: they crack and crumble into rubble.
- **Images:** `IceChunks` (2), `IceShards` (8), `CrocJaws` (upper and lower), `BiteMark`, `ChompBurst`, `StoneSlabs` (3 widths), `StoneRubble` (8) and `Cracks` (white, tinted per material). Clean-up: the same as the shop icons ([[Game Icon Pack]]), then bake the outline (`tools/icons/bake_outline.py`) and lay the game's stud texture on top in Studio.

**Built (2026-11-11). Not playtested by Claude; the user tests it with `bossmove`.**
- **Art:** the user ran 6 of the 8 prompts. Missing: `ChompBurst` and `Cracks`.
  - Sources are in `assets/Icons/BossOverlays/Sources/`.
  - Cleaned, split per piece and outlined (7 px on the big pieces, 5 px on debris) into `Baked/`; ids in `Baked/assets.json`.
  - The pieces: `IceChunk1-2`, `IceShard1-8`, `UpperJaw`, `LowerJaw`, `BiteMark`, `StoneSlab1-3` and `StoneRubble1-8`.
  - The bite mark came out with an orange rim, not croc green. It's kept as is.
- **Studio:** `ChopBar.Bar.Overlays` is the same size as `Track`. It holds:
  - `Templates`: hidden ImageLabels with an `Aspect` attribute (height / width).
  - The layer frames `Frost`, `Shell`, `Chomp` and `Debris`.
  - Under `Chomp`: the `ZoneFlash` frame and the authored `UpperJaw` / `LowerJaw` (the teeth bite 20 px into the track).
  - `ChopBar` uses **Global** ZIndexBehavior. To get the overlays above `Lip` (7) but under the cursor, these all moved up 10: `CursorLane`, `Cursor`, `Shield`, the timer and `SignatureBadge`. The hearts moved up 20 and `ResultLabel` went to 25.
  - The overlays use ZIndex 8 to 11.
  - The game's stud texture is not laid on the pieces, because an ImageLabel can't mask it to their shape.
- **Code:** `UIController/BossOverlays.luau`, driven from `ChopBar.applyRamp` (kind, values, center, strength), with timings in `BossOverlayConfig`.
  - A Block round passes `None`, so the overlays leave during Block rounds and come back after.
  - `Close` clears them at once.
  - A landing feeds the bar's existing shake.
  - Drop-in: a `ChompBurst` ImageLabel added to `Templates` is used automatically. `Cracks` isn't wired yet.
- **Follow-ups (user, 2026-11-11):**
  - The images took a moment to show the first time. `BossOverlays` now preloads every overlay ImageLabel with `ContentProvider:PreloadAsync` as the chop bar screen is created, at join.
  - "delete the move text with the emojis": the `SignatureBadge` (emoji + "Chomp!" / "Shell!" / "Frost!" by the bar) is deleted from Studio and `ChopBar`, with `BossConfig.Signature.Icons` and `BossFxConfig.Signature.BadgeTextStyle`. `Signature.Banners` stays: the server's notification and the Shell result text use it.

Sources: [Clear Heart mod](https://modrinth.com/mod/clear-heart), [Minecraft freezing hearts feedback](https://feedback.minecraft.net/hc/en-us/community/posts/360074983391-freezing-hearts-affect-your-max-health-not-your-actual-health), [Path of Exile life bar thread](https://vpn-erintek.duckdns.org/forum/view-thread/3922328), [Dead by Daylight status HUD](https://deadbydaylight.wiki.gg/wiki/Proficiency_Indicator), [Final Fantasy Petrify](https://finalfantasy.fandom.com/wiki/Petrify_(status)), [Bloodstained Stone](https://bloodstained.fandom.com/wiki/Stone), [UI feedback design](https://gamejuice.pages.dev/articles/ui-feedback-design).

Related: [[Boss Health Bar Reference]], [[Diamond Rock]], [[World Bosses]], [[Block Rounds]], [[Chop Minigame]]

## Boss name gradients and Enraged prefix (2026-11-12)
- Boss bar names now use real 3-stop vertical gradients (`BossBarConfig.Titles`, `title(top, center, bottom, stroke)`): Big Croc swamp greens, Boulder Crab orange to red, Frost Yeti white to blue, Diamond Rock cyan. The old hard two-colour split (`TitleSplit`) is gone, and names are no longer upper-cased (No All Caps In UI).
- When the boss is mad, `Body.EnragedTitle` / `EnragedTitleShadow` (Studio copies of Title, red `EnragedTitle` gradient) show "Enraged" before the name. The name keeps its own colours. `placeTitle` centres the pair from `TextBounds` divided by the on-screen scale. It hides again when `IsMad` clears (fight reset). The longest name fits: "Enraged Boulder Crab" is 791 px in a 960 px body.
- Overlay intros were cut to under 0.1 s (`IceDropSeconds`, `JawInSeconds`, `SlabDropSeconds`, `SlabStaggerSeconds`).
- The main signature delay is on the server: `triggerSignature` sends only the banner, and `ChopModifier` fires at the *next* round start in `scheduleNextRound`. This was handed to the boss-abilities session on 2026-11-12.
