--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Config.PetConfig)

local RokValue = {}

function RokValue.Sell(petKey: string): number
	local pet = PetConfig.Pets[petKey]
	return if pet then math.floor(pet.MoneyPerSecond * PetConfig.SellValueSeconds) else 0
end

return RokValue
