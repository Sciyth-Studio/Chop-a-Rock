--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local Types = require(script.Parent.Types)

local Chopping = {}

local brokenEpsilon = 1e-6

function Chopping.MaxHealth(strengthRequired: number): number
	return math.max(strengthRequired, 1) * ChopConfig.GoodDamageMultiplier * GeodeFallConfig.HealthChops
end

function Chopping.Damage(strength: number, quality: number, multiplier: number): number
	if quality == ChopQuality.Master then
		return strength * ChopConfig.PerfectDamageMultiplier * GeodeFallConfig.MasterPerfectMultiplier
	end
	return strength * multiplier
end

function Chopping.Apply(geode: Types.Geode, damage: number, quality: number): number
	local share = GeodeFallConfig.MaxShareByQuality[quality] or 1
	local applied = math.min(damage, geode.MaxHealth * share, geode.Health)
	geode.Health -= applied
	return applied
end

function Chopping.IsBroken(geode: Types.Geode): boolean
	return geode.Health <= brokenEpsilon
end

return Chopping
