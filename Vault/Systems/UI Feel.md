---
description: Button hover/press feel (2026-10-14) on every screen via UIController/ButtonFeel; hover darkens + grows with a tick, press squashes, click sound; layout and pivot gotchas; panel pop, shimmer, success/error feedback, toggle and tab sounds (2026-10-15).
type: system
---
# UI Feel

Approved 2026-10-14. The user asked for "buttons growing darker when hovered + sound effects + shimmers and clicks and pops".

## Decisions (user, 2026-10-14)
- Hover darkens **and** grows slightly.
- A tick plays on every hover, not just on click.
- Shimmer is a slow idle shine, only on buttons that want attention (Rebirth ready, affordable Buy, Claim, Claim All).
- The user finds the sounds. Claude can search the Creator Store (`search_asset`, Audio, free, short) and drop candidates into `Assets/Sounds/UI` to audition.

## Built (phase 1)
- `UIController/ButtonFeel.luau`: `UIController` calls `feel.Bind(gui)` after each screen's `new`. Every `GuiButton` is bound, including ones added later (cloned rows), and unbound when it leaves the gui.
- Visual box: the button itself, or its parent when the button is an invisible `Button` covering a frame (menu buttons, teleport bar, cards). Full-screen covers (`HatchReveal.Dismiss`) get only the click sound.
- Darkening tweens `Track.Fill.BackgroundColor3` (the `UIGradient` multiplies it, so screens' gradient recolours are untouched), else the box's own background. Hover 18%, press 30% (drafts).
- Grow and press use a `UIScale` named `FeelScale`: hover 1.06, press 0.93, release springs back with Back easing (drafts in `UIFeelConfig`).
- Sounds: `SFX_UI_Hover` (at most one every 50 ms) and `SFX_UI_Click`, played through `LocalSound`, so the SFX toggle and volume apply.
- Per-button attributes: `Feel = "None"` opts out; `ClickSound = "<AssetRegistry key>"` overrides the click; `Tilt = true` on the box tilts its `Icon*` children (`TiltDegrees` -10, springy) while hovered or pressed. The side menu buttons and `MenuButtonTemplate` have `Tilt` (user asked, 2026-10-14).
- Sounds in `Assets/Sounds/UI` (2026-10-14, picked by Claude from the Creator Store, both by Roblox): `SFX_UI_Hover` = RBLX UI Hover 01 (`10066931761`, vol 0.3), `SFX_UI_Click` = Roblox_UI_Bright_Click (`15675059323`, vol 0.5). Alternates to audition in `ServerStorage.UISoundOptions`: RBLX UI Hover 03, SodaBreadle Hover 1, Pop Button Click, SodaBreadle Click 1. To swap, rename the alternate to the `SFX_UI_` name and move it into `Assets/Sounds/UI`.
- Screen open sounds: `UIController:Open` plays `UIFeelConfig.OpenSounds[name]` once per open (not again while already open). A shop bell (`SFX_UI_ShopBell` = "Shop Bell open" `127488139302452`, 1.96 s) plays for Shop, GeodeStand, SellShop, AuraShop and RobuxShop (user asked 2026-10-14 "a shop bell for when the shop ui opens"; Claude applied it to every shop). Bell alternates are `Bell_*` in `ServerStorage.UISoundOptions`.
- Touch: hover is ignored while the preferred input is touch. Gamepad selection counts as hover.

## Built (phase 2, 2026-10-14)
- Panel pop: every modal ScreenGui (Shop, GeodeStand, Index, Rebirth, RobuxShop, Roks, SellShop, Settings, AuraShop) has its `Panel` inside a transparent full-screen `PopRoot` frame holding a `UIScale` named `PopScale`. It has to be a wrapper because one object only honours one `UIScale`, and `Panel` already has `ScreenScale`.
- `UIController/PanelPop.luau`, driven by `UIController:Open`/`Close`, applies to any screen with a `PopRoot` child. Open: 0.7 to 1 over 0.25 s, Back easing (overshoots about 3%). Close: shrinks to 0.8 over 0.1 s, then calls the screen's `Close`. Reopening during the shrink cancels it. Numbers in `UIFeelConfig` (`PopOpenFromScale` etc., drafts).
- Sounds: `SFX_UI_PanelOpen` = RBLX UI Select 01 (`10128760939`), `SFX_UI_PanelClose` = RBLX UI Back (`10066914500`), both by Roblox, vol 0.5. Shops keep their bell (`OpenSounds` overrides the open sound). Alternates `PanelOpen_*` / `PanelClose_*` are in `ServerStorage.UISoundOptions`.
- New modal panel: wrap its `Panel` in a `PopRoot` copy and it pops with no code change.
- Gotcha: a screen's own `Close` (and state like `isOpen`) runs 0.1 s after `UIController:Close`, when the shrink ends.

## Built (phases 3 and 4, 2026-10-15)
- Shimmer: a hidden `Shine` frame (white, `UIGradient` rotation 20 with a narrow 0.45-transparency band) sits inside `Track.Fill` of the attention buttons: Rebirth `RebirthButton`, Arm Shop and Aura Shop `RowTemplate.BuyButton`, Geode `BuyOne`/`BuyThree`, Index `ClaimButton`, `ClaimAll` and `SectionTemplate...ZoneReward`. Screens set the boolean attribute `Shimmer` on the button; ButtonFeel shows the shine and slides its gradient Offset -1 to 1 over 0.7 s every 1.8 s (the first sweep waits for the gap too). When on: Rebirth ready, affordable next arm tier, unowned unlocked affordable aura, affordable geode buy with no blocker, claimable entry / zone / any claim.
- New attention button: add a `Shine` copy to its `Track.Fill` in Studio and set `Shimmer` from the screen.
- Feedback: `context.Feedback(button, isSuccess)` (from `ButtonFeel.Feedback`). Success bounces `FeelScale` to 1.15 then settles back with Back easing; callers keep playing `SFX_Money_Gain` as the cha-ching. Failure plays `SFX_UI_Error` and shakes the box's `Rotation` through -7, 6, -5, 4, -2, 0 (0.04 s steps). Wired on arm, aura, geode and slot buys, Index claims, Sell, and Rebirth. Local rejects (locked arm tier, locked or unaffordable aura, rebirth not ready, Sell with nothing selected) also fail.
- Toggle and tab sounds use the existing `ClickSound` attribute: `SFX_UI_Toggle` on the Settings toggles and Geode `LuckToggle`, and `SFX_UI_Tab` on the Index and Geode `TabTemplate` and the Sell Shop `SortTemplate`.
- Sounds (picked by Claude 2026-10-15, vol 0.5): `SFX_UI_Error` = "Tycoon Error Sound" (`90321528664115`), `SFX_UI_Toggle` = Pro Sound Effects "Switch Click On Or Off Toggle Button 1" (`9119717529`), `SFX_UI_Tab` = RBLX UI Swipe (`10128766965`). Alternates `Error_*`, `Toggle_*` and `Tab_*` are in `ServerStorage.UISoundOptions`. Creator Store search for error/buzzer sounds returns almost nothing from verified creators.
- Numbers are drafts in `UIFeelConfig` (`SuccessScale`, `ShakeDegrees`, `Shimmer*`).

## Gotchas
- `UIScale` scales around the object's `AnchorPoint`. ButtonFeel re-anchors free-positioned boxes to 0.5,0.5 once at bind and shifts `Position` by the exact UDim difference, so they don't move. Code that positions a button itself must use its anchor (`Hud.luau` invite button does).
- Inside a `UIListLayout`, a `UIScale` pivots at the top-left and pushes the siblings. Inside a `UIGridLayout`, it scales around the cell centre with no reflow. So the menu buttons, teleport bar, Index tabs and Sell Shop sort list were switched to `UIGridLayout` (named `GridLayout`) on 2026-10-14. The old list layouts are in `ServerStorage.UIBackup`. Buttons still in a list (the admin command list) only darken and don't grow.
- A box that already has another `UIScale` (a `ScreenScale` root such as `ChopMeter.LeaveButton`) doesn't grow.

## Still to do
- Phase 5 (user): listen to the sounds, swap alternates, tune volumes and the drafted numbers in a playtest.

Related: [[Menu Panel Style]], [[Settings]], [[UI Built In Studio]]
