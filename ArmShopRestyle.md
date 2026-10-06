# Arm Shop UI restyle: checklist

## Read first
`AGENTS.md`, `Vault/Index.md`, `Vault/Preferences/Menu Panel Style.md`, `Vault/Reference/UI Style References.md`, and the `studio-ui` and `studio-playtest` skills (`.claude/skills/`).

## Current state
- `StarterGui.Shop` → `Panel` (480×380, rounded) with `Title`, `CloseButton`, `List` (ScrollingFrame + UIListLayout), hidden `RowTemplate` (`TierName`, `TierInfo`, `BuyButton`), `ScreenScale`.
- Driven by `src/client/Controllers/UIController/Screens/Shop.luau`. Tiers come from `src/shared/Config/ArmConfig.luau`.

## Decided by the user (do not change)
- **Panel colour is orange** (edge 255,110,0 / center 255,205,120 / studs 170,60,0): header bar and panel glow.
- **Buy button colours:** green when affordable, grey when too expensive, orange when owned. Tiers beyond the next one (locked) are grey.
- **Text:** notification style everywhere (white, black stroke, no gradient). The only exceptions are the parts the house style marks as Chrome (the header title), plus anything the user names later.
- **No cash display in the header.**
- **Arm previews use ViewportFrames** built from `ArmConfig` at runtime, so new tiers need no UI work. ViewportFrames do not render particles; hand sparkles will not show, which is accepted.

## Studio build (Edit mode, Studio MCP)
- [ ] Copy the header bar, close button and button fill from `StarterGui.Rebirth` rather than rebuilding them, then recolour to orange.
- [ ] Remove every `UICorner`.
- [ ] `Panel`: box style (black horizontal gradient 0.3 / 0.6 / 0.3, orange `ColorGlow`, `InnerBorder` with a white 3px Miter stroke). Make it roomy; Rebirth's 760×520 is the reference. Keep `ScreenScale`.
- [ ] Header bar flush with the top and sides, holding a Chrome "ARM SHOP" title with a `TitleShadow`.
- [ ] `CloseButton`: 56×56 inside the header, 14px from the right edge, notification-style X.
- [ ] `List`: padding, list spacing, automatic Y canvas size, styled scrollbar.
- [ ] `RowTemplate`:
  - inner-box style
  - a `Preview` ViewportFrame for the arm
  - `TierName`
  - `TierInfo` showing the multiplier
  - `BuyButton` with `Fill`, `StudTexture` and a child `Label` (the fill hides the button's own text), plus a money icon with outlines and shadow next to the price
- [ ] Agent's call: whether to highlight the tier the player has equipped, and the exact sizes and spacing.

## Code
- [ ] **Arm previews:** for each tier, clone an arm model into the row's ViewportFrame and apply `tier.Visual.Material` and `.Color` to each part, the same way `ArmVisualService` does on the server (`src/server/Services/ArmVisualService.luau`, `apply`).
  - Recommended source: a template R15 arm model (upper arm, lower arm, hand) fetched through `AssetRegistry`.
  - Add a `Camera` framed on the arm.
  - Light the frame with `Ambient` and `LightColor` so materials don't render flat.
  - Do not move `ArmVisualService` code into a shared helper without asking the user.
- [ ] Replace `paint()`, which sets `BackgroundColor3`, with Rebirth's approach: recolour the `Fill` gradient and `StudTexture` (`Rebirth.luau`, around line 95). Use the green, grey and orange colours from the palette, not constants hardcoded at the top of the file.
- [ ] Put button text on the child `Label`. Update shadow labels together with the real ones.
- [ ] A missing element should warn and skip, not error.
- [ ] House rules: `--!strict`, no comments, no edits outside this task, run `./scripts/check.ps1`.

## Check it works
- [ ] Playtest from the Arm Shop stand. Check every button state: owned, next tier affordable, next tier too expensive, locked.
- [ ] Buy one tier. The rows and colours should update live and the sound should play.
- [ ] Every tier's arm preview shows the right material and colour.
- [ ] Phone size: scaling and scrolling work. The close button works.
- [ ] Tell the user to **save the place file** (StarterGui is not in git). When committing, add only this task's files by explicit path.
- [ ] Record what you learned in the vault, e.g. a gotcha about ViewportFrames, and add the Shop changes to the `studio-ui` skill.
