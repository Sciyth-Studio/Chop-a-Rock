# Chop a Rock — Development Roadmap

**Precedence:** [`Chop_a_Rock_Master_Game_Plan.txt`](Chop_a_Rock_Master_Game_Plan.txt) defines WHAT the game is. This roadmap defines WHEN parts get built. [`AGENTS.md`](AGENTS.md) defines HOW code is written. This document is [PROPOSED] until the user approves it.

**MVP success criterion:** developer plays instead of develops for >10 continuous minutes. Every phase is judged against whether it advances that.

**Guiding principle:** the chop is the entire product. Everything else is scaffolding around a 5-second input. Sequence proves the chop feels good before building the economy around it.

---

## Phase 0 — Foundations (no visible gameplay)

**Goal:** the invisible plumbing every gameplay module will depend on. Nothing player-facing here.

**Deliverables:**
- `src/shared/Config/` — one module per concern:
  - `RockConfig.luau` — per-tier strength requirements, base payouts, respawn timing.
  - `ChopConfig.luau` — timing-meter parameters (windup duration, power-band positions, sloppy/good/perfect thresholds). `[PLAYTEST]`
  - `ArmConfig.luau` — arm tiers with strength-gain multiplier, price, look tag.
  - `TrainingConfig.luau` — base strength per successful training rep.
  - `EconomyConfig.luau` — currency formatting, offline-cap defaults (for later).
- `src/shared/Assets/AssetRegistry.luau` — key → asset location/id lookup, returns placeholder + warns if missing. Every future asset reference goes through this.
- Assets folder scaffold documented: `ReplicatedStorage/Assets/{VFX,Sounds,Animations,Models,Images}` (folder authored in Studio, project.json gets `$ignoreUnknownInstances` on ReplicatedStorage so Rojo doesn't wipe it — already set).
- Remove `ClaudeMarkerService` (smoke-test only, not part of the game).

**Gate to Phase 1:** `scripts/check.ps1` clean; a bare test service can read a config value and log a placeholder-asset warning.

**Dependencies:** none. Blocks everything else.

---

## Phase 1 — The Chop, Bare (prove the mechanic exists)

**Goal:** one rock, in front of the player, that responds correctly to hold-release input. No polish yet. Zero economy. This phase answers "does the timing meter work at all."

**Deliverables:**
- Server:
  - `RockService` — spawns one rock at a fixed spot for each player (client visual + server state), handles `ChopRequest`, classifies result (crack / sloppy / good / perfect), replicates result.
  - Chop timing runs on the server; client only sends "windup started" / "release" timestamps for the server to validate against `ChopConfig`.
- Client:
  - `ChopController` — captures ProximityPrompt or key hold, streams windup progress to a bare on-screen meter, sends release.
  - `ChopMeterScreen` under UIController — a plain sliding-band widget, no polish.
- Shared:
  - `Packets.ChopStart`, `Packets.ChopRelease`, `Packets.ChopResult` (server-authoritative; rate-limited).
- One placeholder rock (a scaled Part with a "yeah, that's a rock" material) at a fixed spawn-adjacent location. Instant respawn on break.

**What's explicitly not here:** screen shake, slow-mo, damage numbers, debris, SFX, animations, training, money, upgrades, second rock, crack-on-too-weak (the whole rock is breakable here since there's no strength system yet).

**Gate to Phase 2:** hold + release produces a legible sloppy/good/perfect result on the meter, server confirms, rock disappears + respawns. Feel is minimally readable.

**Dependencies:** Phase 0 configs, AGENTS.md UI convention (ScreenGui authored in Studio, code finds by name).

**Propose-and-wait item:** input scheme — hold-a-key vs. hold-a-proximity-prompt vs. click-and-hold. I lean **hold-a-key while near the rock** for MVP simplicity; needs your ok.

---

## Phase 2 — Impact Polish (make the break feel amazing)

**Goal:** transform the bare mechanic into something the developer wants to do again unprompted. This is where MVP-must-have #3 (full impact polish) gets built.

**Deliverables:**
- `ImpactController` (client) driving on-break feedback stack:
  - Screen shake (short, tuned in `ChopConfig`).
  - ~0.1s slow-mo frame just before contact (workspace.Gravity or timescale-lite via camera tricks).
  - Giant damage number pop (numeric label, scale-and-fade tween).
  - Pre-fractured debris (either scripted chunk instances or a stored fractured model looked up via AssetRegistry).
  - Placeholder "yoo" SFX played on perfect.
- Player character size held constant so the boulder visibly dwarfs them (handled via ScaleType on Humanoid; verified against a 20-30 stud rock).
- Bigger perfect shatter: larger shake, more debris, louder crunch (values in `ChopConfig`).

**Gate to Phase 3:** the developer breaks one rock, reflexively holds again. If it doesn't produce that response, iterate here before moving on.

**Dependencies:** Phase 1 mechanic. AssetRegistry (placeholders acceptable throughout).

**Propose-and-wait item:** the slow-mo implementation approach — camera-based fake vs. workspace physics vs. a per-player time-dilation trick. Depends on what plays best; I'll prototype the cheapest option and flag it.

---

## Phase 3 — The Loop (train → chop → upgrade → chop-a-bigger-rock)

**Goal:** prove the train → chop → upgrade cycle by adding just enough progression to have a decision. All balance values live in `Config`; nothing hardcoded.

**Status (2026-09-28):** built — saved Cash/Strength/ArmTier via `DataService`, passive training (no meter, by decision), arm shop with sequential tiers, second rock with crack-on-too-weak, HUD. Remaining: arm visuals on the player (`VisualAssetKey`), Crack SFX asset (`SFX_Rock_Crack`), and the balance-number sign-off below.

**Deliverables:**
- Player state (server, ProfileStore-backed):
  - `Strength`, `Money`, `ArmTier`.
  - Save on change (debounced); load on join.
- Training station:
  - A dedicated Part in the hub with a ProximityPrompt.
  - Interacting runs the same timing meter (single-tier "one board" for MVP).
  - Successful training → strength gain per `TrainingConfig`, multiplied by current arm tier's gain multiplier.
- Two arm tiers (`Arm_Base`, `Arm_Tier2`):
  - Visible on the player (glove/gauntlet attachment via AssetRegistry placeholder is fine).
  - Tier 2 costs money, sets `ArmTier`, boosts training gain.
- One shop UI screen (`ArmShop`) authored in StarterGui by the user; screen module drives it. Icon + label + price + buy button.
- Second rock in the zone:
  - Higher strength requirement than the first.
  - Too-weak attempt → crack response (visual + SFX, no reward, clear signal).
  - Successful break → higher payout per `RockConfig`.
- Money HUD (a screen module reading a player attribute).

**What's not here:** gems, luck, pedestals, base plots, offline income, rebirth, additional zones, teleports, gates, tutorial cutscene, index. All post-MVP per plan §10.

**Gate to MVP:** all seven MVP-must-have items from plan §10 present and functional; server-authoritative for timing/payouts/purchases; every threshold in Config.

**Dependencies:** Phase 2 polish; ProfileStore (already in ServerPackages); AssetRegistry for arm visuals.

**Propose-and-wait items:**
- Prices/rates for MVP: I'll draft numbers in Config and flag for your approval before merging. Player-facing values.
- Whether the two arm tiers are named "Fists" and something else, and whether tier 2 has an aura in MVP or defers to post-MVP.

---

## Phase 4 — MVP Playtest & Tune

**Goal:** stress-test against the 10-minute criterion. Not a build phase — a decide phase.

**Actions:**
- Delete `ClaudeMarkerService` (should already be gone by end of Phase 0 but confirming).
- Config sanity pass: any hardcoded number gets moved to Config.
- Play it repeatedly. If the 10-minute criterion fails, ask: is it a feel problem (go back to Phase 2) or a loop problem (adjust Phase 3 balance)?
- Only after passing: start planning post-MVP (gems + luck + bases).

---

## Cross-cutting standards

- Server-authoritative for chop timing, payouts, purchases, saves, all state changes. Client sends intent, server decides.
- All balance values in `src/shared/Config/*`. Any hardcoded threshold is a bug.
- UI: ScreenGuis authored in StarterGui (per AGENTS.md); code finds by name; missing screens warn and disable, don't crash.
- Assets: never referenced by path or id directly; always through `AssetRegistry`. Placeholders + warnings are acceptable throughout MVP.
- Rebirth-related code stays config-driven so the [TBD] rebirth-reset scope can be resolved post-MVP without rewriting.

## Deferred to post-MVP (do not build in MVP)

Gems, luck, base plots, pedestals, offline income, rebirth, floors, multipliers, additional zones, teleport pads, strength gates, tutorial cutscene, sensei/bacon-hair NPCs, cheering crowds, rock/gem index, milestone announcements, weekly rewards, random events, PvP arena, monetization (gamepasses / developer products), and additional arm/rock/environment tiers beyond the MVP two.

## Known risks

1. **Chop feel is untunable via config alone.** If Phase 2 polish doesn't land the "anime impact" feel, no economy will save the MVP. Mitigation: prototype Phase 1+2 together in a Studio-only sandbox before committing to the pattern.
2. **Studio-authored ScreenGuis are not in git.** Losing the place file loses all UI. Mitigation: user commits the .rbxlx (or a .rbxmx export of StarterGui) periodically; this is a user-side workflow, not a code fix.
3. **Server timing under lag.** Server-authoritative timing means high-latency clients may feel unfair. Mitigation: `ChopConfig` includes a latency-compensation window; playtest on throttled network before locking values.
