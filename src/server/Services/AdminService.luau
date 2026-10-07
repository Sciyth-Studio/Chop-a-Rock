--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local AdminService = { Name = "AdminService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local random = Random.new()

local function notify(player: Player, message: string)
	services.NotificationService:Notify(player, "Info", message)
end

local handlers: { [string]: (Player) -> () } = {
	GrantCash = function(player: Player)
		if services.DataService:AdjustCash(player, AdminConfig.CashAmount) then
			notify(player, `Admin: +{AdminConfig.CashAmount} cash`)
		end
	end,
	GrantPet = function(player: Player)
		local geodeKey = next(GeodeConfig.Geodes)
		local petKey = if geodeKey then HatchOdds.Roll(random, geodeKey, 1) else nil
		local grant = if petKey then services.PetService:Grant(player, petKey) else nil
		if not grant then
			notify(player, "Admin: no Rok granted")
			return
		end
		local pet = PetConfig.Pets[grant.PetKey]
		local trait = if grant.Trait then ` + {grant.Trait} {grant.TraitValue}` else ""
		notify(player, `Admin: {pet.DisplayName} ({pet.Rarity}){trait}{if grant.IsNew then " New" else ""}`)
	end,
	GrantGeode = function(player: Player)
		local geodeKey = next(GeodeConfig.Geodes)
		if geodeKey and services.GeodeService:GrantGeodes(player, geodeKey, 1) then
			notify(player, `Admin: +1 {GeodeConfig.Geodes[geodeKey].DisplayName}`)
		end
	end,
	ForceSecret = function(player: Player)
		services.GeodeService:ForceNextRarity(player, "Secret")
		notify(player, "Admin: next hatch is a Secret")
	end,
	ForceMaster = function(player: Player)
		services.RockService:ForceNextMaster(player)
		notify(player, "Admin: next chop is a Master")
	end,
	SpawnSpots = function(player: Player)
		local isShown = services.RockService:ToggleSpawnSpots(player)
		notify(player, if isShown then "Admin: spawn spots shown" else "Admin: spawn spots hidden")
	end,
	ResetData = function(player: Player)
		if services.DataService:ResetData(player) then
			notify(player, "Admin: data reset")
		end
	end,
}

function AdminService.IsAdmin(_self: any, player: Player): boolean
	return RunService:IsStudio() or table.find(AdminConfig.UserIds, player.UserId) ~= nil
end

function AdminService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function AdminService.Start(_self: any)
	local function mark(player: Player)
		if AdminService:IsAdmin(player) then
			player:SetAttribute(AdminConfig.AttributeName, true)
		end
	end
	for _, player in Players:GetPlayers() do
		mark(player)
	end
	trove:Add(Players.PlayerAdded:Connect(mark))
	trove:Add(Packets.AdminRun.OnServerEvent:Connect(function(player: Player, commandId: string)
		if not AdminService:IsAdmin(player) then
			return
		end
		local handler = handlers[commandId]
		if not handler then
			return
		end
		print(`[AdminService] {player.Name} ran {commandId}`)
		handler(player)
	end))
end

function AdminService.Destroy(_self: any)
	trove:Clean()
end

return AdminService
