--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type GeodeStandSettings = {
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unavailable: ShopConfig.MeterColors,
		LuckOn: ShopConfig.MeterColors,
		LuckOff: ShopConfig.MeterColors,
	},
	Preview: {
		CameraDirection: Vector3,
		FieldOfView: number,
		CameraPadding: number,
	},
	OddsColor: Color3,
	GamepassOddsColor: Color3,
	HiddenColor: Color3,
	HiddenName: string,
	SingleButtonOffsetPixels: number,
	PairButtonOffsetPixels: number,
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
	},
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
	OddsColor = Color3.fromRGB(255, 255, 255),
	GamepassOddsColor = Color3.fromRGB(255, 200, 0),
	HiddenColor = Color3.fromRGB(0, 0, 0),
	HiddenName = "???",
	SingleButtonOffsetPixels = 0,
	PairButtonOffsetPixels = 162,
}

return table.freeze(GeodeStandConfig)
