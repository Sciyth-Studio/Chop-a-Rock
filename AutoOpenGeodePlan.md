# Auto-open geodes gamepass: plan

Status: **approved 2026-10-24, not built.** The user decided every row of section 1 the same day. The first answer, "runs anywhere", was replaced: auto-open is a hands-off mode at your own crack pit. Every number marked *draft* goes in config and is checked in a playtest. Studio UI (the prompt, the stop button) is built with the `studio-ui` skill and shown to the user before it's final.

## 1. Decisions

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| A1 | **Where does it run?** | **Only at your base pit (user, 2026-10-24):** "you should get prompted to auto open when you walk up to your pit. it doesn't run anywhere, it just lets you go hands off while trying to open your geodes at the pit." Walking away stops it. | It replaces the hold-prompt-and-time-the-meter loop, not the trip to the pit. You still watch your Roks hatch. |
| A3 | **Random hit quality: which odds?** | **The balance model's "typical kid" mix, no Master Chops (user, 2026-10-24):** Bad 5% / Mid 15% / Good 40% / Great 25% / Perfect 15% (model Inputs rows 4-8), which averages +0.095 luck. | The model already assumes this mix for every geode check, so balance doesn't move. A player who keeps hitting Perfect by hand (+0.25), or lands a Master (+1), still does better. |
| A4 | **Speed and display** | **The normal reveal plays for every crack, and the next crack starts as soon as it ends** (follows from A1). No new timer: the pit's existing lock (reveal + `RecrackDelaySeconds`) sets the pace, about 4.2 s a crack on average. | You're standing at the pit, so the full reveal and its camera are fine. It's about 1.3x faster than by hand (no prompt hold, no camera in and out, no waiting for the meter). |
| A5 | **Auto-sell?** | **No (user, 2026-10-24).** A full Backpack (100 Roks) stops auto-open. | Keeps the pass simple. |
| A7 | **Off on rejoin?** | **Yes** (follows from A1). It only runs while you stand at the pit, so there's nothing to resume. | |
| A2 | **Does it buy geodes too?** | **No, only the geodes you own (user, 2026-10-24).** It stops with "All geodes opened!" when they run out. (The earlier "buys and cracks" answer was for the run-anywhere design.) | Buying stays at the lobby shop; auto-open only replaces the cracking. |
| A6 | **Price** | **Game pass, 199 R$ (user, 2026-10-24).** Not a timed developer product. | Permanent, like 2x Luck. Simulator auto-hatch passes usually sell for about 150-400 R$. |

## Read first
`AGENTS.md`, `Vault/Index.md`, `GeodeSystemPlan.md`, `GeodePitySystemPlan.md`, and the vault notes `Geode Shop`, `Bases`, `Sell Shop`, `Balance Model`, `Balance Pass Oct 18`, `Hatch Reveal Reference`, `Tutorial`, `Movement Lock`, `UI Feel`. Code: `GeodeService` (`init`, `Cracking`, `Effects`, `Luck`, `Types`), `ChopController` (how it handles `ChopResult` with no minigame open), `HatchController`, `PromptController` (the `OwnedPrompt` tag), `LuckConfig`, `GeodeConfig`. Skills: `studio-ui`, `studio-playtest`.

## Why
The user has wanted an auto-open pass since the 2026-10-18 balance pass. Spam hatching was declared fine then, provided each auto-open rolls a random hit quality. Sell value was cut to 60 s, and pity was built so it works with auto-open. This plan turns those decisions into a build.

## What is already decided (do not change)
- **Spam hatching is fine.** A geode costs about 2-4 s of income at a zone's best rock ([[Balance Pass Oct 18]]).
- **Each auto-open rolls a random hit quality** instead of playing the chop meter (user, 2026-10-18).
- **Auto-open cracks through the same code as a manual crack** (`GeodeService/Cracking`), so pity, weather modifiers, the Index and Secret announcements work unchanged. Faster cracking makes the Snow Legendary guarantee (35 cracks) come more often. That is by design and within 2x expected (`GeodePitySystemPlan.md` § 5).
- **Sell value is 60 s of income** (`PetConfig.SellValueSeconds`), so hatch-and-sell is below 100% of the geode price in every zone ([[Sell Shop]]).
- The Geode Stand reference's Auto-Hatch / Multi buttons were deferred to Master Game Plan §10. §10 lists 2x Luck as the only planned game pass, so this plan adds the second one there (build step 5).
- The shop and the reveal show base odds. Auto-open doesn't change the odds tables, only which hit quality feeds luck.

## 2. Player flow
1. **Walk up to your pit** with geodes. Beside the usual "Crack (12 left)" prompt there's a second one, **Auto Open**, on its own key (*draft* F on keyboard; a second prompt button on touch and gamepad).
   - No pass: "Auto Open" with the Robux price. Triggering it opens the game pass prompt.
   - Pass owned: hold it (the same `PromptHoldSeconds` as Crack) to start.
2. **While running:** the pit cracks a geode for you with a random hit quality. The normal hit effect, reveal, New! / Guaranteed! / modifier tags and Secret announcement all play as usual. When the reveal ends, the next crack starts. A small **Stop Auto** button sits on screen (bottom centre, *draft*) with a count ("Auto Open · 12 opened"). Both prompts hide while it runs.
3. **Stops** (a notification says why):
   - you tap Stop Auto,
   - you walk out of range (*draft* 14 studs from the pit, a little more than the prompt's range),
   - out of geodes ("All geodes opened!"),
   - Backpack full ("Bag full! Sell some Roks"),
   - too weak for the next geode ("Get stronger! Need X Strength"), instead of clinking again and again,
   - you start a chop, teleport, fire a cannon, rebirth or leave.
   The prompts come back once the last reveal ends.

## 3. Rules
- **Pace:** one crack, then the existing lock (`lockedUntil`: reveal time + `RecrackDelaySeconds`), then the next. Plus `AutoOpenConfig.StartDelaySeconds` (*draft* 0.3 s) for the strike to read. Nothing from the client sets the pace.
- **Which geode:** the same pick as the Crack prompt (`Cracking.PickGeode`, highest zone first).
- **Quality** is rolled on the server from `AutoOpenConfig.QualityWeights` (A3). No Master roll. Luck = `Luck.Total(context, player, quality)`, so rebirth luck and 2x Luck apply as normal.
- **Counts as a real crack:** a geode is taken, a Rok granted, pity counters move, the Index fills, weather rolls a modifier, Auto Equip works as usual. **Doesn't count:** Perfect Chops (`StatsService:RecordChop` is skipped, so the leaderboard stays about skill).
- **Tutorial:** no Auto Open prompt while the tutorial runs.
- **Admin "Next Hatch: <Rarity>"** applies to the next auto crack too.

## 4. Architecture

### Config (`src/shared/Config/AutoOpenConfig.luau`, new)
```
GamepassId = nil,                 -- set once the pass is made
QualityWeights = { [Bad] = 5, [Mid] = 15, [Good] = 40, [Great] = 25, [Perfect] = 15 },  -- model mix
StartDelaySeconds = 0.3,          -- draft
RangeStuds = 14,                  -- draft, stop distance from the pit
PromptKey = Enum.KeyCode.F,       -- draft
RunningAttribute = "AutoOpening", CountAttribute = "AutoOpenCount",
```

### Server (`GeodeService`)
- **Split `Cracking.Release`** into the timing half and a new `Cracking.Finish(context, player, session, random, quality, isAuto) → number` (lock seconds). `Release` turns the client's elapsed time into a quality, rolls Master and `RecordChop`, then calls `Finish`. Auto calls `Finish` directly with the rolled quality and `isAuto = true` (skips Master and `RecordChop`). Everything else (pity, grant, refund, effects, `GeodeHatched`, the Secret announcement) is the same code, so pity works with no extra code, as `GeodePitySystemPlan.md` promised.
- **`Cracking.Begin`** gains `isAuto`: it sets up the session and shows the geode but doesn't fire `ChopMinigameStart`, so the camera never enters the chop view.
- **`AutoOpen.luau`** (new child): `AutoOpen.Next(context, player, spot, random) → (session?, stopReason?)`. It checks the pass, the tutorial, the range, geodes left, the Backpack and strength, then calls `Begin` with `isAuto`.
- **`init.luau`**: a second pit prompt (`AutoPrompt`, tagged `OwnedPrompt` like the crack prompt, its own `KeyboardKeyCode`). Triggering it marks the player as auto-opening, sets `AutoOpening`, and starts a crack. After each crack's lock ends (the existing `task.delay` in the `ChopRelease` path, shared with auto), the next one starts if the player is still auto-opening. A Heartbeat check every 0.5 s stops a player who's out of range. Stopping clears the flag and the attributes; the reveal already playing finishes. `refreshPit` hides both prompts while auto runs. `SetAutoOpen` binds only Stop.
- **Ownership:** `context.GamepassOwners` becomes `context.Passes[player] = { Luck: boolean, AutoOpen: boolean }`, cached on load with `UserOwnsGamePassAsync` (pcall; a failed check is treated as not owned and rechecked once 30 s later). A `MarketplaceService.PromptGamePassPurchaseFinished` handler sets the cache after a purchase, for both passes (the 2x Luck pass doesn't have one yet). `Luck.luau` reads `Passes[player].Luck`. The prompt's text comes from the cache: "Auto Open" or "Auto Open (199 R$)".
- **Other systems that stop it:** `RockService` chop start, `TeleportService`, `CannonService` and `RebirthService` already call `GeodeService:EndSession`. Make `EndSession` stop auto too.

### Player data
- None. Auto-open is session state.

### Networking (`Packets.luau`)
- `StopAutoOpen = Packet("StopAutoOpen"):RateLimit(2, 1)`. The only thing the client can send. Starting is the pit prompt (server `Triggered`, so the server already knows who and where).
- No new hatch packet: auto cracks use `ChopResult` and `GeodeHatched` as they are.
- Running state reaches the client as the `AutoOpening` and `AutoOpenCount` player attributes.

### Client
- `ChopController` / `HatchController`: check that a `ChopResult` with no open minigame plays the strike and pit effects and doesn't open the meter. If it can't, add a small `isAuto` path that plays the strike animation only (`Utils/ChopAnimation`).
- `Screens/AutoOpenButton.luau` (new, non-modal): shows while `AutoOpening` is set, with the count. Its button fires `StopAutoOpen`.
- When the player doesn't own the pass, triggering the Auto prompt calls `MarketplaceService:PromptGamePassPurchase` (from `PromptController`, which already styles owned prompts).

### Studio (with the `studio-ui` skill, house text style; save the place)
- The Auto prompt uses the custom prompt style the Crack prompt already has. Check that two prompts on one attachment both show and don't overlap; if they do, move `AutoPrompt` to a second attachment beside `GeodeSpot`.
- `StarterGui.AutoOpenButton`: a pill with "Auto Open · 12 opened" and a red Stop button. Show the user the look.

### Admin
- "Auto Open Pass" (on/off, Studio only): fakes ownership for this session so it can be tested before the pass exists. Alias `autopass`.

## 5. Rate limiting and anti-exploit
- **The client never sends anything that affects a crack.** It triggers a server-side prompt (range and owner checked by Roblox and by `BaseService:GetCrackSpot`) and can send Stop. Quality, timing and the roll are all on the server.
- The server checks the pass at the prompt and before every crack. The pass cache is server-side only.
- Pace comes from the existing per-player lock. Retriggering the prompt can't stack two loops: a player already auto-opening is ignored, the same as `sessions[player]` today.
- Range is checked on the server from the character's position, so standing still client-side while teleported elsewhere doesn't help.
- The crack keeps today's rule: no yield between the geode change, the grant and the pity write.

## 6. UI states (summary)

| Where | State | Shows |
| --- | --- | --- |
| Pit prompt | No pass | "Auto Open (199 R$)" next to "Crack (12 left)" |
| Pit prompt | Pass, idle | "Auto Open" next to "Crack (12 left)" |
| Pit prompt | Running | Hidden (both prompts) |
| Pit prompt | No geodes / tutorial | Hidden |
| Screen | Running | "Auto Open · 12 opened" pill with Stop |
| Notification | Stopped | "All geodes opened!", "Bag full! Sell some Roks", "Get stronger! Need X Strength" |

## 7. Balance check ([[Balance Model]] v9)
- **Odds per crack: unchanged from the model.** The model's luck already uses timing +0.095 (Collection rows 5-9), which is exactly A3's mix. With no Masters, an auto crack is very slightly below a typical manual player (manual Masters are about 1.3% of cracks).
- **Cash per hatch: unchanged**, so hatch-and-sell is still not a loop. Worst cases (10 rebirths, worst weather): Forest 70%, Desert 83%, **Jungle 96%**, Ocean 43%, Snow 46%. Selling stays a manual trip to the lobby.
- **Pace:** the average reveal at Forest odds is about 3.05 s (Common 2.7 s up to Secret 5.45 s), plus 0.12 s pre-impact, 1 s recrack and 0.3 s start: **about 4.5 s a crack, against about 5.5 s by hand**. Cash allows faster in every zone (1.6-3.9 s a geode, Collection column I against the geode price), so auto-open is speed-bound everywhere. It's a convenience, not a multiplier.
- **Roks page time** (model minimum 5 min): expected hatches × 4.5 s = **Forest 60, Desert 37, Jungle 25, Ocean 12, Snow 8.9 min** (model's cash-only figures: 20.4 / 10.7 / 5.5 / 8.7 / 6.4). All pass with room.
- **Pity under auto-open:** in the Snow the Legendary guarantee (35 cracks) comes within about 2.6 minutes of standing at the pit.
- **Model change:** small. Add an "Auto-open" row to Collection (seconds per auto crack and the page-time floor). Save as v10 via Excel COM, with a "Changes in v10" line in Read Me. Nothing in Checks changes.

## 8. Build order (each step ends checkable)
1. **Split `Cracking.Finish` out of `Release`, add `isAuto` to `Begin`.** No behaviour change for manual cracks. Check in Play: a manual crack, a forced Secret, a pity crack, a too-weak clink and a full Backpack all behave as before.
2. **Config + pass cache + admin fake pass.** Check by value: `Passes` fills on load; `PromptGamePassPurchaseFinished` flips it; 2x Luck still reads correctly.
3. **Auto prompt + loop.** Check with the admin fake pass: the prompt shows only with geodes and outside the tutorial; cracks chain with the normal reveal; each stop reason works (Stop, walking away, out of geodes, bag full, too weak, chop, teleport, rebirth); no Perfect Chops added; pity counters move. 1,000 simulated quality rolls land near 5/15/40/25/15.
4. **Stop pill + prompt look** in Studio. Show the user, then wire the screen.
5. **Make the pass** (Sciyth Studio group, Open Cloud or the Creator Dashboard), set `AutoOpenConfig.GamepassId`, test a real purchase prompt in a published test place. Docs: balance model v10; a `Systems/Auto Open` note in the vault (linked from [[Geode Shop]]); Master Game Plan §10 Gamepasses gains "Auto Open"; remove the To Do line once built and checked.
6. `./scripts/check.ps1` passes. The user playtests.

## 9. Risks and gotchas
- **Two prompts on one pit:** custom-style prompts on the same attachment can stack. Check before building the look (section 4, Studio).
- **`ChopResult` with no minigame:** the client may expect an open chop session. Check in step 1 before relying on it.
- **Jungle margin:** 96% worst-case hatch-and-sell. Re-run the model after any Jungle odds or price change.
- **Policy:** the pass is a convenience; geodes are bought with in-game cash and the odds are unchanged and shown. If Robux geodes are ever sold, auto-open must follow the same disclosure.

## Out of scope
Auto-open away from the pit (A1), buying geodes from the pit (A2), auto-sell (A5), a shorter reveal for Commons, auto-open for Geode Fall geodes, multi-open (several geodes per crack), and a timed or trial version of the pass.
