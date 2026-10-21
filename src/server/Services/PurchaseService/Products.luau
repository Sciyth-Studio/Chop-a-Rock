--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)

export type Grant = (player: Player, services: { [string]: any }) -> boolean

local Products: { [number]: Grant } = {}

for _, pack in CashPackConfig.Packs do
	Products[pack.ProductId] = function(player: Player, services: { [string]: any }): boolean
		local data = services.DataService:GetData(player)
		if not data then
			return false
		end
		local amount = CashPack.Value(pack, data.Strength)
		if amount <= 0 then
			return false
		end
		return services.DataService:AdjustCash(player, amount)
	end
end

return Products
