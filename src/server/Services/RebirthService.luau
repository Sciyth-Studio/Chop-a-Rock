--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local RebirthConfig = require(ReplicatedStorage.Config.RebirthConfig)
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RebirthService = {
	Name = "RebirthService",
	Reborn = Signal.new() :: Signal.Signal<(Player, number)>,
}
local services: { [string]: any } = {}

local function current(player: Player): RebirthConfig.Rebirth?
	local data = services.DataService:GetData(player)
	if not data or data.Rebirths <= 0 then
		return nil
	end
	return RebirthStats.Get(data.Rebirths)
end

function RebirthService.GetCashMultiplier(_self: any, player: Player): number
	local rebirth = current(player)
	return if rebirth then rebirth.CashMultiplier else 1
end

function RebirthService.ApplyCashMultiplier(_self: any, player: Player, amount: number): number
	return math.floor(amount * RebirthService:GetCashMultiplier(player) + 0.5)
end

function RebirthService.Rebirth(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not data or not replica then
		return false
	end
	local nextRebirth = RebirthStats.Get(data.Rebirths + 1)
	if data.Strength < nextRebirth.StrengthRequired then
		return false
	end
	local values: { [string]: any } = { Rebirths = data.Rebirths + 1 }
	if RebirthConfig.ResetCash then
		values.Cash = 0
	end
	if RebirthConfig.ResetStrength then
		values.Strength = 0
	end
	replica:SetValues({}, values)
	if RebirthConfig.ResetCash then
		services.PedestalService:ClearEarnings(player)
	end
	if RebirthConfig.ResetAuraTier then
		services.AuraService:SetTier(player, 1)
	end
	services.DataService:RequestSave(player)
	print(`[RebirthService] {player.Name} rebirthed: rebirths={data.Rebirths}`)
	RebirthService.Reborn:Fire(player, data.Rebirths)
	return true
end

function RebirthService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function RebirthService.Start(_self: any)
	Packets.Rebirth.OnServerInvoke = function(player: Player): boolean
		return RebirthService:Rebirth(player)
	end
end

function RebirthService.Destroy(_self: any)
	Packets.Rebirth.OnServerInvoke = nil
end

return RebirthService
