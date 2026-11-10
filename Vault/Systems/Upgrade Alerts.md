---
description: Wiggling red ! billboards over things you can now upgrade (Aura Shop, your training sign, Cannon Shop after an unlock) plus a once-per-level notification; client-only UpgradeAlertController + UpgradeAlertConfig. Built 2026-11-09, not playtested.
type: system
updated: 2026-11-09
---
# Upgrade Alerts

User, 2026-11-09: "Things that can now be upgraded should have an exclamation point appear above them and wiggle (look in the icon set folder for a 256px red one) as well as notify you." The user picked the targets and the notify rule from a list.

## What shows
| Alert | When | Over | Notification |
|---|---|---|---|
| Aura | cash ≥ next `AuraConfig.Tiers` price | `Workspace.AuraShop` | "<Aura> ready to buy!" |
| Training | cash ≥ `TrainingStands.Next` price (stands are cash only since 2026-11-09) | your plot's `TrainingUpgradeSign` | "<Stand> stand ready!" |
| Cannon | a new key appears in `Cannons` after load | `Workspace.CannonShop` | none (server already says "<Cannon> unlocked!") |

- Not chosen: the next pedestal slot. Rebirth is scrapped, so it's left out.
- Notifications fire **once per upgrade level per session** (user's pick), not again if cash dips and comes back. Kind `Unlock`.
- Cannon alert clears once the `CannonShop` screen opens; session only, not saved.
- All hidden while the tutorial runs (auras can't be bought then, and onboarding stays clean). `NotificationController` also drops normal notices during the tutorial.

## Build
- `UpgradeAlertController` (client): every `CheckSeconds` (0.25) reads `DataController`, places an invisible anchored part at the target's bounding-box top + `HeightStuds` in `Workspace.UpgradeAlerts`, and adorns a BillboardGui (`AlwaysOnTop`, `LightInfluence` 0, `MaxDistance` 250, `SizeStuds` 4) with the icon. RenderStepped wiggles `Rotation` (±`WiggleDegrees` 12 at `WiggleSpeed` 9) and bobs `StudsOffsetWorldSpace` (`BobStuds` 0.4).
- Icon: the pack's `UI/Exclamation Mark/256px/Exclamation Mark 1st Outline 256px.png` ([[Game Icon Pack]]; the outline version because a world billboard has no `IconOutline` copies), RGBA copy at `assets/Icons/Upgrade/UpgradeAlert.png`, uploaded by Claude through Open Cloud under the group as rbxassetid://77562065252330 (preload Success in Edit).
- All numbers are drafts.

Related: [[Auras]], [[Cannon Shop]], [[Training Upgrade Sign Reference]], [[Tutorial]]
