--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetModifier = require(ReplicatedStorage.PetModifier)

local PetValue = {}

function PetValue.Sell(petKey: string, modifier: string?): number
	return math.floor(PetModifier.Rate(petKey, modifier) * PetConfig.SellValueSeconds)
end

return PetValue
