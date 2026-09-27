--!strict

export type Rock = {
	DisplayName: string,
	StrengthRequired: number,
	BasePayout: number,
	RespawnSeconds: number,
}

local RockConfig = {
	Rocks = {
		Basic = {
			DisplayName = "Pebble",
			StrengthRequired = 1,
			BasePayout = 10,
			RespawnSeconds = 0.8,
		} :: Rock,
		Second = {
			DisplayName = "Boulder",
			StrengthRequired = 10,
			BasePayout = 50,
			RespawnSeconds = 0.8,
		} :: Rock,
	},
}

return table.freeze(RockConfig)
