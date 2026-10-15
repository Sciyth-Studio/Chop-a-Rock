--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

local TrainingStands = {}

function TrainingStands.IndexForRebirths(rebirths: number): number
	local bestIndex = 1
	for index, stand in TrainingConfig.Stands do
		if rebirths >= stand.Rebirths and stand.Rebirths >= TrainingConfig.Stands[bestIndex].Rebirths then
			bestIndex = index
		end
	end
	return bestIndex
end

function TrainingStands.ForRebirths(rebirths: number): TrainingConfig.Stand
	return TrainingConfig.Stands[TrainingStands.IndexForRebirths(rebirths)]
end

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
