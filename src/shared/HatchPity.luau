--!strict

local GeodeConfig = require(script.Parent.Config.GeodeConfig)
local RarityConfig = require(script.Parent.Config.RarityConfig)

export type Counts = { [string]: number }

local HatchPity = {}

local function misses(counts: any, rarity: string): number
	local value = if type(counts) == "table" then counts[rarity] else nil
	return if type(value) == "number" then value else 0
end

function HatchPity.Threshold(geodeKey: string, rarity: string): number?
	local geode = GeodeConfig.Geodes[geodeKey]
	local pity = if geode then geode.Pity else nil
	return if pity then pity[rarity] else nil
end

function HatchPity.Due(geodeKey: string, counts: any): string?
	for _, rarity in GeodeConfig.PityRarities do
		local threshold = HatchPity.Threshold(geodeKey, rarity)
		if threshold and misses(counts, rarity) + 1 >= threshold then
			return rarity
		end
	end
	return nil
end

function HatchPity.After(geodeKey: string, counts: any, hatchedRarity: string): Counts
	local hatchedIndex = table.find(RarityConfig.Order, hatchedRarity) or 0
	local after: Counts = {}
	for _, rarity in GeodeConfig.PityRarities do
		if HatchPity.Threshold(geodeKey, rarity) then
			local index = table.find(RarityConfig.Order, rarity) or math.huge
			after[rarity] = if hatchedIndex >= index then 0 else misses(counts, rarity) + 1
		end
	end
	return after
end

function HatchPity.Left(geodeKey: string, counts: any, rarity: string): number?
	local threshold = HatchPity.Threshold(geodeKey, rarity)
	if not threshold then
		return nil
	end
	return math.max(1, threshold - misses(counts, rarity))
end

return table.freeze(HatchPity)
