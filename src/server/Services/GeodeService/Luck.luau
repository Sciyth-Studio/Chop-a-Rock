--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LuckConfig = require(ReplicatedStorage.Config.LuckConfig)
local Types = require(script.Parent.Types)

local Luck = {}

function Luck.Total(context: Types.Context, player: Player): number
	local passMultiplier = if context.Services.PassService:Owns(player, "Luck")
		then LuckConfig.GamepassMultiplier
		else 1
	return passMultiplier + context.Services.BoostService:GetBonus(player, "Luck")
end

return Luck
