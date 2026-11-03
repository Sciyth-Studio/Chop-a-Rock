---
description: Custom Pet hotbar and the Pets inventory panel (built 2026-10-29 from the user's dinosaur-game reference, restyled to the house style the same day); replaces the Roblox Backpack hotbar and the old pedestal-list Pets panel.
type: system
updated: 2026-10-29
---
# Toolbar and Pets panel

Built 2026-10-29. The layout comes from a reference the user sent (another game's dino hotbar and inventory). The reference's separate "Q" slot is left out on purpose; the user asked for that. The first build copied the reference's look too (rounded translucent green); the user then asked for the house style ([[Menu Panel Style]], [[Tile Style Reference]]), so only the layout is the reference's. Backups of the reference look: `ServerStorage.UIBackup.PetsReferenceLook` and `ToolbarReferenceLook`.

## Hotbar (`StarterGui.Toolbar`, `Screens/Toolbar.luau`)
- `Toolbar` turns off `CoreGuiType.Backpack` and draws its own row. `Bar` is anchored bottom-centre at 1,-12 with a `ScreenScale` (104px tiles since the later 2026-10-29 pass, up from 84, so they are easier to tap on phones). It holds `PetsToggle` first, then `ToolbarConfig.SlotCount` (7) clones of the hidden `SlotTemplate`.
- `PetsToggle` is the old `PetsButton` menu tile (156px with a 120px icon since 2026-11-01, 1.5x the slots; `Bar` is 954 wide and its `UIListLayout` is bottom-aligned so the toggle grows upward) (blue fill, bag icon, "Pets" label at the bottom with its shadow). `SlotTemplate` is the same tile with a grey fill, no icon shadow, `Icon`/`Preview`, `PetName` + `PetNameShadow` (Chrome), a white `SizeTag` top-left and a Gold `Count` top-right. Sharp corners, 3px black `OuterStroke`.
- A slot is one stack of identical unplaced Pets (same key, modifier, size and $/s), sorted by $/s, best first. Size tag hidden for Normal, count hidden at 1. The stack in hand gets a white outline.
- Clicking a slot or pressing 1-7 equips one tool from that stack with `Humanoid:EquipTool`, or puts it away if that stack is already in hand. Tools are still the `PetService/Tools` Backpack tools; nothing changed on the server.
- Pressing ~ (`ToolbarConfig.PanelKey`, Backquote) opens or closes the Pets panel, like the old Roblox backpack (user asked 2026-10-29). Ignored while typing in chat or a text box, and while the toolbar is hidden.
- `HatchController` and `IntroController` hide it by closing the `Toolbar` screen (they used to toggle the Backpack CoreGui). It's in `IntroConfig.HiddenScreens`.

## Pets panel (`StarterGui.Pets`, `Screens/Pets.luau`)
- House panel, 1040x530 inside `PopRoot`, bottom at 1,-136 so it sits just above the bar: dark body (14,16,20 at 0.15), 5px black outline, no corners. `Header` is a copy of the Sell Shop's green block header with the bag icon overlapping the left, the title "Pets" in plain white with a 4px black stroke plus `TitleShadow` (white because the user asked, 2026-10-29), and the red block `CloseButton`.
- Under the header: `CountLabel` ("Pets: N   Placed: x/y", plain white), `EquipBestButton` and `SlotButton` (block buttons), and the `Search` TextBox (dark 28,28,30 box, 3px black outline, placeholder "search").
- `Grid` (5 columns of 180x186 cards with 120px icons; it was 6 columns of 146x150 before the user asked for bigger icons). Cards copy the Sell Shop card: grey 58,58,62, `WeldTexture`, `InnerBorder`, 3px black outline (white when that stack is in hand). Each has the white size tag, a Gold count, the icon and a dark `Strip` with the name (Green style, or the modifier's colours) and the $/s in plain white. Pets placed on pedestals are left out of the grid (user asked; they used to show with a `PlacedBadge`, which is now hidden and unused). The count line still says how many are placed.
- Hovering a card only darkens it: `CardTemplate` has the attribute `Feel = "NoGrow"` (`UIFeelConfig.FeelNoGrow`), which makes `ButtonFeel` skip the grow but keep the darken.

## Pet detail popup (`Pets.Panel.Detail`)
![[Pet Detail Popup Reference.png]]
- Clicking a card opens a popup off its bottom-right corner, 12px out diagonally (`DetailGapPixels`), so it never covers the clicked card or the tiles beside and below it (user asked, 2026-10-29). It flips to the left near the right edge, and above the card only when it would run off the bottom of the screen. (The first version flipped when it ran more than 110px past the panel bottom, which made the first row always open upward over the card.) The clicked card gets a gold 4px outline (`SelectedStroke`).
- To make it stand out from the panel (user: it "doesn't really pop out"): it pops in from 0.6 scale with a Back ease out of the card corner (`PopIn` UIScale), has a black drop shadow (`Shadow`, 8,10 offset, 45%), and its 4px `InnerBorder` takes the rarity colour. Body is the house stud body: 44,44,46, studs, 5px black outline, sharp corners, 300px wide, ZIndex 30+ (the Pets ScreenGui uses Global ZIndex).
- Top to bottom: the Pet name (Chrome), a `Tags` row with the size (its `PetSize` text style) and the modifier (`PetModifier.PaintLabel`), hidden when both are plain; "Earns when placed"; the rarity in its rarity colours (`RarityRibbon.Colors`, rainbow for Secret); the $/s (Green); and a green block `HoldButton` ("Hold" / "Put away") that equips or puts away one from that stack. Grey dividers sit between the info lines.
- Clicking a card no longer equips it directly (the hotbar and 1-7 still do). The popup closes when you click outside it, scroll the grid or close the panel, and follows the stack when the list refreshes. Texts and placement numbers are in `ToolbarConfig` (`DetailEarnsText`, `HoldText`, `PutAwayText`, `DetailGapPixels`, `DetailPopFromScale`, `DetailPopSeconds`, `SelectedStroke`).
- Backups from before this pass: `ServerStorage.UIBackup.ToolbarBeforeBigIcons` and `PetsBeforeBigIcons`.
- Search filters on the full name ("Large Zappy Bloky"), case-insensitive, live as you type. `PetsConfig.EmptyText` / `NoMatchText` show when nothing matches.
- Stack building and painting live in `UIController/PetStacks.luau`, shared by both screens. Strokes and text formats are in `ToolbarConfig`.
- The `PetsButton` menu button is gone (`MenuButtonConfig`). Backups of the old panel and button: `ServerStorage.UIBackup.PetsBeforeToolbar` and `PetsButtonBeforeToolbar`.

## Tested 2026-10-29 (Play, worktree scripts pushed into Studio)
Seen on screen: the house-style hotbar and panel (header, close button, cards with Placed badges and size tags, held stack outlined white). Checked by value earlier the same day: key 1 equipped Nesty; clicking a slot held that Pet; search "bloky" gave the two Bloky stacks, "Enorm" one, "zzz" showed "No Pets found"; clicking the placed Berry card picked it up (Placed 3/3 → 2/3) and it moved into hotbar slot 1; Equip Best put it back; X closed the panel. Not checked: the hotbar hiding during a real geode crack and the intro, phone layout, gamepad.

Related: [[Pedestals]], [[Pet Sizes]], [[Item Icons]]
