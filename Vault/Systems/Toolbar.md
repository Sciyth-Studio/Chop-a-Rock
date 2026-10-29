---
description: Custom Rok hotbar and the Roks inventory panel (built 2026-10-29 from the user's dinosaur-game reference); replaces the Roblox Backpack hotbar and the old pedestal-list Roks panel.
type: system
---
# Toolbar and Roks panel

Built 2026-10-29 to match a reference the user sent (another game's dino hotbar and inventory). The reference's separate "Q" slot is left out on purpose; the user asked for that.

## Hotbar (`StarterGui.Toolbar`, `Screens/Toolbar.luau`)
- `Toolbar` turns off `CoreGuiType.Backpack` and draws its own row. `Bar` is anchored bottom-centre at 1,-12 with a `ScreenScale`. It holds `RoksToggle` first (84px rounded square, white 3px border, dark green, "Roks" label on top, the bag icon below), then `ToolbarConfig.SlotCount` (7) clones of the hidden `SlotTemplate`.
- A slot is one stack of identical unplaced Roks (same key, modifier, size and $/s), sorted by $/s, best first. It shows the icon, the size tag top-left (hidden for Normal), the stack count top-right (Gold, hidden at 1) and the short name along the bottom (Chrome). The stack holding the tool in hand gets a white stroke.
- Clicking a slot or pressing 1-7 equips one tool from that stack with `Humanoid:EquipTool`, or puts it away if that stack is already in hand. Tools are still the `PetService/Tools` Backpack tools; nothing changed on the server.
- `HatchController` and `IntroController` hide it by closing the `Toolbar` screen (they used to toggle the Backpack CoreGui). It's in `IntroConfig.HiddenScreens`.

## Roks panel (`StarterGui.Roks`, `Screens/Roks.luau`)
- Translucent dark green rounded `Panel` (1000x520) inside `PopRoot`, bottom at 1,-116 so it sits just above the bar. Faded `Title` "Roks", `CountLabel` ("Roks: N   Placed: x/y"), `EquipBestButton` and `SlotButton` (the old block buttons, resized), the grey `Search` TextBox (placeholder "search") and `CloseButton` ("X"; the ✖ glyph rendered faint in the game font).
- `Grid` (6 columns of 146x150 cards) shows every Rok as stacks, placed and unplaced apart. A card has the size tag, a Gold count, the icon, a `PlacedBadge` on placed stacks (green stroke too), and a dark `Strip` with the name (Green style, or the modifier's colours) and the $/s. Clicking an unplaced card equips one from the hotbar stack; clicking a placed card picks one up off its pedestal (`UnequipPet`).
- Search filters on the full name ("Large Zappy Bloky"), case-insensitive, live as you type. `RoksConfig.EmptyText` / `NoMatchText` show when nothing matches.
- Stack building and painting live in `UIController/RokStacks.luau`, shared by both screens. Strokes and text formats are in `ToolbarConfig`.
- The `RoksButton` menu button is gone (`MenuButtonConfig`). Backups of the old panel and button: `ServerStorage.UIBackup.RoksBeforeToolbar` and `RoksButtonBeforeToolbar`.

## Tested 2026-10-29 (Play, worktree scripts pushed into Studio)
Seen on screen: the hotbar with icons, size tags (Enormous, Large), counts (4, 3, 2) and names; the panel with the faded title, count line, buttons, search box and cards with Placed badges. Checked by value: key 1 equipped Nesty; clicking slot 2 held Shroomy (white stroke on slot and card); search "bloky" gave the two Bloky stacks, "Enorm" one, "zzz" showed "No Roks found"; clicking the placed Berry card picked it up (Placed 3/3 → 2/3) and it moved into hotbar slot 1; Equip Best put it back; X closed the panel. Not checked: the hotbar hiding during a real geode crack and the intro, phone layout, gamepad.

Related: [[Pedestals]], [[Rok Sizes]], [[Item Icons]]
