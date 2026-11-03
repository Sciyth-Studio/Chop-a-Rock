--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)

local GeodeOrder = {}

local function sorted(isRobuxOnly: boolean): { string }
	local keys: { string } = {}
	for key, geode in GeodeConfig.Geodes do
		if not geode.IsFalling and (geode.RobuxOnly == true) == isRobuxOnly then
			table.insert(keys, key)
		end
	end
	table.sort(keys, function(a: string, b: string): boolean
		return GeodeConfig.Geodes[a].Order < GeodeConfig.Geodes[b].Order
	end)
	return keys
end

local function sortedFalling(): { string }
	local keys: { string } = {}
	for key, geode in GeodeConfig.Geodes do
		if geode.IsFalling then
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

function GeodeOrder.FallingKey(baseKey: string): string?
	local key = GeodeConfig.FallingKeyPrefix .. baseKey
	local geode = GeodeConfig.Geodes[key]
	return if geode and geode.IsFalling then key else nil
end

function GeodeOrder.All(): { string }
	local keys: { string } = {}
	for _, group in { GeodeOrder.SortedLucky(), sortedFalling(), GeodeOrder.Sorted() } do
		for index = #group, 1, -1 do
			table.insert(keys, group[index])
		end
	end
	return keys
end

function GeodeOrder.Pick(geodes: { [string]: number }, selected: string?): string?
	if selected and GeodeConfig.Geodes[selected] and (geodes[selected] or 0) > 0 then
		return selected
	end
	for _, key in GeodeOrder.All() do
		if (geodes[key] or 0) > 0 then
			return key
		end
	end
	return nil
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
