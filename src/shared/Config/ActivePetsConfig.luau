--!strict

local ShopConfig = require(script.Parent.ShopConfig)

local ActivePetsConfig = {
	Screen = "ActivePets",
	TitleFormat = "%d/%d Active",
	StoredFormat = "%d stored",
	SlotFormat = "+1 Slot $%s",
	UnequipText = "Unequip",
	Unequip = {
		Edge = Color3.fromRGB(200, 0, 20),
		Center = Color3.fromRGB(255, 110, 110),
		Studs = Color3.fromRGB(120, 0, 10),
	} :: ShopConfig.MeterColors,
	Affordable = ShopConfig.Palette.Green,
	Unavailable = ShopConfig.Palette.Grey,
	EquipBest = ShopConfig.Palette.Green,
}

return table.freeze(ActivePetsConfig)
