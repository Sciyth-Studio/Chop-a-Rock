--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local Analytics = require(ServerScriptService.Utils.Analytics)
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local Packets = require(ReplicatedStorage.Packets)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Display = require(script.Display)
local Earnings = require(script.Earnings)
local Placement = require(script.Placement)
local Types = require(script.Types)

local PedestalService = {
	Name = "PedestalService",
	OfflineEarned = Signal.new() :: Signal.Signal<(Player, number, number)>,
}

local trove = Trove.new()
local context: Types.Context = { Services = {} }
local sessions: { [Player]: Types.Session } = {}

local function totalRate(player: Player, data: any): number
	local services = context.Services
	local multiplier = services.IndexService:GetCashMultiplier(player)
		* RebirthStats.Get(data.Rebirths).CashMultiplier
	local total = 0
	for _, petId in PedestalSlots.Placed(data.Pets) do
		total += services.PetService:GetRate(data.Pets[petId]) * multiplier
	end
	return total
end

local function refresh(player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	local session = sessions[player]
	if not data or not session then
		return
	end
	session.Rate = totalRate(player, data)
	services.PetService:SyncTools(player)
	local plot = services.BaseService:GetPlot(player)
	if not plot then
		return
	end
	local views: { [number]: Display.PenPetView } = {}
	for slot, petId in PedestalSlots.Placed(data.Pets) do
		local pet = data.Pets[petId]
		views[slot] = { PetKey = pet.Key, Modifier = pet.Modifier, Size = pet.Size, Income = pet.Income }
	end
	Display.RenderPen(plot, player, views)
end

local function logIncome(player: Player, data: any)
	local session = sessions[player]
	if session and session.Unlogged > 0 then
		Analytics.LogCash(player, AnalyticsConfig.Sources.Pad, Earnings.TakeUnlogged(session), data.Cash)
	end
end

local function payOffline(player: Player, seconds: number): number
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data or seconds <= 0 then
		return 0
	end
	local total = math.floor(Earnings.Offline(totalRate(player, data), seconds))
	if total > 0 then
		services.DataService:AdjustCash(player, total, AnalyticsConfig.Sources.Offline)
	end
	PedestalService.OfflineEarned:Fire(player, total, seconds)
	return total
end

local function equipBest(player: Player)
	if Placement.EquipBest(context, player) then
		context.Services.DataService:RequestSave(player)
		refresh(player)
	end
end

local function start(player: Player, isFirstLoad: boolean)
	local data = context.Services.DataService:GetData(player)
	if not data then
		return
	end
	Placement.Sanitize(context, player)
	sessions[player] = Earnings.New()
	equipBest(player)
	if isFirstLoad then
		payOffline(player, Earnings.OfflineSeconds(data.LastSeenAt, os.time()))
	end
	refresh(player)
end

local function respond(player: Player, changed: boolean): boolean
	if changed then
		context.Services.DataService:RequestSave(player)
		refresh(player)
	end
	return changed
end

function PedestalService.SetSlots(_self: any, player: Player, count: number): boolean
	local services = context.Services
	if not services.DataService:GetData(player) or count < 1 or count > PedestalSlots.Total() then
		return false
	end
	services.DataService:Set(player, { "PedestalSlots" }, count)
	Placement.Sanitize(context, player)
	return respond(player, true)
end

function PedestalService.Refresh(_self: any, player: Player)
	refresh(player)
end

function PedestalService.ShowPet(_self: any, pedestal: Model, petKey: string?, scale: number?)
	Display.ShowPet(pedestal, petKey, scale)
end

function PedestalService.EquipBest(_self: any, player: Player): boolean
	return respond(player, Placement.EquipBest(context, player))
end

function PedestalService.GetIncomeRate(_self: any, player: Player): number
	local session = sessions[player]
	return if session then session.Rate else 0
end

function PedestalService.EmptySlotCount(_self: any, player: Player): number
	local data = context.Services.DataService:GetData(player)
	if not data then
		return 0
	end
	local count = 0
	local placed = PedestalSlots.Placed(data.Pets)
	for _, slot in PedestalSlots.Unlocked(data.PedestalSlots) do
		if not placed[slot] then
			count += 1
		end
	end
	return count
end

function PedestalService.SimulateOffline(_self: any, player: Player, seconds: number): number
	return payOffline(player, math.clamp(seconds, 0, EconomyConfig.OfflineCapSeconds))
end

function PedestalService.Init(_self: any, registry: { [string]: any })
	context.Services = registry
end

function PedestalService.Start(_self: any)
	local services = context.Services
	local loaded: { [Player]: boolean } = {}
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		local isFirstLoad = not loaded[player]
		loaded[player] = true
		start(player, isFirstLoad)
	end)
	services.DataService.PlayerReleasing:Connect(function(player: Player, data: any)
		loaded[player] = nil
		logIncome(player, data)
		sessions[player] = nil
	end)
	trove:Add(services.BaseService.PlotClaimed:Connect(function(player: Player)
		refresh(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(_player: Player, plot: Model)
		Display.ClearPen(plot)
	end))
	trove:Add(services.PetService.HeldChanged:Connect(refresh))
	trove:Add(services.PetService.ModifierChanged:Connect(refresh))
	trove:Add(services.IndexService.CashMultiplierChanged:Connect(refresh))
	trove:Add(services.RebirthService.Reborn:Connect(function(player: Player)
		refresh(player)
	end))
	trove:Add(services.PetService.Granted:Connect(function(player: Player, equipDelay: number)
		if equipDelay > 0 then
			task.delay(equipDelay, equipBest, player)
		else
			equipBest(player)
		end
	end))

	Packets.UnequipPet.OnServerInvoke = function(player: Player, slot: number): boolean
		if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > PedestalSlots.Total() then
			return false
		end
		return respond(player, Placement.PickUp(context, player, slot))
	end
	Packets.EquipBestPets.OnServerInvoke = function(player: Player): boolean
		return respond(player, Placement.EquipBest(context, player))
	end
	Packets.BuyPedestalSlot.OnServerInvoke = function(player: Player): boolean
		return respond(player, Placement.BuySlot(context, player))
	end

	trove:Add(task.spawn(function()
		local sinceLog = 0
		while true do
			task.wait(PedestalConfig.IncomeTickSeconds)
			sinceLog += PedestalConfig.IncomeTickSeconds
			local shouldLog = sinceLog >= PedestalConfig.IncomeLogSeconds
			if shouldLog then
				sinceLog = 0
			end
			for player, session in sessions do
				local amount = Earnings.Tick(session, PedestalConfig.IncomeTickSeconds)
				if amount > 0 then
					services.DataService:AdjustCash(player, amount)
				end
				local data = if shouldLog then services.DataService:GetData(player) else nil
				if data then
					logIncome(player, data)
				end
			end
		end
	end))
end

function PedestalService.Destroy(_self: any)
	Packets.UnequipPet.OnServerInvoke = nil
	Packets.EquipBestPets.OnServerInvoke = nil
	Packets.BuyPedestalSlot.OnServerInvoke = nil
	trove:Clean()
end

return PedestalService
