--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local Types = require(script.Parent.Types)

local Chopping = {}

local brokenEpsilon = 1e-6

function Chopping.Damage(strength: number, quality: number, multiplier: number): number
	if quality == ChopQuality.Master then
		return strength * ChopConfig.PerfectDamageMultiplier * DiamondRockConfig.MasterPerfectMultiplier
	end
	return strength * multiplier
end

function Chopping.Apply(diamond: Types.Diamond, damage: number): (number, number)
	local applied = math.min(damage, diamond.Health)
	diamond.Health -= applied
	local payout = math.max(0, math.floor(diamond.Value * applied / diamond.MaxHealth + 0.5))
	return applied, payout
end

function Chopping.IsBroken(diamond: Types.Diamond): boolean
	return diamond.Health <= brokenEpsilon
end

function Chopping.FreeSlot(diamond: Types.Diamond, center: Vector3, position: Vector3): number?
	local offset = position - center
	local playerAngle = math.atan2(offset.X, offset.Z)
	local best: number? = nil
	local bestGap = math.huge
	for slot = 1, DiamondRockConfig.Slots do
		if diamond.Slots[slot] then
			continue
		end
		local angle = (slot - 1) / DiamondRockConfig.Slots * math.pi * 2
		local gap = math.abs((playerAngle - angle + math.pi) % (math.pi * 2) - math.pi)
		if gap < bestGap then
			best = slot
			bestGap = gap
		end
	end
	return best
end

return Chopping
