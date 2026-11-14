--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopEffectConfig = require(ReplicatedStorage.Config.ChopEffectConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local ZoneScaleConfig = require(ReplicatedStorage.Config.ZoneScaleConfig)

local CutPower = {}

local zoneCount = #ZoneScaleConfig.Order
local rockZones: { [string]: number } = {}
for zone, zoneConfig in RockSpawnConfig.Zones do
	local index = table.find(ZoneScaleConfig.Order, zone)
	if index then
		for key in zoneConfig.Weights do
			rockZones[key] = index
		end
	end
end

local function zoneFraction(index: number): number
	return (index - 1) / math.max(zoneCount - 1, 1)
end

function CutPower.FurthestZone(peakStrength: number): number
	local furthest = 1
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for key, rock in rocks do
		local zone = rockZones[key]
		if zone and zone > furthest and rock.StrengthRequired <= peakStrength then
			furthest = zone
		end
	end
	return furthest
end

function CutPower.Of(peakStrength: number, rockKey: string?, strengthRatio: number, quality: number): number
	local furthest = CutPower.FurthestZone(peakStrength)
	local rockZone = if rockKey then rockZones[rockKey] or furthest else furthest
	local base = 1 + zoneFraction(furthest) * ChopEffectConfig.CutZoneStages
	local overkill = math.clamp(
		math.log(math.max(strengthRatio, 1)) / math.log(ChopEffectConfig.CutOverkillPerStage),
		0,
		1
	)
	local reach = ChopEffectConfig.CutOverkillReachMin
		+ (1 - ChopEffectConfig.CutOverkillReachMin) * zoneFraction(rockZone)
	local power = base + overkill * reach * ChopEffectConfig.CutOverkillStages
	if quality < ChopQuality.Perfect then
		power -= ChopEffectConfig.CutNormalPenalty
	end
	return math.clamp(power, 1, ChopEffectConfig.CutMaxPower)
end

return CutPower
