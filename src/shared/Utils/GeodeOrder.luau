--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)

local GeodeOrder = {}

local function sorted(isRobuxOnly: boolean): { string }
	local keys: { string } = {}
	for key, geode in GeodeConfig.Geodes do
		if (geode.RobuxOnly == true) == isRobuxOnly then
			table.insert(keys, key)
		end
	end
	table.sort(keys, function(a: string, b: string): boolean
		return GeodeConfig.Geodes[a].Order < GeodeConfig.Geodes[b].Order
	end)
	return keys
end

function GeodeOrder.Sorted(): { string }
	return sorted(false)
end

function GeodeOrder.SortedLucky(): { string }
	return sorted(true)
end

function GeodeOrder.LuckyKey(baseKey: string): string?
	local key = GeodeConfig.LuckyKeyPrefix .. baseKey
	local geode = GeodeConfig.Geodes[key]
	return if geode and geode.RobuxOnly then key else nil
end

function GeodeOrder.ForStrength(strength: number): string?
	local keys = GeodeOrder.Sorted()
	local best: string? = keys[1]
	for _, key in keys do
		if strength >= GeodeConfig.Geodes[key].StrengthRequired then
			best = key
		end
	end
	return best
end

return GeodeOrder
