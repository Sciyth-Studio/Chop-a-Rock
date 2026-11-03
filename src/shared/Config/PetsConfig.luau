--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type PetsSettings = {
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

local PetsConfig: PetsSettings = {
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unavailable = ShopConfig.Palette.Grey,
	},
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
	EmptyText = "No Pets yet! Crack a geode",
	NoMatchText = "No Pets found",
}

return table.freeze(PetsConfig)
