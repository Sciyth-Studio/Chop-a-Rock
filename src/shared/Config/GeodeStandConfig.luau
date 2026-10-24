--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type GeodeStandSettings = {
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unavailable: ShopConfig.MeterColors,
		LuckOn: ShopConfig.MeterColors,
		LuckOff: ShopConfig.MeterColors,
		TabActive: ShopConfig.MeterColors,
		TabIdle: ShopConfig.MeterColors,
	},
	TabStrengthFormat: string,
	Preview: {
		CameraDirection: Vector3,
		FieldOfView: number,
		CameraPadding: number,
	},
	OddsColor: Color3,
	GamepassOddsColor: Color3,
	HiddenColor: Color3,
	HiddenName: string,
	PityFormat: string,
	PityFillLighten: number,
	SingleButtonOffsetPixels: number,
	PairButtonOffsetPixels: number,
	ButtonCenterOffsetPixels: number,
}

local GeodeStandConfig: GeodeStandSettings = {
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unavailable = ShopConfig.Palette.Grey,
		LuckOn = {
			Edge = Color3.fromRGB(255, 170, 0),
			Center = Color3.fromRGB(255, 245, 130),
			Studs = Color3.fromRGB(190, 100, 0),
		},
		LuckOff = ShopConfig.Palette.Grey,
		TabActive = {
			Edge = Color3.fromRGB(0, 110, 255),
			Center = Color3.fromRGB(130, 205, 255),
			Studs = Color3.fromRGB(0, 60, 170),
		},
		TabIdle = ShopConfig.Palette.Grey,
	},
	TabStrengthFormat = "%s Strength",
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
	OddsColor = Color3.fromRGB(255, 255, 255),
	GamepassOddsColor = Color3.fromRGB(255, 200, 0),
	HiddenColor = Color3.fromRGB(0, 0, 0),
	HiddenName = "???",
	PityFormat = "%s in %s",
	PityFillLighten = 0.55,
	SingleButtonOffsetPixels = 0,
	PairButtonOffsetPixels = 162,
	ButtonCenterOffsetPixels = 92,
}

return table.freeze(GeodeStandConfig)
