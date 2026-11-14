---
description: 2026-11-11 Block rounds for the world bosses (WorldBossPlan 4.4) — a chop round where the zones become one red block zone; stop the cursor in it to block. Testable on rocks with the admin "Toggle Block Rounds"; playtested by Claude.
type: system
---
# Block rounds

The boss's turn inside the chop bar, from `WorldBossPlan.md` 4.4. Built 2026-11-11 before any boss service, so it can be tried on ordinary rocks.

## Design (user, 2026-11-11)
The first version swapped the bar for a separate target with a shrinking ring and a 1.5 s timing window. The user: "too far removed from the minigame we have". They picked the **red block zone**: the bar sweeps exactly as in a chop, but the coloured zones become grey with one red zone. Stop the cursor in the red zone to block, in its yellow centre for a perfect block, anywhere else for "Ouch!". A block round deals no damage. Alternatives they passed on: "danger chop" (chop as normal, quality decides if you get hit) and "faster sweep".

## Harder (user, 2026-11-11: "for bosses to actually be tense blocking needs to be difficult")
The user picked all four levers: a narrower zone, a faster sweep, one pass only, and harder when mad.
- **Zone** (`BlockRoundConfig`, `ChopZones.BlockBand` / `ClassifyBlock`): `ZoneWidth` 0.13 and `PerfectWidth` 0.04 of the bar, times the chop zone multipliers (PC 1.5, touch 2.5) and the difficulty's `ZoneScale`. Strength does not widen it. The centre is a random chop centre (0.2 to 0.8), clamped inside the bar.
- **One pass** (`ChopZones.BlockPosition`): the zone shows for `LeadSeconds` 0.6 with the cursor parked at the left (the boss's wind-up). Then the cursor crosses the bar once, left to right, in half a chop cycle divided by `Speed`, and stops at the end. A press during the lead counts as "Ouch!", and so does no press by the end of the pass plus `MaxLatencySeconds`.
- **Difficulties:** `Normal` (Speed 1, ZoneScale 1) and `Mad` (Speed 1.2, ZoneScale 0.85). Rocks use Normal; the admin "Toggle Mad Block Rounds" (alias `blockmad`) switches the rock test to Mad.
- **Windows** (zone lit / perfect lit): PC 146 / 45 ms, PC mad 104 / 32 ms, touch 325 / 100 ms, touch mad 230 / 71 ms. The first harder pass (zone 0.1, perfect 0.03, Speed 1.5, mad 1.875 x0.75) gave PC 75 / 22 ms and mad 45 / 13 ms; the user called it "overkill difficulty" and it was eased to these numbers the same day. Not yet felt by the user.

## How it works
- **Server:** `ServerScriptService.Utils.BlockJudge.Judge` turns the claimed elapsed time (clamped by `ChopTiming.Elapsed`) into a cursor position and classifies it against the round's centre. Packets: `BlockRoundStart` (centre, speed, zone scale), `BlockPress` (claimed elapsed), `BlockResult` (outcome 1 Blocked, 2 Perfect, 3 Missed).
- **Rocks (test only):** the admin cheat `BlockRounds` ("Toggle Block Rounds", alias `block`, Chop tab) makes every 4th round of a rock chop a Block round (`RockService` `startBlockRound` / `onBlockPress`, `Session.BlockStart`). On rocks the outcome is only shown: no HP, counter-hit or bonus. Those come with the boss service.
- **Client:** `ChopController` starts the pass on `BlockRoundStart` (centre, speed, zone scale) and sends the chop button (E, Space, R2, left click, touch button titled "Block") as `BlockPress`. It fires `BlockStarted(center)` / `BlockResolved(outcome)`, exposes `IsBlockRound()`, and freezes the cursor on the result (on a miss too). "Ouch!" shakes the camera; "Perfect block!" flashes the screen.
- **UI:** `ChopBar` repaints the existing `RampGradient` in the chop quality colours (user, 2026-11-11: "use the same colors as the chop minigame"): outside = Bad red, zone = Great lime, centre = Perfect pure green (`buildBlockRamp`). The cursor becomes a shield: `Bar.CursorLane.Cursor.Shield` (96 px ImageLabel, `rbxassetid://114868042792448`, the user's white shield with a baked 7% black outline, source `assets/Icons/OutlineSources/Shield.png`, group-owned, Approved). The plain cursor's background and stroke hide while it shows (`setShieldCursor`). `ResultLabel` shows "Block!" (Red), then "Blocked!" (Green), "Perfect block!" (the Perfect chop's rainbow) or "Ouch!" (Red). The first version's `BlockCue` and `BlockFlash` were deleted.
- **Sounds** (picked with earshot, see [[SFX Audit]]): warning `SFX_Cannon_Whoosh` (peaks about 0.8 s in), Blocked `SFX_Train_Vault` (door-slam thud), Perfect `SFX_Chop_Perfect`, Ouch `SFX_Enemy_Hit`.

## Playtest (Claude, 2026-11-11)
- Harder version: the zone shows narrower on screen. The cursor stayed at 0 through the lead, crossed (0.14 at 0.7 s, 0.40 at 0.85 s, 0.67 at 1.0 s), stopped at 1.0, and "Ouch!" came 1.50 s after the start. A pure-function check at centre 0.5: 0.85 s gives position 0.50, Perfect.
- Earlier, wider version:
- Seen on screen: grey bar, red zone with a yellow centre, the cursor sweeping, "Block!" above.
- No press: "Ouch!" after 3.4 s. A real E press stopped the cursor at 0.423 against a zone of 0.10 to 0.40, and the server said "Ouch!", which matches. The cursor stayed frozen after the result.
- Judge edges (centre 0.5, PC): 0.34 Missed, 0.36 Blocked, 0.45 Blocked, 0.46 Perfect, 0.54 Perfect, 0.55 Blocked, 0.66 Missed. A centre of 0.9 clamps the zone to 0.70 to 1.00.
- Not tested: a real press that lands "Blocked!" or "Perfect block!", touch and controller.
- A strong save breaks Forest rocks in one chop. Test on a Ruins rock with Ignore Strength; it lasts about 7 chops, so one Block round per rock.

On bosses since 2026-11-11: a wide camera that frames the boss and a ForceField shield in front of the player that flashes, shudders or shatters on the result ([[World Bosses]], boss abilities).

Related: [[Chop Minigame]], [[World Boss Research]], [[Boss Sheets]]
