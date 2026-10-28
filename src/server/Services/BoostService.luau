--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local BoostService = { Name = "BoostService" }

local TICK_SECONDS = 1

local services: { [string]: any } = {}
local trove = Trove.new()
local personal: { [Player]: { [string]: number } } = {}
local serverEnds: { [string]: number } = {}
local serverBuyers: { [string]: { string } } = {}
local lastTick = 0
local lastSave = 0

local boostsByKey: { [string]: MonetizationConfig.Boost } = {}
for _, boost in MonetizationConfig.Boosts do
	boostsByKey[boost.Key] = boost
end
local serverBoostsByKey: { [string]: MonetizationConfig.ServerBoost } = {}
for _, boost in MonetizationConfig.ServerBoosts do
	serverBoostsByKey[boost.Key] = boost
end

local function now(): number
	return workspace:GetServerTimeNow()
end

local function showPersonal(player: Player, key: string)
	local left = personal[player] and personal[player][key]
	local endsAt = if left and left > 0 then now() + left else nil
	player:SetAttribute(MonetizationConfig.BoostEndsAttributePrefix .. key, endsAt)
	if not endsAt then
		player:SetAttribute(MonetizationConfig.BoostPausedAttributePrefix .. key, nil)
	end
end

local function save(player: Player)
	local left = personal[player]
	local data = services.DataService:GetData(player)
	if not left or not data then
		return
	end
	for key in boostsByKey do
		local seconds = math.ceil(left[key] or 0)
		local stored = if seconds > 0 then seconds else nil
		if data.Boosts[key] ~= stored then
			services.DataService:Set(player, { "Boosts", key }, stored)
		end
	end
end

local function showServer(key: string)
	local endsAt = serverEnds[key]
	workspace:SetAttribute(MonetizationConfig.ServerBoostEndsAttributePrefix .. key, endsAt)
	local names = if endsAt
		then table.concat(serverBuyers[key] or {}, MonetizationConfig.ServerBoostNameSeparator)
		else nil
	workspace:SetAttribute(MonetizationConfig.ServerBoostByAttributePrefix .. key, names)
end

local function tick()
	local clock = os.clock()
	local elapsed = clock - lastTick
	if elapsed < TICK_SECONDS then
		return
	end
	lastTick = clock
	for player, left in personal do
		for key, seconds in left do
			local boost = boostsByKey[key]
			local isPaused = boost ~= nil
				and boost.OnlyWhileTraining == true
				and not services.TrainingService:IsTraining(player)
			local pausedAttribute = MonetizationConfig.BoostPausedAttributePrefix .. key
			local pausedValue = if isPaused then math.ceil(seconds) else nil
			if player:GetAttribute(pausedAttribute) ~= pausedValue then
				player:SetAttribute(pausedAttribute, pausedValue)
				if not isPaused then
					showPersonal(player, key)
				end
			end
			if isPaused then
				continue
			end
			local remaining = seconds - elapsed
			if remaining > 0 then
				left[key] = remaining
			else
				left[key] = nil
				showPersonal(player, key)
				save(player)
				Packets.BoostEnded:FireClient(player, key)
			end
		end
	end
	local serverNow = now()
	for key, endsAt in serverEnds do
		if endsAt <= serverNow then
			serverEnds[key] = nil
			serverBuyers[key] = nil
			showServer(key)
		end
	end
	if clock - lastSave >= MonetizationConfig.BoostSaveSeconds then
		lastSave = clock
		for player in personal do
			save(player)
		end
	end
end

function BoostService.AddPersonal(_self: any, player: Player, key: string, seconds: number): boolean
	local left = personal[player]
	if not left or not boostsByKey[key] or seconds <= 0 then
		return false
	end
	left[key] = math.min((left[key] or 0) + seconds, MonetizationConfig.BoostCapSeconds)
	showPersonal(player, key)
	save(player)
	return true
end

function BoostService.AddServer(_self: any, key: string, seconds: number, buyer: Player?): boolean
	if not serverBoostsByKey[key] or seconds <= 0 then
		return false
	end
	local serverNow = now()
	local endsAt = math.max(serverEnds[key] or serverNow, serverNow) + seconds
	serverEnds[key] = math.min(endsAt, serverNow + MonetizationConfig.ServerBoostCapSeconds)
	if buyer then
		local buyers = serverBuyers[key] or {}
		local existing = table.find(buyers, buyer.DisplayName)
		if existing then
			table.remove(buyers, existing)
		end
		table.insert(buyers, 1, buyer.DisplayName)
		while #buyers > MonetizationConfig.ServerBoostMaxNames do
			table.remove(buyers)
		end
		serverBuyers[key] = buyers
		Packets.PurchaseAnnounced:FireAllClients("ServerBoost", buyer.DisplayName, "", key)
	end
	showServer(key)
	return true
end

function BoostService.ClearPersonal(_self: any, player: Player): boolean
	local left = personal[player]
	if not left then
		return false
	end
	for key in left do
		left[key] = nil
		showPersonal(player, key)
	end
	save(player)
	return true
end

function BoostService.ClearServer(_self: any)
	for key in serverEnds do
		serverEnds[key] = nil
		serverBuyers[key] = nil
		showServer(key)
	end
end

function BoostService.GetBonus(_self: any, player: Player, key: string): number
	local bonus = 0
	local left = personal[player]
	if left and (left[key] or 0) > 0 then
		bonus += MonetizationConfig.BoostBonus
	end
	if (serverEnds[key] or 0) > now() then
		bonus += MonetizationConfig.ServerBoostBonus
	end
	return bonus
end

function BoostService.GetPersonalSeconds(_self: any, player: Player, key: string): number
	local left = personal[player]
	return if left then left[key] or 0 else 0
end

function BoostService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function BoostService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player, data: any)
		local left = {}
		for key, seconds in data.Boosts do
			if boostsByKey[key] and seconds > 0 then
				left[key] = math.min(seconds, MonetizationConfig.BoostCapSeconds)
			end
		end
		personal[player] = left
		for key in left do
			showPersonal(player, key)
		end
	end)
	services.DataService.PlayerReleasing:Connect(function(player: Player, data: any)
		local left = personal[player]
		if left then
			for key in boostsByKey do
				local seconds = math.ceil(left[key] or 0)
				data.Boosts[key] = if seconds > 0 then seconds else nil
			end
		end
		personal[player] = nil
	end)
	trove:Add(services.TutorialService.Finished:Connect(function(player: Player)
		local data = services.DataService:GetData(player)
		local offerKey = MonetizationConfig.TasteOfferKey
		if not data or data.Offers[offerKey] then
			return
		end
		services.DataService:Set(player, { "Offers", offerKey }, true)
		local boost = boostsByKey[MonetizationConfig.TasteBoostKey]
		if boost then
			BoostService:AddPersonal(player, boost.Key, MonetizationConfig.TasteSeconds)
		end
	end))
	lastTick = os.clock()
	lastSave = lastTick
	trove:Connect(RunService.Heartbeat, tick)
end

function BoostService.Destroy(_self: any)
	trove:Destroy()
	BoostService:ClearServer()
end

return BoostService
