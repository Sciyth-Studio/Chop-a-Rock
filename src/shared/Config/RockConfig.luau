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
		DesertFirst = {
			DisplayName = "Sandstone",
			StrengthRequired = 500,
			BasePayout = 3200,
			RespawnSeconds = 0.8,
			TemplateKey = "Model_Rock_DesertFirst",
			PlaceholderSize = Vector3.new(7, 5, 6),
			PlaceholderColor = Color3.fromRGB(240, 190, 90),
		} :: Rock,
		DesertSecond = {
			DisplayName = "Canyon Boulder",
			StrengthRequired = 2500,
			BasePayout = 12800,
			RespawnSeconds = 0.8,
			TemplateKey = "Model_Rock_DesertSecond",
			PlaceholderSize = Vector3.new(12, 7, 10),
			PlaceholderColor = Color3.fromRGB(255, 120, 30),
		} :: Rock,
		DesertThird = {
			DisplayName = "Cactus Boulder",
			StrengthRequired = 12500,
			BasePayout = 51200,
			RespawnSeconds = 0.8,
			TemplateKey = "Model_Rock_DesertThird",
			PlaceholderSize = Vector3.new(19, 12, 17),
			PlaceholderColor = Color3.fromRGB(210, 50, 20),
		} :: Rock,
	},
}

return table.freeze(RockConfig)
