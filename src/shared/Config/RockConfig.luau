--!strict

export type Rock = {
	DisplayName: string,
	StrengthRequired: number,
	BasePayout: number,
	RespawnSeconds: number,
	TemplateKey: string,
	PlaceholderSize: Vector3,
	PlaceholderColor: Color3,
}

local RockConfig = {
	Rocks = {
		Basic = {
			DisplayName = "Stone",
			StrengthRequired = 2,
			BasePayout = 40,
			RespawnSeconds = 0.8,
			TemplateKey = "Model_Rock_Basic",
			PlaceholderSize = Vector3.new(6, 6, 6),
			PlaceholderColor = Color3.fromRGB(120, 120, 120),
		} :: Rock,
		Second = {
			DisplayName = "Boulder",
			StrengthRequired = 20,
			BasePayout = 200,
			RespawnSeconds = 0.8,
			TemplateKey = "Model_Rock_Second",
			PlaceholderSize = Vector3.new(10, 10, 10),
			PlaceholderColor = Color3.fromRGB(70, 70, 100),
		} :: Rock,
		Third = {
			DisplayName = "Mossy Boulder",
			StrengthRequired = 100,
			BasePayout = 800,
			RespawnSeconds = 0.8,
			TemplateKey = "Model_Rock_Third",
			PlaceholderSize = Vector3.new(14, 14, 14),
			PlaceholderColor = Color3.fromRGB(100, 100, 120),
		} :: Rock,
	},
}

return table.freeze(RockConfig)
