--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type RoksSettings = {
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unavailable: ShopConfig.MeterColors,
	},
	Preview: {
		CameraDirection: Vector3,
		FieldOfView: number,
		CameraPadding: number,
	},
	EmptyText: string,
	NoMatchText: string,
}

local RoksConfig: RoksSettings = {
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unavailable = ShopConfig.Palette.Grey,
	},
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
	EmptyText = "No Roks yet! Crack a geode",
	NoMatchText = "No Roks found",
}

return table.freeze(RoksConfig)
