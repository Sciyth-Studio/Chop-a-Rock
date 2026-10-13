--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local AuraService = { Name = "AuraService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local aurasByKey: { [string]: AuraConfig.Aura } = {}

for _, aura in AuraConfig.Auras do
	aurasByKey[aura.Key] = aura
end

local function apply(player: Player)
	local data = services.DataService:GetData(player)
	local aura = if data then aurasByKey[data.EquippedAura] else nil
	if aura and not data.Auras[aura.Key] then
		aura = nil
	end
	services.WalkSpeedService:SetBonus(
		player,
		AuraConfig.SpeedSource,
		if aura then aura.WalkSpeedBonus else 0
	)
	player:SetAttribute(AuraConfig.Attribute, if aura then aura.Key else nil)
end

function AuraService.Buy(_self: any, player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	local aura = aurasByKey[key]
	if not data or not aura or data.Auras[key] then
		return false
	end
	if data.Rebirths < aura.RebirthsRequired or data.Cash < aura.Price then
		return false
	end
	if not services.DataService:AdjustCash(player, -aura.Price) then
		return false
	end
	services.DataService:Set(player, { "Auras", key }, true)
	services.DataService:Set(player, { "EquippedAura" }, key)
	apply(player)
	services.NotificationService:Notify(player, "Purchase", `Bought {aura.DisplayName}!`)
	services.DataService:RequestSave(player)
	return true
end

function AuraService.Equip(_self: any, player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	if not data or (key ~= "" and not data.Auras[key]) then
		return false
	end
	services.DataService:Set(player, { "EquippedAura" }, key)
	apply(player)
	services.DataService:RequestSave(player)
	return true
end

function AuraService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function AuraService.Start(_self: any)
	trove:Add(services.DataService.PlayerLoaded:Connect(function(player: Player)
		apply(player)
	end))
	for _, player in Players:GetPlayers() do
		if services.DataService:GetData(player) then
			apply(player)
		end
	end
	Packets.BuyAura.OnServerInvoke = function(player: Player, key: string): boolean
		return AuraService:Buy(player, key)
	end
	Packets.EquipAura.OnServerInvoke = function(player: Player, key: string): boolean
		return AuraService:Equip(player, key)
	end
end

function AuraService.Destroy(_self: any)
	Packets.BuyAura.OnServerInvoke = nil
	Packets.EquipAura.OnServerInvoke = nil
	trove:Clean()
end

return AuraService
