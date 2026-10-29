---
description: Custom Rok hotbar and the Roks inventory panel (built 2026-10-29 from the user's dinosaur-game reference, restyled to the house style the same day); replaces the Roblox Backpack hotbar and the old pedestal-list Roks panel.
type: system
---
# Toolbar and Roks panel

Built 2026-10-29. The layout comes from a reference the user sent (another game's dino hotbar and inventory). The reference's separate "Q" slot is left out on purpose; the user asked for that. The first build copied the reference's look too (rounded translucent green); the user then asked for the house style ([[Menu Panel Style]], [[Tile Style Reference]]), so only the layout is the reference's. Backups of the reference look: `ServerStorage.UIBackup.RoksReferenceLook` and `ToolbarReferenceLook`.

## Hotbar (`StarterGui.Toolbar`, `Screens/Toolbar.luau`)
- `Toolbar` turns off `CoreGuiType.Backpack` and draws its own row. `Bar` is anchored bottom-centre at 1,-12 with a `ScreenScale`. It holds `RoksToggle` first, then `ToolbarConfig.SlotCount` (7) clones of the hidden `SlotTemplate`.
- `RoksToggle` is the old `RoksButton` menu tile at 84px (blue fill, bag icon, "Roks" label at the bottom with its shadow). `SlotTemplate` is the same tile with a grey fill, no icon shadow, `Icon`/`Preview`, `RokName` + `RokNameShadow` (Chrome), a white `SizeTag` top-left and a Gold `Count` top-right. Sharp corners, 3px black `OuterStroke`.
- A slot is one stack of identical unplaced Roks (same key, modifier, size and $/s), sorted by $/s, best first. Size tag hidden for Normal, count hidden at 1. The stack in hand gets a white outline.
- Clicking a slot or pressing 1-7 equips one tool from that stack with `Humanoid:EquipTool`, or puts it away if that stack is already in hand. Tools are still the `PetService/Tools` Backpack tools; nothing changed on the server.
- `HatchController` and `IntroController` hide it by closing the `Toolbar` screen (they used to toggle the Backpack CoreGui). It's in `IntroConfig.HiddenScreens`.

## Roks panel (`StarterGui.Roks`, `Screens/Roks.luau`)
- House panel, 1040x530 inside `PopRoot`, bottom at 1,-116 so it sits just above the bar: dark body (14,16,20 at 0.15), 5px black outline, no corners. `Header` is a copy of the Sell Shop's green block header with the bag icon overlapping the left, the title "Roks" in plain white with a 4px black stroke plus `TitleShadow` (white because the user asked, 2026-10-29), and the red block `CloseButton`.
- Under the header: `CountLabel` ("Roks: N   Placed: x/y", plain white), `EquipBestButton` and `SlotButton` (block buttons), and the `Search` TextBox (dark 28,28,30 box, 3px black outline, placeholder "search").
- `Grid` (6 columns of 146x150 cards). Cards copy the Sell Shop card: grey 58,58,62, `WeldTexture`, `InnerBorder`, 3px black outline (white when that stack is in hand, green when placed). Each has the white size tag, a Gold count, the icon, a square green `PlacedBadge` on placed stacks, and a dark `Strip` with the name (Green style, or the modifier's colours) and the $/s in plain white. Clicking an unplaced card equips one from that stack; clicking a placed card picks one up off its pedestal (`UnequipPet`).
- Search filters on the full name ("Large Zappy Bloky"), case-insensitive, live as you type. `RoksConfig.EmptyText` / `NoMatchText` show when nothing matches.
- Stack building and painting live in `UIController/RokStacks.luau`, shared by both screens. Strokes and text formats are in `ToolbarConfig`.
- The `RoksButton` menu button is gone (`MenuButtonConfig`). Backups of the old panel and button: `ServerStorage.UIBackup.RoksBeforeToolbar` and `RoksButtonBeforeToolbar`.

## Tested 2026-10-29 (Play, worktree scripts pushed into Studio)
Seen on screen: the house-style hotbar and panel (header, close button, cards with Placed badges and size tags, held stack outlined white). Checked by value earlier the same day: key 1 equipped Nesty; clicking a slot held that Rok; search "bloky" gave the two Bloky stacks, "Enorm" one, "zzz" showed "No Roks found"; clicking the placed Berry card picked it up (Placed 3/3 → 2/3) and it moved into hotbar slot 1; Equip Best put it back; X closed the panel. Not checked: the hotbar hiding during a real geode crack and the intro, phone layout, gamepad.

Related: [[Pedestals]], [[Rok Sizes]], [[Item Icons]]
