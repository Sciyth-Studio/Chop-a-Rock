--!strict

local RokModifier = require(script.Parent.RokModifier)
local RokSizeConfig = require(script.Parent.Config.RokSizeConfig)

export type Chance = {
	Key: string,
	Chance: number,
}

local RokSize = {}

function RokSize.Get(size: string?): RokSizeConfig.Size
	local config = if size then RokSizeConfig.Sizes[size] else nil
	return config or RokSizeConfig.Sizes[RokSizeConfig.DefaultKey]
end

function RokSize.IsShown(size: string?): boolean
	return size ~= nil and size ~= RokSizeConfig.DefaultKey and RokSizeConfig.Sizes[size] ~= nil
end

function RokSize.Scale(size: string?): number
	return RokSize.Get(size).Scale
end

function RokSize.Chances(luck: number): { Chance }
	local totalWeight = 0
	for _, key in RokSizeConfig.Order do
		totalWeight += math.max(RokSizeConfig.Sizes[key].Weight, 0)
	end
	local chances: { Chance } = {}
	if totalWeight <= 0 then
		return chances
	end
	local bigShare = 0
	for _, key in RokSizeConfig.Order do
		if key ~= RokSizeConfig.DefaultKey then
			bigShare += math.max(RokSizeConfig.Sizes[key].Weight, 0) / totalWeight
		end
	end
	local factor = 1
	if bigShare > 0 and bigShare < 1 then
		factor = math.min(math.max(luck, 1), math.max(1, RokSizeConfig.MaxBigShare / bigShare))
	end
	local defaultScale = if bigShare < 1 then (1 - bigShare * factor) / (1 - bigShare) else 1
	for _, key in RokSizeConfig.Order do
		local base = math.max(RokSizeConfig.Sizes[key].Weight, 0) / totalWeight
		local scale = if key == RokSizeConfig.DefaultKey then defaultScale else factor
		table.insert(chances, { Key = key, Chance = base * scale })
	end
	return chances
end

function RokSize.Roll(random: Random, luck: number): string?
	local roll = random:NextNumber()
	local cumulative = 0
	for _, entry in RokSize.Chances(luck) do
		cumulative += entry.Chance
		if roll < cumulative then
			return if entry.Key == RokSizeConfig.DefaultKey then nil else entry.Key
		end
	end
	return nil
end

function RokSize.Name(petKey: string, modifier: string?, size: string?): string
	local name = RokModifier.Name(petKey, modifier)
	return if RokSize.IsShown(size) then `{RokSize.Get(size).DisplayName} {name}` else name
end

return table.freeze(RokSize)
