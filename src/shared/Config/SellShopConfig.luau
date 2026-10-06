--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type SortMode = {
	Key: "Value" | "Rarity" | "Newest",
	Label: string,
}

export type SellShopSettings = {
	Sorts: { SortMode },
	DescendingArrow: string,
	AscendingArrow: string,
	Palette: {
		Active: ShopConfig.MeterColors,
		Inactive: ShopConfig.MeterColors,
		Ready: ShopConfig.MeterColors,
		Disabled: ShopConfig.MeterColors,
	},
	SelectedStrokeColor: Color3,
	IdleStrokeColor: Color3,
	Preview: {
		CameraDirection: Vector3,
		FieldOfView: number,
		CameraPadding: number,
	},
}

local SellShopConfig: SellShopSettings = {
	Sorts = {
		{ Key = "Value", Label = "Value" },
		{ Key = "Rarity", Label = "Rarity" },
		{ Key = "Newest", Label = "Newest" },
	},
	DescendingArrow = "▼",
	AscendingArrow = "▲",
	Palette = {
		Active = ShopConfig.Palette.Green,
		Inactive = ShopConfig.Palette.Grey,
		Ready = ShopConfig.Palette.Green,
		Disabled = ShopConfig.Palette.Grey,
	},
	SelectedStrokeColor = Color3.fromRGB(0, 255, 60),
	IdleStrokeColor = Color3.fromRGB(0, 0, 0),
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
}

return table.freeze(SellShopConfig)
