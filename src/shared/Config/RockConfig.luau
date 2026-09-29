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
			DisplayName = "Pebble",
			StrengthRequired = 1,
			BasePayout = 10,
			RespawnSeconds = 0.8,
			PlaceholderPosition = Vector3.new(0, 3, 0),
			PlaceholderSize = Vector3.new(6, 6, 6),
			PlaceholderColor = Color3.fromRGB(120, 120, 120),
		} :: Rock,
		Second = {
			DisplayName = "Boulder",
			StrengthRequired = 10,
			BasePayout = 50,
			RespawnSeconds = 0.8,
			PlaceholderPosition = Vector3.new(30, 5, 0),
			PlaceholderSize = Vector3.new(10, 10, 10),
			PlaceholderColor = Color3.fromRGB(70, 70, 100),
		} :: Rock,
	},
}

return table.freeze(RockConfig)
