---
description: Roks as Backpack tools, base pedestals earning flat $/s onto green pads, slot buying, Equip Best and the Roks panel (built 2026-10-06).
type: system
---
# Pedestals and Rok tools

Plan and decisions: `PetBaseSystemPlan.md` (approved 2026-10-06), Master Game Plan Decision Log 2026-10-06.

## Server
- `PetService` (folder): `Tools.luau` keeps one `Tool` per unplaced Rok in the Backpack (attribute `PetId`, handle = the Rok model's PrimaryPart renamed `Handle`, scaled by `PetConfig.ToolScale`, `PetConfig.ToolGrip`). Tools are rebuilt whenever a new `Backpack` appears (respawn). `HeldChanged` fires when a Rok tool enters or leaves the character. `PutAway` is called by RockService, GeodeService/Cracking and TrainingService when a chop, crack or training round starts.
- `PedestalService` (folder): `Placement` (place, pick up, Equip Best, buy slot, sanitise bad slots on load), `Earnings` (pure math), `Display` (Rok model `PlacedRok` on the pedestal, pedestal attributes, the `PedestalPrompt`). Prompts are server-made with the `OwnedPrompt` tag, like the geode pit.
- Data: `Pet.Slot` (1-8 when placed), `PedestalSlots` (unlocked count), `PedestalEarnings` (uncollected money per slot, string keys). Slots unlock in `PedestalConfig.UnlockOrder` (1,5,2,6,3,7,4,8: entrance end first, alternating sides).
- Earnings never tick through data. Each slot keeps `Banked` + `Rate` + `BankedAt` (server time). Since 2026-10-27 income steps once every `IncomeTickSeconds` (1 s; was a 0.1 s display refresh): `Earnings.Current` = `Banked + Rate x whole seconds since BankedAt`, and that is what the pad shows and a collect pays. `Take` moves `BankedAt` forward by whole seconds only, so the part-second in progress carries over. `Earnings.Exact` (continuous) is used for rate changes (`SetRate` banks exactly, then the tick phase restarts at that moment) and for every save (flush, collect, release), so the slower tick never loses or double-counts income. Checked in Play: the pad stepped +$2 at each whole second, a collect of $38 took the HUD from $771 to $809, and `BankedAt` moved exactly 41 s with the $0.66 fraction kept. Data is flushed every `FlushSeconds` and written directly in `PlayerReleasing`. Offline time comes from `LastSeenAt` (set on every save), at `OfflineRateMultiplier`, capped by `EconomyConfig.OfflineCapSeconds`.
- Collect: owner touches the pedestal's `EarningsPad` (server `Touched`, 1 s cooldown per slot).
- Rebirth clears every pad (2026-10-18). When `RebirthConfig.ResetCash` is on, `RebirthService` calls `PedestalService:ClearEarnings`. That zeroes each slot's `Banked`, moves `BankedAt` to now and empties `PedestalEarnings`. Banked pad money is uncollected cash, so it resets along with cash. Roks and their rates stay, and the pads start filling again straight away. Before this fix the banks survived a rebirth (both the session and the saved data), so a player could collect them straight into the fresh wallet. Checked in Play: about $160K across six pads dropped to 0 and stayed small after restarting Play.
- Online banking has no cap. A pad keeps adding `Rate x elapsed` for as long as the player stays in the server, so an AFK player banks without limit. Only offline time is capped (`EconomyConfig.OfflineCapSeconds`, 4 h). This is intended: the user decided on 2026-10-23 that online banking has no cap.

## Client
- `Components/Pedestal.luau` (tag `Pedestal`, added by the server) clones `Assets/VFX/PedestalPad` (`Amount`, a top-face SurfaceGui since 2026-10-24) onto the pad and `PedestalInfo` (`Modifier`, `Title`, `Detail`, top to bottom; see [[Weather]]) above the pedestal, and counts the pad up locally from the attributes. Visitors see them too.
- `Screens/Roks.luau` + `StarterGui.Roks` (teal header, copy of the Shop panel): title "X/Y Placed", `Header.SlotButton`, `List.RowTemplate` (`Preview`, `RokName`, `UnequipButton`), `EmptyLabel`, `EquipBestButton`. Opened by the `RoksButton` menu button (was `BagButton`).
- The Delete button shown while holding a Rok (`HeldRok`) was removed the same day; Roks are sold at the [[Sell Shop]] instead.
- `ExpBar.Container` moved to y = 1,-84 so it clears the Roblox hotbar.
- Idle motion (2026-10-14, draft numbers in `RokMotionConfig`): `Display` tags each `PlacedRok` `IdleRok`, sets `PlacedAt` (server time) and makes it `Atomic` for streaming. `Components/IdleRok.luau` makes it breathe (volume-kept Y squash, random phase), blink (parts ending `_Eyes` / `_Pupils` squash in Y) and drop in with a squash bounce when `PlacedAt` is under 1 s old. It resizes and moves parts locally each frame, so it assumes Rok parts are axis-aligned with the pivot at bottom centre (all forest Roks are). Skipped beyond 100 studs from the camera; Low Graphics turns off breathing only. New Roks need their eye meshes named `<Name>_Eyes` / `<Name>_Pupils` to blink.

## Gotchas
- Pedestal Models are `Atomic` (set in `Display.EnsurePrompt`, 2026-10-22). Before this they streamed part by part, so walking away streamed out `EarningsPad` and took the client's pad BillboardGui with it. The component never restarted because the tagged Model stayed, so the amount never came back. The server `Touched` collect still worked. Atomic alone didn't fix every pad (some still came back blank after cannoning to snow), so `Components/Pedestal` now also rebuilds both billboards whenever a child named `Pedestal` or `EarningsPad` is added or removed. Any client gui parented to a part inside a tagged model needs the same remount.
- Auto Equip on hatch waits for the reveal (2026-10-20). `PetService.Granted` carries an equip delay. `GeodeService/Cracking` passes the impact delay plus `HatchTiming.RevealSeconds(rarity)`, so the Rok drops onto the pedestal at the pop and not mid-animation. Before this, the Rok was placed the moment it was granted, which spoiled the reveal. Admin grants pass no delay.
- The pedestal prompt range (10) is measured from the pedestal centre; the pad is 8.25 away, so standing on the pad is just inside range.
- Hotbar icons are empty until the item-icon pipeline (`IconSystemPlan.md`) lands; set `Tool.TextureId` from it then.

## Collect pad look (2026-10-24)
Matched to the user's reference (flat green pad, raised border, tiled squares, amount printed on the pad):

![[Collect Pad Reference.png]]

- `EarningsPad` is 3.5 x 0.5 x 6.5, `2022 Universal` variant (square tiles), colour still 0,90,0. It is turned 90° in the pedestal so its Top-face SurfaceGui canvas is 325 x 175 (50 px/stud) with the text running along the long side, upright for a player standing on the centre path. The SurfaceGui maps the part's local Z to its width, so don't swap the pad's size back to 6.5 x 3.5.
- `EarningsPadEdge` is a grey 100,100,100 rim (user asked for grey) behind the pad: 7.4 x 0.35 x 4.4, `2022 Inlet`, no collide, touch or query. Collect still only listens to `EarningsPad.Touched`.
- Amount text: `Chrome` style, 9 px black round stroke, `LightInfluence` 0, label 0.92 x 0.78 with TextScaled. The amount is redrawn from the attributes when the whole-second count changes (checked each Heartbeat) and straight away when `Banked`, `BankedAt` or `Rate` change, so it jumps cleanly once a second (the pad doesn't use `NumberTicker`; the user chose a clean jump over a count-up on 2026-10-27). `PadLabelHeightStuds` is gone.
- Edited in Studio on `Model_BasePlot` (all 8 pedestals) and `Model_BasePedestal`. The old billboard is kept in `ServerStorage.UIBackup.PedestalPadBillboard`.

Related: [[Base Plot Reference]], [[Index]], [[Menu Panel Style]]
- Earnings pad colour (2026-10-10): pure green 0,255,0 looked self-lit, and the user called it a glow. The lobby colour correction pushes bright greens so hard that the stud texture disappears. Pads are now 0,90,0, which still reads bright green but is properly lit with studs showing. Up to about 0,75 still looks lit; 0,115 and above look glowing. Applied to `Model_BasePedestal`, the `Model_BasePlot` pedestals and the old backup.
