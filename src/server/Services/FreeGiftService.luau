--!strict

local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local FreeGiftConfig = require(ReplicatedStorage.Config.FreeGiftConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local FreeGiftService = { Name = "FreeGiftService" }

local services: { [string]: any } = {}
local trove = Trove.new()
local claiming: { [Player]: boolean } = {}
local results = FreeGiftConfig.Results

local function isInGroup(player: Player): boolean?
	local ok, groups = pcall(GroupService.GetGroupsAsync, GroupService, player.UserId)
	if not ok or type(groups) ~= "table" then
		return nil
	end
	for _, group in groups do
		if type(group) == "table" and group.Id == FreeGiftConfig.GroupId then
			return true
		end
	end
	return false
end

local function hasClaimed(player: Player): boolean?
	local data = services.DataService:GetData(player)
	if not data then
		return nil
	end
	return data.Offers[FreeGiftConfig.OfferKey] == true
end

local function claim(player: Player): string
	local claimed = hasClaimed(player)
	if claimed == nil then
		return results.Failed
	elseif claimed then
		return results.AlreadyClaimed
	end
	local isMember = isInGroup(player)
	if isMember == nil then
		return results.Failed
	elseif not isMember then
		return results.NotInGroup
	end
	local data = services.DataService:GetData(player)
	if not data then
		return results.Failed
	elseif data.Offers[FreeGiftConfig.OfferKey] == true then
		return results.AlreadyClaimed
	end
	services.DataService:Set(player, { "Offers", FreeGiftConfig.OfferKey }, true)
	local cash = CashPack.GeodeValue(FreeGiftConfig.Geodes, data.PeakStrength)
	if cash > 0 then
		services.DataService:AdjustCash(player, cash, AnalyticsConfig.Sources.FreeGift)
	end
	return results.Claimed
end

function FreeGiftService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function FreeGiftService.Start(_self: any)
	Packets.ClaimFreeGift.OnServerInvoke = function(player: Player): string
		if claiming[player] then
			return results.Failed
		end
		claiming[player] = true
		local ok, result = pcall(claim, player)
		claiming[player] = nil
		return if ok then result else results.Failed
	end
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		claiming[player] = nil
	end)
end

function FreeGiftService.Destroy(_self: any)
	Packets.ClaimFreeGift.OnServerInvoke = nil
	trove:Destroy()
end

return FreeGiftService
