---
description: The "Arm Shop" and "Wood Training" name signs above the lobby stands; how they are built and two Studio gotchas hit while making them.
type: reference
---
# Stand name signs

`StandSign` BillboardGuis hang above the two lobby stands, parented to a mesh and adorned to an Attachment named `SignAnchor`, so they move with the model. Non-italic, BuilderSans ExtraBold, colors baked into the label (plus the `TextStyle` attribute):
- "Arm Shop" (14 x 4 studs, 4.9px stroke, `Strength` style) on `Workspace.ShopKiosk.ShopStall.ShopStall_Wood`, anchor about 3.5 studs above the awning.
- "Wood Training" (6 x 1.5 studs, 2.5px stroke, `Chrome` style, small on purpose) on `Workspace.TrainingStand.TrainingBoard`, anchor about 4 studs above the board stack.

- "Geode" (14 x 4 studs and 4.9px stroke, same as Arm Shop; `Sky` blue style) on `Workspace.Model_Geode_Basic.Geode`, the geode sitting on the forest `GeodeStand` pedestal; anchor 3.5 studs above the geode's top. Added 2026-10-03. If the geode model is replaced or moved, the sign has to move with it.

The user wanted the training sign much smaller than the first pass (11 x 3.5) but the Arm Shop sign kept its original 14 x 4 size.

Authored in Studio, not code, so nothing static is applied by `Typography`; the colors are baked into the label.

Gotchas:
- Set an Attachment's `WorldPosition` after parenting it; before parenting the value is read as local and ends up at double the position.
- `screen_capture` does not draw BillboardGuis in Play or Edit (not even the real `RockLabel`), so a sign cannot be checked by eye through the MCP. Check properties and `WorldToViewportPoint` instead.

See [[UI Text Style]], [[Shop Stall Reference]].
