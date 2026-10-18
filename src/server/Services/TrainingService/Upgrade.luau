--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)

local Upgrade = {}

function Upgrade.Buy(services: { [string]: any }, player: Player): string
	local data = services.DataService:GetData(player)
	if not data then
		return "Failed"
	end
	local tier = TrainingStands.ClampTier(data.TrainingTier)
	local nextStand = TrainingStands.Next(tier)
	if not nextStand then
		return "Max"
	end
	if data.Rebirths < nextStand.Rebirths then
		return "Locked"
	end
	if data.Cash < nextStand.Price then
		return "Cash"
	end
	if not services.DataService:AdjustCash(player, -nextStand.Price) then
		return "Cash"
	end
	if not services.DataService:Set(player, { "TrainingTier" }, tier + 1) then
		return "Failed"
	end
	return "Upgraded"
end

function Upgrade.GrantStandCash(services: { [string]: any }, player: Player, tier: number): boolean
	local stand = TrainingStands.Get(tier)
	if stand.Price <= 0 then
		return true
	end
	return services.DataService:AdjustCash(player, stand.Price)
end

return Upgrade
