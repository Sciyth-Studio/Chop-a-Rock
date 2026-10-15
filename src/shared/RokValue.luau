--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RokModifier = require(ReplicatedStorage.RokModifier)

local RokValue = {}

function RokValue.Sell(petKey: string, modifier: string?): number
	return math.floor(RokModifier.Rate(petKey, modifier) * PetConfig.SellValueSeconds)
end

return RokValue
