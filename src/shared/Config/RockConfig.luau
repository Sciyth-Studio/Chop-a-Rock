--!strict

export type Rock = {
	DisplayName: string,
	StrengthRequired: number,
	BasePayout: number,
	RespawnSeconds: number,
	PlaceholderPosition: Vector3,
	PlaceholderSize: Vector3,
	PlaceholderColor: Color3,
}

local RockConfig = {
	Rocks = {
		Basic = {
			DisplayName = "Stone",
			StrengthRequired = 1,
			BasePayout = 40,
			RespawnSeconds = 0.8,
			PlaceholderPosition = Vector3.new(0, 3, 0),
			PlaceholderSize = Vector3.new(6, 6, 6),
			PlaceholderColor = Color3.fromRGB(120, 120, 120),
		} :: Rock,
		Second = {
			DisplayName = "Boulder",
			StrengthRequired = 10,
			BasePayout = 200,
			RespawnSeconds = 0.8,
			PlaceholderPosition = Vector3.new(30, 5, 0),
			PlaceholderSize = Vector3.new(10, 10, 10),
			PlaceholderColor = Color3.fromRGB(70, 70, 100),
		} :: Rock,
		Third = {
			DisplayName = "Mossy Boulder",
			StrengthRequired = 50,
			BasePayout = 800,
			RespawnSeconds = 0.8,
			PlaceholderPosition = Vector3.new(65, 7, 0),
			PlaceholderSize = Vector3.new(14, 14, 14),
			PlaceholderColor = Color3.fromRGB(100, 100, 120),
		} :: Rock,
	},
}

return table.freeze(RockConfig)
