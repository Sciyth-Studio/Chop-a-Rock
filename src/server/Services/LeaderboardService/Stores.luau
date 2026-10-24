--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)

export type Entry = {
	UserId: number,
	Value: number,
}

local Stores = {}

local stores: { [string]: OrderedDataStore } = {}
local warned = false

local function warnOnce(message: string)
	if warned then
		return
	end
	warned = true
	warn(`[LeaderboardService] {message}; boards show this server's players only`)
end

local function get(name: string): OrderedDataStore?
	local store = stores[name]
	if store then
		return store
	end
	local prefix = if RunService:IsStudio()
		then LeaderboardConfig.StudioStorePrefix
		else LeaderboardConfig.StorePrefix
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(prefix .. name)
	end)
	if not ok then
		warnOnce(tostring(result))
		return nil
	end
	stores[name] = result
	return result
end

function Stores.Name(key: string, week: number?): string
	return if week then `{LeaderboardConfig.WeeklyStorePrefix}{week}_{key}` else key
end

function Stores.Encode(value: number): number
	return math.floor(math.log10(math.max(value, 0) + 1) * LeaderboardConfig.EncodeScale + 0.5)
end

function Stores.Decode(encoded: number): number
	return math.max(0, 10 ^ (encoded / LeaderboardConfig.EncodeScale) - 1)
end

function Stores.Write(name: string, userId: number, encoded: number): boolean
	local store = get(name)
	if not store then
		return false
	end
	local ok, result = pcall(function()
		store:SetAsync(tostring(userId), encoded)
	end)
	if not ok then
		warnOnce(tostring(result))
	end
	return ok
end

function Stores.ReadTop(name: string, count: number): { Entry }?
	local store = get(name)
	if not store then
		return nil
	end
	local ok, result = pcall(function()
		return store:GetSortedAsync(false, count):GetCurrentPage()
	end)
	if not ok then
		warnOnce(tostring(result))
		return nil
	end
	local entries: { Entry } = {}
	for _, item in result do
		local userId = tonumber(item.key)
		if userId and type(item.value) == "number" then
			table.insert(entries, { UserId = userId, Value = Stores.Decode(item.value) })
		end
	end
	return entries
end

return Stores
