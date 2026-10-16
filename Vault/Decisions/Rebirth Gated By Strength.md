---
description: 2026-10-13 — no level system; rebirth N needs the toughest rock of zone N in strength; each rebirth unlocks the next training stand with a set strength per 1 s rep; rebirth gives cash + luck only.
type: decision
---
# Rebirth gated by strength, one stand per rebirth (2026-10-13)

The user studied a successful game and wanted its model. Strength is the one stat. Rebirth gives money multipliers. Every rebirth unlocks a new training with a set strength per rep (a rep takes 1 s). Rebirth is gated by a strength number, so there is no level system.

- **No bar on the HUD (user, 2026-10-13):** the "Rebirth N  x/y N" bar at the bottom of the screen was tried and rejected; the user wants no bar there at all. The `ExpBar` screen module is deleted, its ScreenGui was moved to `ServerStorage.UIBackup`, and the `HotStreakBar` container moved down into its old spot (bottom offset -84, above the hotbar) and no longer follows another bar. Rebirth progress shows only on the Rebirth screen.
- **Rebirth effect, not ready effect (user, 2026-10-14):** the old level-up effect (`VFX_LevelUp` + `SFX_Level_Up`) plays once just after a rebirth, never when strength reaches the gate. `RebirthEffectController` plays it when `Rebirths` goes up by exactly 1; keys are `RebirthConfig.RebirthEffectKey` / `RebirthSoundKey`.
- Gate: `RebirthConfig.BaseStrengthRequired` 100 × `StrengthGrowth` 125^(N-1). That is the toughest rock of zone N (100, 12.5K, 1.56M, 195M, 24.4B), so there is one rebirth per zone. Claude chose this because strength per second has to keep pace with rock requirements growing ×125 per zone. Six stands with small steps topped out at about 4,800/s, while Snow needs 976M.
- Stands are `TrainingConfig.Stands`: Wood R0 1, Brick R1 25, Steel R2 2,500, Vault R3 300K, Energy Core R4 40M, Cosmic R5 5B per rep, each × the arm multiplier. That's about 10 minutes of training without arms per zone. `ChopIntervalSeconds` is now 1 (was 1.6). The strike animation still fits: 0.21 s lead + 0.35 s hold.
- The user agreed the stand only changes looks and feel. Its set strength per rep is the training output, and the rebirth count gives no strength multiplier.
- Rebirth keeps the cash multiplier (1 + N) and the luck bonus.
- Arms still multiply training (Claude's default; the user didn't object).
- Every zone after Snow needs a new stand.
- Considered and dropped: gating stands by zones (5 zones vs 6 stands, and zones already give walk speed), by arms (duplicates the money lever), by level (resets on rebirth, so the stand would downgrade), and buying stands with cash (a second money-bought training multiplier, and a bad time to make kids pay right after a rebirth).

Built 2026-10-13 and checked in Play. Details in [[Training Stand Reference]]. Game plan: Decision Log 2026-10-13. Related: [[Big Numbers Over Small Ones]], [[Zones After Desert]]

## Change 2026-10-14: rebirth unlocks, the upgrade sign buys
The user asked for a way to change training tier, then sent [[Training Upgrade Sign Reference]] ("a sign like this for upgrading"). Rebirth no longer swaps the stand by itself. Rebirth N only **unlocks** stand N+1; the player buys it at an "Upgrade" sign beside their stand with cash, or with Robux. Claude proposed this ("rebirth unlocks, sign buys") and the user didn't object; Robux skips only the cash, never the rebirth gate. Tiers are kept through rebirths. No downgrading ("who is ever doing that", user). This reverses the "buying stands with cash" item in the dropped list above. Draft prices (about 8-10 chops of the zone's first rock × the rebirth cash multiplier): Brick $50K, Steel $5M, Vault $400M, Energy Core $30B, Cosmic $500B; Robux 25 / 49 / 79 / 99 / 149, not yet approved and no developer products made. See [[Training Stand Reference]].

## Change 2026-10-16: Robux skips the rebirth gate
The user said Robux only working after the rebirth "defeats the point of the skip". The Robux button on the upgrade sign now buys the next stand at any time, with no rebirth needed. Cash still needs the rebirth. The server grant never checked rebirths. Only the sign's client check changed (`Components/TrainingUpgradeSign`). Prices approved: Robux 25 / 49 / 79 / 99 / 149, developer products made 2026-10-16 (ids in `TrainingConfig`). This replaces "Robux skips only the cash, never the rebirth gate" above.
