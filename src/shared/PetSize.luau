--!strict

local PetModifier = require(script.Parent.PetModifier)
local PetSizeConfig = require(script.Parent.Config.PetSizeConfig)

export type Chance = {
	Key: string,
	Chance: number,
}

local PetSize = {}

function PetSize.Get(size: string?): PetSizeConfig.Size
	local config = if size then PetSizeConfig.Sizes[size] else nil
	return config or PetSizeConfig.Sizes[PetSizeConfig.DefaultKey]
end

function PetSize.IsShown(size: string?): boolean
	return size ~= nil and size ~= PetSizeConfig.DefaultKey and PetSizeConfig.Sizes[size] ~= nil
end

function PetSize.Scale(size: string?): number
	return PetSize.Get(size).Scale
end

local function isBig(key: string): boolean
	return PetSizeConfig.Sizes[key].Scale > PetSizeConfig.Sizes[PetSizeConfig.DefaultKey].Scale
end

function PetSize.Chances(luck: number): { Chance }
	local totalWeight = 0
	for _, key in PetSizeConfig.Order do
		totalWeight += math.max(PetSizeConfig.Sizes[key].Weight, 0)
	end
	local chances: { Chance } = {}
	if totalWeight <= 0 then
		return chances
	end
	local bigShare = 0
	for _, key in PetSizeConfig.Order do
		if isBig(key) then
			bigShare += math.max(PetSizeConfig.Sizes[key].Weight, 0) / totalWeight
		end
	end
	local factor = 1
	if bigShare > 0 and bigShare < 1 then
		factor = math.min(math.max(luck, 1), math.max(1, PetSizeConfig.MaxBigShare / bigShare))
	end
	local smallScale = if bigShare < 1 then (1 - bigShare * factor) / (1 - bigShare) else 1
	for _, key in PetSizeConfig.Order do
		local base = math.max(PetSizeConfig.Sizes[key].Weight, 0) / totalWeight
		local scale = if isBig(key) then factor else smallScale
		table.insert(chances, { Key = key, Chance = base * scale })
	end
	return chances
end

function PetSize.Roll(random: Random, luck: number): string?
	local roll = random:NextNumber()
	local cumulative = 0
	for _, entry in PetSize.Chances(luck) do
		cumulative += entry.Chance
		if roll < cumulative then
			return if entry.Key == PetSizeConfig.DefaultKey then nil else entry.Key
		end
	end
	return nil
end

function PetSize.Name(petKey: string, modifier: string?, size: string?): string
	local name = PetModifier.Name(petKey, modifier)
	return if PetSize.IsShown(size) then `{PetSize.Get(size).DisplayName} {name}` else name
end

return table.freeze(PetSize)
