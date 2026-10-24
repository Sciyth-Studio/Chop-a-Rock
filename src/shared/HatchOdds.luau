--!strict

local GeodeConfig = require(script.Parent.Config.GeodeConfig)
local LuckConfig = require(script.Parent.Config.LuckConfig)
local PetConfig = require(script.Parent.Config.PetConfig)
local RarityConfig = require(script.Parent.Config.RarityConfig)

export type Chance = {
	PetKey: string,
	Chance: number,
}

local HatchOdds = {}

local function isLucky(petKey: string): boolean
	local pet = PetConfig.Pets[petKey]
	local rarity = if pet then RarityConfig.Rarities[pet.Rarity] else nil
	return rarity ~= nil and rarity.IsLucky
end

function HatchOdds.Chances(geodeKey: string, luck: number): { Chance }
	local chances: { Chance } = {}
	local geode = GeodeConfig.Geodes[geodeKey]
	if not geode then
		return chances
	end
	local totalWeight = 0
	for _, entry in geode.Pets do
		totalWeight += math.max(entry.Weight, 0)
	end
	if totalWeight <= 0 then
		return chances
	end
	local luckyShare = 0
	for _, entry in geode.Pets do
		if isLucky(entry.PetKey) then
			luckyShare += math.max(entry.Weight, 0) / totalWeight
		end
	end
	local factor = 1
	if luckyShare > 0 and luckyShare < 1 then
		factor = math.min(math.max(luck, 1), math.max(1, LuckConfig.LuckyShareCap / luckyShare))
	end
	local plainScale = if luckyShare < 1 then (1 - luckyShare * factor) / (1 - luckyShare) else 1
	for _, entry in geode.Pets do
		local base = math.max(entry.Weight, 0) / totalWeight
		local scale = if isLucky(entry.PetKey) then factor else plainScale
		table.insert(chances, { PetKey = entry.PetKey, Chance = base * scale })
	end
	return chances
end

function HatchOdds.Roll(random: Random, geodeKey: string, luck: number): string?
	local chances = HatchOdds.Chances(geodeKey, luck)
	local roll = random:NextNumber()
	local cumulative = 0
	local fallback: string? = nil
	for _, entry in chances do
		if entry.Chance > 0 then
			cumulative += entry.Chance
			fallback = entry.PetKey
			if roll < cumulative then
				return entry.PetKey
			end
		end
	end
	return fallback
end

function HatchOdds.RollAtLeast(random: Random, geodeKey: string, minRarity: string): string?
	local geode = GeodeConfig.Geodes[geodeKey]
	local minIndex = table.find(RarityConfig.Order, minRarity)
	if not geode or not minIndex then
		return nil
	end
	local eligible: { GeodeConfig.GeodePet } = {}
	local totalWeight = 0
	for _, entry in geode.Pets do
		local pet = PetConfig.Pets[entry.PetKey]
		local index = if pet then table.find(RarityConfig.Order, pet.Rarity) else nil
		if index and index >= minIndex and entry.Weight > 0 then
			table.insert(eligible, entry)
			totalWeight += entry.Weight
		end
	end
	if totalWeight <= 0 then
		return nil
	end
	local roll = random:NextNumber() * totalWeight
	for _, entry in eligible do
		roll -= entry.Weight
		if roll < 0 then
			return entry.PetKey
		end
	end
	return eligible[#eligible].PetKey
end

function HatchOdds.RollRarity(random: Random, geodeKey: string, rarity: string): string?
	local geode = GeodeConfig.Geodes[geodeKey]
	if not geode then
		return nil
	end
	local eligible: { GeodeConfig.GeodePet } = {}
	local totalWeight = 0
	for _, entry in geode.Pets do
		local pet = PetConfig.Pets[entry.PetKey]
		if pet and pet.Rarity == rarity and entry.Weight > 0 then
			table.insert(eligible, entry)
			totalWeight += entry.Weight
		end
	end
	if totalWeight <= 0 then
		return nil
	end
	local roll = random:NextNumber() * totalWeight
	for _, entry in eligible do
		roll -= entry.Weight
		if roll < 0 then
			return entry.PetKey
		end
	end
	return eligible[#eligible].PetKey
end

return table.freeze(HatchOdds)
