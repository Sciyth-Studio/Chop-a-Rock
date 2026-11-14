--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)

export type ZoneStats = {
	FirstRequirement: number,
	TopStrength: number,
	TopPayout: number,
}

local ArenaShare = {}

function ArenaShare.ZoneStats(zone: string): ZoneStats?
	local zoneConfig = RockSpawnConfig.Zones[zone]
	if not zoneConfig then
		return nil
	end
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local first = math.huge
	local topStrength = -math.huge
	local topPayout = 0
	for key, weight in zoneConfig.Weights do
		local config = configs[key]
		if weight <= 0 or not config then
			continue
		end
		first = math.min(first, config.StrengthRequired)
		if config.StrengthRequired > topStrength then
			topStrength = config.StrengthRequired
			topPayout = config.BasePayout
		end
	end
	if first == math.huge then
		return nil
	end
	return { FirstRequirement = first, TopStrength = topStrength, TopPayout = topPayout }
end

function ArenaShare.BestZone(peakStrength: number): string?
	local best: string? = nil
	local bestOrder = math.huge
	local reached: string? = nil
	local reachedOrder = -math.huge
	for zone, geode in GeodeConfig.Geodes do
		if not RockSpawnConfig.Zones[zone] then
			continue
		end
		if geode.Order < bestOrder then
			best = zone
			bestOrder = geode.Order
		end
		if peakStrength >= geode.StrengthRequired and geode.Order > reachedOrder then
			reached = zone
			reachedOrder = geode.Order
		end
	end
	return reached or best
end

function ArenaShare.StatsFor(peakStrength: number): ZoneStats?
	local zone = ArenaShare.BestZone(peakStrength)
	return if zone then ArenaShare.ZoneStats(zone) else nil
end

return ArenaShare
