--!strict

local Types = require(script.Parent.Types)

local EggLuck = {}

EggLuck.Base = 100

local function sortedTrimmed(list: { number }, count: number): { number }
	local copy = table.clone(list)
	table.sort(copy, function(a: number, b: number)
		return a > b
	end)
	while #copy > count do
		table.remove(copy)
	end
	return copy
end

function EggLuck.Add(context: Types.Context, player: Player, geodeKey: string, luck: number, amount: number)
	local dataService = context.Services.DataService
	local data = dataService:GetData(player)
	if not data then
		return
	end
	local list = table.clone(data.EggLuck[geodeKey] or {})
	for _ = 1, amount do
		table.insert(list, math.floor(luck + 0.5))
	end
	dataService:Set(player, { "EggLuck", geodeKey }, sortedTrimmed(list, data.Geodes[geodeKey] or 0))
end

function EggLuck.Best(data: any, geodeKey: string): number
	local list = data.EggLuck[geodeKey]
	local best = EggLuck.Base
	if list then
		for index, value in list do
			if index > (data.Geodes[geodeKey] or 0) then
				break
			end
			best = math.max(best, value)
		end
	end
	return best
end

function EggLuck.Take(context: Types.Context, player: Player, geodeKey: string, countAfter: number): number
	local dataService = context.Services.DataService
	local data = dataService:GetData(player)
	local list = if data then data.EggLuck[geodeKey] else nil
	if not list or #list == 0 then
		return EggLuck.Base
	end
	local sorted = sortedTrimmed(list, countAfter + 1)
	local best = table.remove(sorted, 1) or EggLuck.Base
	dataService:Set(player, { "EggLuck", geodeKey }, if #sorted > 0 then sorted else nil)
	return best
end

return EggLuck
