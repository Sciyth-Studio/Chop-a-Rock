--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)

local GeodeOrder = {}

function GeodeOrder.Sorted(): { string }
	local keys: { string } = {}
	for key in GeodeConfig.Geodes do
		table.insert(keys, key)
	end
	table.sort(keys, function(a: string, b: string): boolean
		return GeodeConfig.Geodes[a].Order < GeodeConfig.Geodes[b].Order
	end)
	return keys
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
