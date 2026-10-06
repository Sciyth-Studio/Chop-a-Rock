---
description: How the geode stand shopkeeper (user 341574948, R6) was imported and posed, 2026-10-04; reuse for other shopkeepers.
type: reference
---
# Shopkeeper avatar

`Workspace.Shopkeeper`: R6 avatar of user 341574948 leaning on the front-right of the geode stand (`Workspace.Geode Stand`), facing the spawn side (+Z).

How it was made (Studio, Edit mode `execute_luau`):
- `Players:GetHumanoidDescriptionFromUserId(id)` then `Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)`. Works in Edit mode.
- Deleted `Animate`, `DisplayDistanceType = None` so no name tag, every part Anchored.
- Static pose by `Part1.CFrame = Part0.CFrame * C0 * rot * C1:Inverse()` per Motor6D. Shoulder and hip rotate about joint Z (swing forward or back); the body is tilted 14 degrees about the feet and the hips get the same angle back so the legs stay vertical.
- Stand face at torso height is a near vertical plane at z about -261.2; floor top y is 1.0.
- `screen_capture` needs a `capture_id` (any string); move `workspace.CurrentCamera.CFrame` first to frame the shot.

A second shopkeeper, `Karlosush` (user 531562578), stands in `Workspace.SellShop` (2026-10-06); see [[Sell Shop]] for the accessory-weld gotcha.

Related: [[Geode Stand Reference]]
