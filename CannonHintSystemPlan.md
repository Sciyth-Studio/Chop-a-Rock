# Cannon hint (staggered tutorial): plan

Status: **built 2026-10-20** (see `Vault/Systems/Tutorial.md` § Staggered hints). Changes while building: admin presets and Reset clear `Hints` instead of setting Done, so test presets show the hint; any cannon landing (even before the hint starts) sets Done; the welcome notice only shows if the hint was running. Numbers marked *draft* go in config and are checked in a playtest.

## Why staggered
The first-time tutorial ends at 10 Strength and $150. The Desert Cannon needs 500 Strength and $80K (`CannonConfig`). Rebirths need `100 x 125^(n-1)` Strength (`RebirthStats`): 100, 12,500, 1.56M, which lines up with the zones' first rocks (Desert 500, Jungle 62,500). So run 1 is the forest and the run after rebirth 1 is the Desert. Teaching the cannon in the first tutorial would explain something they can't use for a long time, and firing an empty cannon only opens the shop ("Buy a cannon to fire!"). So the cannon gets its own short guide that starts after the first rebirth, once the Desert Cannon unlocks, and stops after the first launch (user, 2026-10-20: "have the hint appear post rebirth 1").

## Read first
`AGENTS.md`, `Vault/Index.md`, vault notes `Tutorial`, `Cannon Shop`, `Teleport Bar`, `Shop Pads`, `Rebirth Gated By Strength`, and `TutorialSystemPlan.md`. Skills: `studio-ui`, `studio-playtest`.

## Rules
- Taught once per profile. Only the Desert Cannon. Later cannons work the same way, so they get a plain notification when they unlock and no guide.
- **Never blocks anything.** No pad locks, no chopping gate, no hidden HUD, weather and Hot Streak run as normal. It only draws: pinned text, guide arrows, the marker and spotlights.
- Never runs while the first-time tutorial runs (`Tutorial.Step < Done`). It can't happen anyway (the tutorial ends at 10 Strength), but admin presets and Reset could cause it.
- Pauses during cutscenes the same way the tutorial does: `HatchController:IsPlaying()`, `HatchReveal`, `Letterbox`, and also while a cannon flight runs.

## Stages

| # | ID | Starts when | Pinned title / detail | Guide | Moves on when |
|---|---|---|---|---|---|
| 0 | `Locked` | new profile | none | none | `Rebirths >= 1` and `Strength >= 500` (the Desert Cannon's `StrengthRequired`) |
| 1 | `Save` | first unlock | "Desert Cannon unlocked!" / "Save up: $12.4K/$80K" | none (a goal, not a walk) | `Cash >= 80K` |
| 2 | `Buy` | can afford it | "Buy the Desert Cannon!" / "Click Shops at the top!" → "Click Cannon to teleport there!" → buy-button spotlight | Teleport spotlight, then arrows to the `CannonShop` pad, then `Spotlight` on `CannonShop…CannonDesert` buy button | `Cannons.Desert` owned |
| 3 | `Fire` | owns it | "Fire the cannon!" / "Press E" (from the prompt: "Tap Fire", gamepad key) | Arrows + marker to `LobbyCannon.PromptAnchor`; `Base` teleport spotlight if it saves 40+ studs (same rule as the tutorial) | the server lands the player from the cannon |
| 4 | `Done` | first landing | one normal notification "Welcome to the Desert!" | none | none |

The stage is decided again every check, like the tutorial: **later milestones win** (owns a cannon → `Fire`, even if the player bought it while still in `Save`). When the cash goal is lost the stage goes back (`Buy` → `Save`, when Cash < price and the cannon isn't owned).

Unlocking (`Locked` → `Save`) plays the tutorial's step sound and a one-off "Desert Cannon unlocked!" notification.

### Rebirth
- **Before rebirth 1 the hint never starts.** A player who skips the first rebirth and reaches 500 Strength in run 1 gets nothing until they rebirth. They've found the Desert on their own by then anyway.
- **After rebirth 1** the player starts from 0 and passes 500 on the way to the next rebirth at 12,500, so a later rebirth almost never lands mid-hint. If one does (Strength and Cash reset in `Save` or `Buy`), the hint goes quiet while Strength is under 500 and keeps its stage. `Fire` stays shown, because cannons are kept and firing never checks Strength.

## Data
- New `PlayerData.Hints: { [string]: number }`, with `Data`, `Template` (`{}`), `Validate` and `Migrate` together. The key is `Cannon`, the value is the stage. A table so later staggered hints (for example the first rebirth or the Index) don't need a new field each.
- Migrate: any profile that owns a cannon gets `Hints.Cannon = Done`, so players who already found it never see the guide. Other profiles start at `Locked`, and the first check moves a player with `Rebirths >= 1` and `Strength >= 500` on to the right stage.
- `DataService:ResetData` clears it; admin presets set `Done` unless the preset is fresh; add `Hints` to admin snapshots.

## Server: `CannonHintService` (new)
- Shared `CannonHint.luau` (beside `Tutorial.luau`): stage numbers, `IsValid`, `Stage(data)`, which works out the stage from Strength, Cash, `Cannons` and the stored value, used by both the server and the client so they agree.
- The service checks every player on a 0.25 s timer (same as `TutorialService`) and writes `Hints.Cannon` when the stage changes. Skips players whose tutorial isn't Done.
- `CannonService` gets a `Landed` signal (`Signal<Player, string>`), fired after the landing `PivotTo`. The hint service listens to it and sets `Done` the first time. The landing is checked on the server, so a client can't mark the hint finished early, and only a real flight finishes it.
- Funnel: `AnalyticsService:LogCustomEvent` `CannonHint` with value = stage, once each (unlock, buy, first fire), so the drop-off between unlock and first launch can be seen. *Not* `LogOnboardingFunnelStepEvent`, which is the first tutorial's.
- Skip: packet `CannonHintSkip` → `Done` and custom event `CannonHintSkipped` (value = stage).

## Client: inside `TutorialController`
The hint reuses the tutorial's parts as they are: pinned notifications, `Guide`, `Spotlight`, `Teleports`, `Layout`, `Targets`. Building them again in another controller would duplicate ~800 lines. So:
- New child `TutorialController/CannonHint.luau`: for the current stage, returns the title, detail, target (`Targets` gains `CannonShopPad` and `LobbyCannon`), the spotlight button and the teleport id.
- `init` runs the hint track when `Tutorial.Step == Done` and `CannonHint.Stage` is `Buy` or `Fire` (and `Save` for the pinned line only). It doesn't hide `MenuButtons` or the pills (that part stays tutorial-only).
- `Teleports.For(step, …)` gets a sibling `Teleports.ForDestination(id, target, verb)` so the hint can ask for "Cannon" (a fan option, already in `TeleportConfig.ShopFan.Options`) or "Base". `For` calls it after mapping the step.
- `Layout` keeps the pinned text under the Teleport Bar while either track runs.
- Skip: the `TutorialHud` Skip button (with the "Sure?" confirm) shows during `Buy` and `Fire`, and sends `CannonHintSkip`. Not shown during `Save`, which is a single line.

## Config (`TutorialConfig.CannonHint`, drafts)
`Cannon = "Desert"`, `WelcomeText = "Welcome to the Desert!"`, `UnlockText = "Desert Cannon unlocked!"`. The Strength and price goals are read from `CannonConfig`, so changing the cannon moves the hint.

## Testing (Play, by value; the user plays the look)
1. Fresh profile through the tutorial, admin set Strength 500 with 0 rebirths: nothing. Rebirth once, set Strength 500: `Save` pins with progress; at Cash 80K → `Buy`; teleport spotlight lands on Shops → Cannon; buy-button spotlight centred on `CannonDesert`; buy → `Fire`; arrows end at the cannon; fire → land → `Done`, welcome notice, nothing pinned.
2. Buy without the guide (admin cash, walk to the shop in `Save`) → jumps to `Fire`.
3. Rebirth again while in `Buy` → hint quiet; back to 500 → shows `Buy` or `Save` by cash.
4. Old profile with a cannon → `Done` on load, no pin.
5. Skip in `Buy` → `Done`, custom event logged.
6. Nothing locked during the hint: chop, other shops, weather.
7. `./scripts/check.ps1` passes.

## Out of scope
Guides for the Jungle, Ocean and Snow cannons; per-zone cannon models; any change to cannon prices or the first tutorial's steps.
