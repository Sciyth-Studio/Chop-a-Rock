--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ArenaShare = require(ServerScriptService.Utils.ArenaShare)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Types = require(script.Parent.Types)

local Fight = {}

local brokenEpsilon = 1e-6

local payoutByQuality: { [number]: number } = {
	[ChopQuality.Bad] = ChopConfig.BadPayoutMultiplier,
	[ChopQuality.Mid] = ChopConfig.MidPayoutMultiplier,
	[ChopQuality.Good] = ChopConfig.GoodPayoutMultiplier,
	[ChopQuality.Great] = ChopConfig.GreatPayoutMultiplier,
	[ChopQuality.Perfect] = ChopConfig.PerfectPayoutMultiplier,
}

function Fight.Share(stats: ArenaShare.ZoneStats, strength: number): number
	return math.max(strength, stats.FirstRequirement)
		* ChopConfig.GoodDamageMultiplier
		* BossConfig.HealthChops
end

function Fight.RoundPay(
	stats: ArenaShare.ZoneStats,
	quality: number,
	strength: number,
	damageMultiplier: number
): number
	local rockHealth = math.max(stats.TopStrength * ChopConfig.HitsAtMinStrength, 1)
	local rockRound = if quality == ChopQuality.Master
		then stats.TopPayout * MasterChopConfig.PayoutMultiplier
		else stats.TopPayout * (payoutByQuality[quality] or 0) * math.min(
			1,
			strength * damageMultiplier / rockHealth
		)
	return math.max(0, math.floor(rockRound * BossConfig.RoundCashMultiplier + 0.5))
end

function Fight.Damage(strength: number, quality: number, multiplier: number): number
	if quality == ChopQuality.Master then
		return strength * ChopConfig.PerfectDamageMultiplier * DiamondRockConfig.MasterPerfectMultiplier
	end
	return strength * multiplier
end

function Fight.Apply(fight: Types.Fight, damage: number): number
	local floor = if fight.IsMad then 0 else fight.MaxHealth / 2
	local applied = math.clamp(damage, 0, math.max(fight.Health - floor, 0))
	fight.Health -= applied
	return applied
end

function Fight.IsBeaten(fight: Types.Fight): boolean
	return fight.IsMad and fight.Health <= brokenEpsilon
end

function Fight.ReachedHalf(fight: Types.Fight): boolean
	return not fight.IsMad and fight.Health <= fight.MaxHealth / 2 + brokenEpsilon
end

function Fight.AddShare(fight: Types.Fight, player: Player, share: number)
	if fight.Counted[player] or share <= 0 then
		return
	end
	fight.Counted[player] = share
	if fight.MaxHealth <= 0 then
		fight.MaxHealth = share
		fight.Health = share
		return
	end
	local ratio = fight.Health / fight.MaxHealth
	fight.MaxHealth += share
	fight.Health = ratio * fight.MaxHealth
end

function Fight.FreeSlot(spot: Types.Spot): number?
	for slot = 1, BossConfig.SlotsPerSpot do
		if not spot.Slots[slot] then
			return slot
		end
	end
	return nil
end

function Fight.FlatNormal(root: BasePart, spot: BasePart): Vector3
	local stored = spot:GetAttribute("Normal")
	local normal: Vector3 = if typeof(stored) == "Vector3"
		then root.CFrame:VectorToWorldSpace(stored)
		else spot.Position - root.Position
	local flat = Vector3.new(normal.X, 0, normal.Z)
	if flat.Magnitude < 1e-3 then
		local outward = spot.Position - root.Position
		flat = Vector3.new(outward.X, 0, outward.Z)
	end
	return if flat.Magnitude < 1e-3 then root.CFrame.LookVector else flat.Unit
end

return Fight
