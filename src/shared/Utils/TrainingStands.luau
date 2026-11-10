--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

local TrainingStands = {}

function TrainingStands.ClampTier(tier: any): number
	local value = if type(tier) == "number" then math.floor(tier) else 1
	return math.clamp(value, 1, #TrainingConfig.Stands)
end

function TrainingStands.Get(tier: any): TrainingConfig.Stand
	return TrainingConfig.Stands[TrainingStands.ClampTier(tier)]
end

function TrainingStands.Next(tier: any): TrainingConfig.Stand?
	return TrainingConfig.Stands[TrainingStands.ClampTier(tier) + 1]
end

return TrainingStands
