--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockConfig = require(ReplicatedStorage.Config.RockConfig)

export type Rock = {
	Key: string,
	Config: RockConfig.Rock,
	Part: BasePart,
	Prompt: ProximityPrompt,
}

export type Session = {
	Rock: Rock,
	CanBreak: boolean,
	StrengthRatio: number,
	Health: number,
	MaxHealth: number,
	Center: number,
	StartTime: number?,
	Round: number,
}

return {}
