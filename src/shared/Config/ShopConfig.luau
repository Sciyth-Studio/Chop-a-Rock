--!strict

export type MeterColors = {
	Edge: Color3,
	Center: Color3,
	Studs: Color3,
}

local ShopConfig = {
	Palette = {
		Green = {
			Edge = Color3.fromRGB(0, 190, 40),
			Center = Color3.fromRGB(150, 255, 120),
			Studs = Color3.fromRGB(0, 120, 20),
		},
		Grey = {
			Edge = Color3.fromRGB(120, 120, 120),
			Center = Color3.fromRGB(215, 215, 215),
			Studs = Color3.fromRGB(70, 70, 70),
		},
		Orange = {
			Edge = Color3.fromRGB(255, 110, 0),
			Center = Color3.fromRGB(255, 205, 120),
			Studs = Color3.fromRGB(170, 60, 0),
		},
	} :: { [string]: MeterColors },
	Preview = {
		ModelKey = "Model_ArmPreview",
		CameraDirection = Vector3.new(0.25, 0.3, 1),
		FieldOfView = 30,
		CameraPadding = 0.8,
	},
	PriceLabel = {
		WithIcon = {
			Position = UDim2.new(0, 64, 0.5, 0),
			Size = UDim2.new(1, -76, 1, -24),
			AnchorPoint = Vector2.new(0, 0.5),
		},
		WithoutIcon = {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -24, 1, -24),
			AnchorPoint = Vector2.new(0.5, 0.5),
		},
	},
}

return table.freeze(ShopConfig)
