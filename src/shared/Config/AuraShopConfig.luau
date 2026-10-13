--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type AuraShopSettings = {
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unaffordable: ShopConfig.MeterColors,
		Locked: ShopConfig.MeterColors,
		Owned: ShopConfig.MeterColors,
		Equipped: ShopConfig.MeterColors,
	},
	LockedText: string,
	InfoText: string,
	EquipText: string,
	EquippedText: string,
}

local AuraShopConfig: AuraShopSettings = {
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unaffordable = ShopConfig.Palette.Grey,
		Locked = ShopConfig.Palette.Grey,
		Owned = {
			Edge = Color3.fromRGB(0, 110, 255),
			Center = Color3.fromRGB(130, 205, 255),
			Studs = Color3.fromRGB(0, 60, 170),
		},
		Equipped = {
			Edge = Color3.fromRGB(230, 0, 0),
			Center = Color3.fromRGB(255, 120, 120),
			Studs = Color3.fromRGB(140, 0, 0),
		},
	},
	LockedText = "Rebirth {Rebirths}",
	InfoText = "+{Speed} Speed",
	EquipText = "Equip",
	EquippedText = "Equipped",
}

return table.freeze(AuraShopConfig)
