# Chop a Rock — Development Roadmap

**Precedence:** [`Chop_a_Rock_Master_Game_Plan.txt`](Chop_a_Rock_Master_Game_Plan.txt) defines WHAT the game is. This roadmap defines WHEN parts get built. [`AGENTS.md`](AGENTS.md) defines HOW code is written. The running task list is [`Vault/To Do.md`](Vault/To%20Do.md); this page tracks phases.

**Updated:** 2026-10-08

**MVP success criterion:** developer plays instead of develops for >10 continuous minutes.

**Guiding principle:** the chop is the entire product. Everything else is scaffolding around a 5-second input.

---

## Done

### Phases 0–3 — Foundations, the chop, impact, the loop
Configs in `src/shared/Config/`, `AssetRegistry`, server-authoritative chop with the moving power band and five timing qualities, multi-chop rocks with health bars, crack-on-too-weak, break presentation, the secret Master Chop, training with the chop animation, money, arm tiers with arm visuals and the Arm Shop (studded restyle with arm previews), strength, levels and the EXP bar, guidance (rock labels, arrow trail), friend boost and invite.

### MVP scope (plan §10, re-scoped 2026-10-01)
- Forest zone with Stone, Boulder and Mossy Boulder, pre-split break pieces.
- Rebirth #1 (level 12 gate, x2 cash and strength, Skip Rebirth shown but inactive).
- Chop VFX: hit, crack, break, Perfect and Master effects, coin cash pop, level-up sparkle and sound.
- Settings panel (master volume, Music/SFX/Low Graphics/Auto Equip/Notifications).

### Built ahead of MVP (pulled forward by the user)
- Geodes, hatching and the hatch reveal; luck affects hatch rarity.
- Roks (pet rocks) as Backpack tools, six forest Roks.
- Six bases, pedestals with flat $/s onto earnings pads, slots, Equip Best, the Roks panel, offline income (50%, 4-hour cap).
- Sell Shop.
- Index (Roks + Rocks pages, claims, zone completion bonus).
- Per-player rock spawning in spawn areas.
- Shop pads, admin panel.
- Desert zone with three placeholder rocks; jungle, ocean and snow bases laid (floor and terrace walls).

---

## Phase 4 — MVP playtest and tune (current)
**Goal:** pass the 10-minute criterion with the forest. Not yet confirmed.
- Play repeatedly. If it fails, decide: feel problem (chop, effects) or loop problem (balance in Config).
- All draft numbers stay `[PLAYTEST]` in Config.

## Phase 5 — In-session pressure (approved 2026-10-06, not built)
Hot Streak, Rush Rocks, countdowns on shared special rocks, and the Diamond Rock. Visuals and UI are proposed to the user before building.

## Phase 6 — More zones
Zone order: forest → desert → jungle → ocean → snow (`new-zone` skill).
- Desert: real rock models to replace the placeholders, Roks, geode, Index page.
- Jungle, ocean, snow: rock lineups need approval; the ocean Rok lineup needs revisiting for the deep-ocean theme.

## Phase 7 — Polish and tooling
- Item icons for Roks and rocks (`IconSystemPlan.md`, waiting on decisions D1–D6).
- Ascended Chop (1 in 1,000) — `[TBD]`, not built until the user picks it up.

## Later updates (not scheduled)
Rebirths past #1 and floors, better training methods, weather modifiers and Golden variants (Index tabs deferred until these exist), monetization (gamepasses, developer products, a working Skip Rebirth), daily/weekly rewards, random events, PvP arena.

---

## Cross-cutting standards
- Server-authoritative for chop timing, payouts, purchases, saves, all state changes. Client sends intent, server decides.
- All balance values in `src/shared/Config/*`. Any hardcoded threshold is a bug.
- UI: ScreenGuis authored in StarterGui; code finds by name; missing screens warn and disable, don't crash.
- Assets go through `AssetRegistry`.
- Rebirth-related code stays config-driven so the open reset-scope questions can be resolved without rewriting.

## Known risks
1. **Studio-authored ScreenGuis are not in git.** Losing the place file loses all UI. Save the place file after every UI change.
2. **Server timing under lag.** High-latency clients may feel unfair; playtest on a throttled network before locking values.
3. **Uploaded assets and group ownership.** Images uploaded through the Studio MCP are user-owned and must be shared with the group game to load.
