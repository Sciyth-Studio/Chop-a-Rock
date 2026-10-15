--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

export type Grant = (player: Player, services: { [string]: any }) -> boolean

local Products: { [number]: Grant } = {}

for tier, stand in TrainingConfig.Stands do
	if stand.RobuxProductId > 0 then
		Products[stand.RobuxProductId] = function(player: Player, services: { [string]: any }): boolean
			return services.TrainingService:GrantTier(player, tier)
		end
	end
end

return Products
