# Tutorial (first-time guide): plan

Status: **built 2026-10-16** (see `Vault/Systems/Tutorial.md` for what shipped and what was tested). Changes from this plan while building: tutorial text is two pinned notifications (user, 2026-10-16) instead of a card; the spotlight is Rectangle; Skip asks "Sure?" first. Numbers marked *draft* go in config and are checked in a playtest. Built from the user's onboarding brief (one objective at a time, always visible, impossible to misread, impossible to break), fitted to this codebase.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` §05 (The first player experience), and the vault notes `Bases`, `Shop Pads`, `Geode Shop`, `Pedestals`, `Weather`, `Teleport Bar`, `UI Feel`, `Movement Lock`. Skills: `studio-ui`, `studio-playtest`.

## Core loop
`train at the base stand → Strength → chop rocks in the forest → Cash → buy arms (2x training) and geodes → crack the geode at the base → Rok on a pedestal → $/s → stronger rocks → rebirth`

The tutorial runs this once, end to end: training, chopping, the first arms (felt straight away on a second short training step), the first geode, the first Rok earning money. That teaches both progression axes, per the [PROPOSED] line in §05.

## Pacing rule (user, 2026-10-16)
As few repeated actions as possible. A training step lasts **at most 5 seconds**. A chopping step needs **at most 3 rocks**. Training for its own sake comes after the tutorial.

## Values (applied 2026-10-16, drafts)

| Value | Was | Now | Why |
| --- | --- | --- | --- |
| Stone `BasePayout` (`RockConfig`) | $40 | **$50** | Fits the 4x payout rule (50 → 200 → 800) |
| Wood Arms `Price` (`ArmConfig`) | $300 | **$150** | First Perfect ($87) + 2 Good ($50) = 3 rocks |
| Forest Geode `Price` (`GeodeConfig`) | $500 | **$150** | At 10 Strength a Good chop breaks a Stone in one hit: 3 Good or 2 Perfect |
| Forest Geode `StrengthRequired` | 10 | 10 | Kept: it is what makes step 4 matter |

Starting Strength, rebirth, Boulder and the training stands are unchanged. Known knock-on: Wood → Stone Arms is now a 16x price jump ($150 → $2,400) against the ~8x rule; judge it in a playtest (the other option is ~$1,200).

How the numbers work: a rock has `StrengthRequired x 4` health, damage per hit is `Strength x quality` (Good 1, Perfect 1.75), and the payout is shared across hits. Stone `StrengthRequired` went 2 → 4 on 2026-10-17 (user), so it has 16 health: at 4 Strength that is 4 Good hits (3 with the forced Perfects on the first Stone); at 10 Strength 2 Good hits or 1 Perfect.

## What the tutorial watches
Progress lives in the `PlayerData` replica, not in Player attributes, so the server watches data paths and the client reads them through `DataController:Observe`.

| Path | Start | Milestone |
| --- | --- | --- |
| `Strength` | 0 | 4 (step 1), 10 (step 4) |
| `Cash` | 0 | $150 (steps 2 and 5) |
| `ArmTier` | 1 | 2 = Wood Arms bought |
| `Geodes.Forest` | nil | Holds a geode |
| `Pets` | {} | First Rok hatched |
| `Pets[id].Slot` | nil | Rok on a pedestal (`AutoEquip` is on by default, so it follows the hatch) |
| `Rebirths` | 0 | First rebirth = last funnel step (retention) |

New field: `Tutorial = { Step: number, Taps: number }` in `PlayerData` (`Data`, `Template`, `Validate` together). Template `Step = 1`. Existing players are moved straight to `DONE` on load (any `Pets`, `ArmTier > 1` or `Rebirths > 0`), so current players never see it.

## Steps

| # | ID | Card text | Subtitle / progress | 3D target | Advance condition | Locked |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `TRAIN` | Break the boards! | Bar `Strength x/4` (4 reps, 4 s) | Own plot's `TrainingStand` | `Strength ≥ 4` and ≥ 1 rep made this step | Chopping, every shop pad, Teleport Bar, menu buttons |
| 2 | `CHOP` | Chop rocks for cash! | Walking: "Follow the arrows"; near a rock: "Hold [key]… let go on gold!"; after the first break: bar `$x/$150` | Nearest Stone | `Cash ≥ 150`. First break is a guaranteed Perfect with full fanfare (§05) | Shop pads, Teleport Bar |
| 3 | `BUY_ARMS` | Buy new arms! | "Walk onto the pad", then spotlight on the Wood Arms buy button | `ArmShop` pad | `ArmTier ≥ 2` | Other pads (red wall "🔒 Arms first!") |
| 4 | `TRAIN_AGAIN` | Train with your new arms! | Bar `Strength x/10` (3 reps at +2, 3 s) | Own plot's `TrainingStand` | `Strength ≥ 10` and ≥ 1 rep made this step | Chopping, shop pads |
| 5 | `CHOP_AGAIN` | Chop rocks for cash! | Bar `$x/$150` (≤3 rocks, one hit each) | Nearest Stone | `Cash ≥ 150` | Shop pads |
| 6 | `BUY_GEODE` | Buy a geode! | Spotlight on the Forest Geode buy button | `GeodeShop` pad | `Geodes.Forest ≥ 1` | Other pads |
| 7 | `CRACK` | Crack it at your base! | "Hold [key]… let go on gold!" | Own plot's `GeodeSpot` | `Pets` has an entry | Everything but the pit prompt |
| 8 | `COLLECT` | Grab your Rok's cash! | "Step on the green pad" | That Rok's pedestal `EarningsPad` | That slot's earnings are collected | — |
| 9 | `FINAL` | You're ready! Go chop! | none | none | `FinalHoldSeconds` (draft 3 s), then `DONE` | Everything unlocks |

Nine steps, one more than the brief's 5–8: it is the only way to teach arms and geodes while keeping every repeated part this short.

Ordering rules in `check(player)`:
- Later milestones win: a player holding a geode jumps to `CRACK`, one with a placed Rok to `COLLECT`.
- Out of order never advances: training steps need a rep made during the step, so an admin preset or leftover strength doesn't skip them.
- Moving back: if `Cash` drops below $150 on `BUY_ARMS` or `BUY_GEODE`, it goes back to the chop step before it. If the geode disappears without a hatch, back to `BUY_GEODE`.
- Rejoin halfway: `Step` is saved, then re-checked against the data on load.
- Mostly Mid or Bad chops can need a 4th rock on step 2; the guaranteed first Perfect keeps everyone else at 3.

## Architecture

| Piece | Where | Role |
| --- | --- | --- |
| `Tutorial` | `src/shared/Tutorial.luau` | Step constants, `Text`, `Funnel` names, gates (`IsActive`, `CanChop`, `IsPadOpen(screenKey)`, `HidesUi`), target finders that return nil until streamed in |
| `TutorialConfig` | `src/shared/Config/TutorialConfig.luau` | `TrainGoal = 4`, `TrainAgainGoal = 10`, `CashGoal = 150`, `FinalHoldSeconds`, chevron and path numbers, sounds, colours |
| `TutorialService` | `src/server/Services/TutorialService.luau` | The authority: owns `Tutorial.Step` through `DataService:Set`; `SetStep` moves forward except for the move-back rules; logs `AnalyticsService:LogOnboardingFunnelStepEvent` in a `pcall` once per new step; handles `TutorialAction` (`Reached`, `Skip`); logs a `TutorialSkipped` custom event |
| `TutorialController` | `src/client/Controllers/TutorialController/` (`init`, `Path` for pathfinding, `Guide` for chevrons/arrow/label/highlight, `Spotlight` for UI focus, `Locks` for red walls) | All visuals, all local |
| `Tutorial` screen | `StarterGui.TutorialHUD` (`Card`, `Hint`, `SkipButton`) + `UIController/Screens/Tutorial.luau` | The objective card, built in Studio per `studio-ui` |
| Packet | `TutorialAction = Packet("TutorialAction", Packet.String):RateLimit(5, 1)` | Client → server, only for what the server can't see |

On purpose, against the brief:
- The step lives in the replica (`Tutorial.Step`), not a Player attribute: AGENTS.md says state goes through Replica, and it saves for free.
- No header comments in scripts (AGENTS.md forbids comments). What connects to what goes in `Vault/Systems/Tutorial.md`.
- Packet instead of a RemoteEvent.

Hooks in existing systems (gate calls only):
- `RockService`: no chop session while `Tutorial.CanChop` is false; the first `Basic` break in `CHOP` is forced Perfect.
- `TrainingService`: increments `Tutorial.Taps` per rep on `TRAIN` and `TRAIN_AGAIN`.
- `ShopPad` component + `Shop` / `GeodeStand` screens: closed pads don't open.
- `TeleportBar`, `MenuButtons`, `WeatherPill`, `DiamondRockPill`, `HotStreakBar`, `RobuxShop`, `TrainingHint`: hidden while `HidesUi` (and re-hidden if something shows them).
- `RockService/Rush`, `DiamondRockService`: skip a player mid-tutorial.
- `RebirthService`: the first rebirth logs the last funnel step (for skippers too).

## Weather (user: ignore it if possible)
Weather runs on a shared server clock, so it can't be switched off for one player, but everything it does to a player can be:
- `WeatherService:RollStormRock` takes the player and returns nil while they're in the tutorial, so their rocks never spawn as storm rocks.
- `rollCatches` skips tutorial players (no surprise Rok catches mid-step).
- `RollHatchModifier` returns nil for the tutorial crack, so the first Rok is a plain one.
- `WeatherController` skips the lighting look and VFX locally while the tutorial is active, and applies the current one at `DONE`. `WeatherPill` is hidden.

## Visuals

**Objective card.** A dark translucent strip, top centre: the title, then either a subtitle or an `x/goal` bar, never both. On a step change it pops (UIScale 0.9→1, Back Out, 0.25 s) and ticks; `FINAL` plays a fanfare. The text adapts to the device, uses the prompt's real `KeyCode`, and is redrawn on `LastInputTypeChanged`. A Skip button shows until `FINAL`. Text uses `TextStyleConfig` styles with no all caps, so the brief's caps examples become "Train first!", "Arms first!".

**3D guide that follows a path.**
- `Path.luau` uses `PathfindingService:CreatePath` (agent radius 2, height 5, can jump; draft spacing 3).
- It computes from the character to a standing spot in front of the target, not the target's centre, which can sit inside a model.
- It recomputes every ~1 s (draft), when the player strays more than ~6 studs from the path, and when the target changes.
- `ComputeAsync` runs on its own thread with the last good path kept, so the arrows never freeze or flicker while it works.
- If there is no path (`NoPath`), it falls back to a straight line and tries again.
- Chevrons are white Parts with a black outline, spaced ~3.2 studs along the waypoint line. They scroll toward the target at ~6 studs/s, turn at corners, sit on the ground by raycast, and stop ~9 studs from the target.
- There is a pool of 36 chevrons; unused ones are parked at y -500.
- Above the target: a big bobbing arrow, an `AlwaysOnTop` label ("Stand", "Stone", "Arms", "Geode", "Pit", "Cash") and a soft pulsing Highlight.

**UI focus: SpotlightUI** ([docs](https://vvshenok.github.io/SpotlightUI/), [GitHub](https://github.com/Vvshenok/SpotlightUI), MIT, by Vvshenok / Interactive Studios). It dims the screen (overlay 0.6) except a cut-out around the target. The cut-out tracks the target every frame and can pulse. It locks ancestor ScrollingFrames during a step, and shows an edge arrow when the target is off screen.
- **Install:** vendored unmodified in `vendor/SpotlightUI` from its latest GitHub release, with its `LICENSE` and the commit noted, and mapped to `ReplicatedStorage.SpotlightUI` in `default.project.json`. `vendor/.luaurc` already turns off type checking there.
- **Janitor:** the module ships its own Janitor and Signal inside its folder. AGENTS.md asks for agreement before adding Janitor, but here it is only internal to the vendored module and the game's own code keeps using Trove.
- **Wrapper:** `TutorialController/Spotlight.luau` owns one `SpotlightUI.new()` for the whole tutorial and drives it with `FocusUI` / `Hide` from `render()`. It does not use the module's own `SetSteps` / `Next`, because the server decides the step.
- **Where it's used:**
  - UI steps only: the Wood Arms buy button (step 3) and the Forest Geode buy button (step 6), with `Shape = "Square"` to match the sharp-cornered tile style and `Pulse = 8` (draft).
  - After `DONE`: the first rebirth button in **focus mode**, which hides the other menu buttons and shops until the player confirms.
  - Walking steps don't use it, because a dimmed screen while walking hides the path. The 3D guide covers those.
- **Hint text:** no SpotlightUI hint text is passed, because its label doesn't use `TextStyleConfig`. The objective card says what to do, and a small styled "Buy!" word sits by the button.
- **To check when built:** that its overlay ScreenGui sits above the shop panels (DisplayOrder) and lines up with the shop's `IgnoreGuiInset`, on phone and PC.

**Soft locks.** Local red translucent Neon walls with a SurfaceGui over locked shop pads.

## Old guide arrows
The old floor-arrow trail (`GuideController/ArrowTrail`, its `GuideConfig` settings and the `Image_GuideArrow` registry key) was removed 2026-10-16 (user: defunct). `GuideController` now only runs `RockLabels`. The `GuideArrow` decal in `ReplicatedStorage.Assets` (Studio) is no longer used and can be deleted there.

## After the tutorial: hints
One at a time, ~5 s each, once per session, never during a chop or crack, ~1.5 s after one ends. Starter set: "Train to get stronger!" (training stand), "You can buy Stone Arms now", "Too weak for this rock → train", "Claim your Index rewards", "You can rebirth! (+cash, +luck)" (focus mode). Saved data arriving on join doesn't count as new.

## Settled decisions
- First-break bonus and free geode (old D1, D2): dropped. The tutorial uses the normal values above, and only the first chop's guaranteed Perfect is special.
- Intro cutscene: not in this build. The tutorial starts on spawn and pauses while `Letterbox` is open if a cutscene is added later.
- Skip: yes, until `FINAL`. It logs which step the player was on.
- Robux shop and gamepass buttons: hidden until `DONE`.
- Collect step: kept. Base income is a "reason to come back" (§05).

## Playtest checklist
- Full path on a fresh profile, timing each training step (≤5 s) and counting rocks on each chop step (≤3 with Good chops).
- The path goes around the lobby shops, bases and terrace walls.
- Failure halfway: spend cash on `BUY_ARMS`, leave and rejoin.
- Skip, and rejoin on every step.
- During a weather event: no storm rocks, catches or modifiers for the tutorial player.
- Touch and gamepad text.
- The funnel shows each step once (Creator Hub → Analytics → Onboarding funnel, after the place is published and played).
