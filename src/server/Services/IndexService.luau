--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IndexConfig = require(ReplicatedStorage.Config.IndexConfig)
local IndexRewards = require(ReplicatedStorage.IndexRewards)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)

local IndexService = { Name = "IndexService" }

local services: { [string]: any } = {}

local function record(player: Player, kind: "Pets" | "Rocks", key: string): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	local counts: { [string]: number } = data.Index[kind]
	local count = counts[key] or 0
	services.DataService:Set(player, { "Index", kind, key }, count + 1)
	return count == 0
end

local function grant(player: Player, reward: IndexConfig.Reward)
	if reward.Cash > 0 then
		services.DataService:AdjustCash(player, reward.Cash)
	end
	if reward.Strength > 0 then
		services.StatsService:AddStrength(player, reward.Strength)
	end
end

function IndexService.RecordPet(_self: any, player: Player, petKey: string): boolean
	if not PetConfig.Pets[petKey] then
		return false
	end
	return record(player, "Pets", petKey)
end

function IndexService.RecordRock(_self: any, player: Player, rockKey: string): boolean
	if not RockConfig.Rocks[rockKey] then
		return false
	end
	return record(player, "Rocks", rockKey)
end

function IndexService.Claim(_self: any, player: Player, pageKey: string, key: string): boolean
	local data = services.DataService:GetData(player)
	local page = IndexRewards.FindPage(pageKey)
	if not data or not page or not IndexRewards.CanClaim(data.Index, page, key) then
		return false
	end
	local reward = IndexRewards.Reward(page, key)
	if not reward then
		return false
	end
	services.DataService:Set(player, { "Index", "Claimed", page.Kind, key }, true)
	grant(player, reward)
	services.DataService:RequestSave(player)
	return true
end

function IndexService.ClaimZone(_self: any, player: Player, pageKey: string, zoneKey: string): boolean
	local data = services.DataService:GetData(player)
	local page = IndexRewards.FindPage(pageKey)
	local zone = if page then IndexRewards.FindZone(page, zoneKey) else nil
	if not data or not page or not zone or not IndexRewards.CanClaimZone(data.Index, page, zone) then
		return false
	end
	services.DataService:Set(player, { "Index", "Claimed", "Zones", IndexRewards.ZoneId(page, zone) }, true)
	services.DataService:RequestSave(player)
	services.NotificationService:Notify(
		player,
		"Unlock",
		`{zone.DisplayName} {page.DisplayName} complete! +{math.floor(IndexConfig.ZoneCashBonus * 100 + 0.5)}% Money`
	)
	return true
end

function IndexService.ClaimAll(_self: any, player: Player): number
	local data = services.DataService:GetData(player)
	if not data then
		return 0
	end
	local claimed = 0
	for _, claim in IndexRewards.Claimable(data.Index) do
		local key = claim.Key
		local isClaimed = if key
			then IndexService:Claim(player, claim.Page.Key, key)
			else IndexService:ClaimZone(player, claim.Page.Key, claim.Zone.Key)
		if isClaimed then
			claimed += 1
		end
	end
	return claimed
end

function IndexService.GetCashMultiplier(_self: any, player: Player): number
	local data = services.DataService:GetData(player)
	return if data then IndexRewards.CashMultiplier(data.Index) else 1
end

function IndexService.ApplyCashMultiplier(_self: any, player: Player, amount: number): number
	return math.floor(amount * IndexService:GetCashMultiplier(player) + 0.5)
end

function IndexService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function IndexService.Start(_self: any)
	Packets.ClaimIndex.OnServerInvoke = function(player: Player, pageKey: string, key: string): boolean
		return IndexService:Claim(player, pageKey, key)
	end
	Packets.ClaimIndexZone.OnServerInvoke = function(
		player: Player,
		pageKey: string,
		zoneKey: string
	): boolean
		return IndexService:ClaimZone(player, pageKey, zoneKey)
	end
	Packets.ClaimAllIndex.OnServerInvoke = function(player: Player): number
		return math.min(IndexService:ClaimAll(player), 255)
	end
end

function IndexService.Destroy(_self: any)
	Packets.ClaimIndex.OnServerInvoke = nil
	Packets.ClaimIndexZone.OnServerInvoke = nil
	Packets.ClaimAllIndex.OnServerInvoke = nil
end

return IndexService
