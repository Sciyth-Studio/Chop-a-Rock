--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LuckConfig = require(ReplicatedStorage.Config.LuckConfig)
local Types = require(script.Parent.Types)

local Luck = {}

function Luck.Total(context: Types.Context, player: Player, quality: number): number
	local data = context.Services.DataService:GetData(player)
	local rebirths = if data then data.Rebirths else 0
	local bonus = (LuckConfig.TimingBonusByQuality[quality] or 0) + rebirths * LuckConfig.PerRebirthBonus
	local multiplier = if context.GamepassOwners[player] then LuckConfig.GamepassMultiplier else 1
	return (1 + bonus) * multiplier
end

return Luck
