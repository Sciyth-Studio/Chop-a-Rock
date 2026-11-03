---
description: 2026-10-29 pass to make the game easier for young kids - phone-only easier chop timing, left click to chop, short notifications with icons, a free first Master Chop after the tutorial, and a Huge Shroomy from the tutorial geode.
type: system
updated: 2026-10-29
---
# Kid Friendly Pass

Built 2026-10-29, not playtested yet. The idea came from the user talking to a 6-year-old, not from watching kids play. Big money numbers stay ([[Big Numbers Over Small Ones]]).

## What the user chose
- Easier chop timing on phones only (user: "might only be necessary for mobile"). PC and controller keep the old timing. Payouts are unchanged for everyone, so the [[Balance Model]] doesn't move. The proposed Bad 0.4x / Mid 0.7x payouts were not used.
- Short notifications for everyone, not only phones (one set of text to maintain).
- Left click to chop.
- Free first Master Chop and the beginner's-luck geode.
- Ground arrow or beam to tutorial targets: skipped. The [[Tutorial]] already draws ground chevrons and spotlights teleport buttons.

## Phone-only chop timing
- The client reports touch input with `Packets.ChopTouch` whenever `UserInputService.LastInputType` flips between Touch and keyboard, mouse or gamepad (`ChopController`). `RockService` stores it as the `TouchChop` player attribute (`ChopConfig.TouchAttribute`).
- `ChopZones.IsTouch(player)` reads it. `ChopZones.Bands`, `Classify` and `Position` take an optional `isTouch`. With touch they use `TouchZoneWidthMultiplier` 2.5 (normal 1.5) and `TouchCycleSeconds` 2.0 (normal 1.5).
- Every chop flow passes it: rocks (`RockService`), the Diamond Rock, Falling Geodes and geode cracking on the server; `ChopMeter`, the tutorial `ChopHint` and the `Spotlight` Good band on the client.
- Known gap, accepted by the user: a PC cheater could send `ChopTouch` true to get the wider zones.
- The flag is read live, so if a player switches device in the middle of a round, that one round can disagree with the server.

## Left click
- While the strike is bound, `ChopController` also listens to `UserInputService.InputBegan` for `MouseButton1`. It ignores clicks the game already handled (`gameProcessedEvent`, e.g. buttons). E, Space, R2 and the touch Chop button still work.
- The tutorial's keyboard prompt now says "Click" instead of "Press E" ("Click here", "Now! Click!", "Click in glow!").

## First Master Chop
- `RockService/FirstMaster.luau`. When the tutorial finishes (`TutorialService.Finished`), `Hints.FirstMaster` is set to 1 (armed) and a random 120-240 s timer starts. When a player who is still armed loads in, the timer restarts. Players who finished the tutorial before this update never get it.
- After the timer, their first Good-or-better chop on a normal rock becomes a Master Chop (cinematic, x3 pay). A natural Master Chop while armed also uses it up. Then `Hints.FirstMaster` = 2, it saves, and the player gets "Master Chop! Super rare!" at impact.
- Logged as the custom analytics event `FirstMasterChop` (value 1 = free, 0 = natural), not as an onboarding funnel step. The funnel logs the furthest milestone reached, so a step out of order would be logged for players who never got it.
- Settings: `MasterChopConfig.FirstMaster`.

## Beginner's luck geode
- `GeodeService/Cracking.luau`: while the tutorial is on Crack and the player has no Pets yet, the hatch is forced to `TutorialConfig.FirstPetKey` (Shroomy, Rare) at `FirstPetSize` (Huge). This only happens if that geode can drop it. Pity is skipped for that hatch. `PetService:Grant` takes an optional size.
- Size is looks-only (`PetValue` ignores it), but Shroomy makes $5/s against Sprout's $2/s.

## Short notifications
- `NotificationService:Notify(player, kind, message, icon?)` and the client `NotificationController:Notify(kind, message, icon?)` take an optional image id. `Packets.Notify` carries it as a third string ("" = none).
- The Studio template `StarterGui.Notifications.Template` has an `Icon` ImageLabel (46x46, hidden by default). `Screens/Notifications` puts it `IconGapPixels` (10) left of the centred text, using `TextBounds / AbsoluteSize` so it follows the screen scale. It fades with the text. Pinned tutorial lines never show an icon.
- Rewrites: "Bag full! Sell Pets" (backpack icon), "+1 {Pet}" (Pet icon), "+{n} {Geode}", "Crack it at base!", "Index done! +10% Money", "Rebirth ready!", "{Rock} unlocked!" (rock icon), "Not enough money!" (money), "New pedestal!", gifts "{gift} from {name}!" / "Gift sent to {name}!" / "{name} says thanks!" (gift icon), "Master Chop by {name}!", "{name} got {rarity} {Pet}!", leaderboard "#3 in {board}!" / "Passed {name}! #3" (crown), Falling Geodes ("{n} Geodes in {zone}! Chop one!", "Geodes: {zone} 3/5 2:30"), Diamond Rock ("Diamond Rock in {zone}!", "Diamond Rock full!", money icon on the payout), weather ("{event} is here! {modifier} x2", "{event} is over"), training sign ("Need Rebirth 2!", "Training maxed!", "Try again!").
- Left as they were: admin and global announcement text, Robux shop details text, "Welcome to the {zone}!", tutorial pinned lines.
