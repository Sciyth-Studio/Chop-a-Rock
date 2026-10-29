--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local Analytics = require(ServerScriptService.Utils.Analytics)
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local Packets = require(ReplicatedStorage.Packets)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Display = require(script.Display)
local Earnings = require(script.Earnings)
local Placement = require(script.Placement)
local Types = require(script.Types)

local PedestalService = {
	Name = "PedestalService",
	Collected = Signal.new() :: Signal.Signal<Player>,
	OfflineEarned = Signal.new() :: Signal.Signal<(Player, number, number)>,
}

local trove = Trove.new()
local context: Types.Context = { Services = {} }
local sessions: { [Player]: Types.Session } = {}
local setupPlots: { [Model]: boolean } = {}

local function slotKey(slot: number): string
	return tostring(slot)
end

local function refresh(player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	local session = sessions[player]
	if not data or not session then
		return
	end
	local now = Earnings.Now()
	local placed = PedestalSlots.Placed(data.Pets)
	local multiplier = services.IndexService:GetCashMultiplier(player)
	for _, slot in PedestalConfig.UnlockOrder do
		local earnings = session.Slots[slot]
		local petId = placed[slot]
		local rate = if petId then services.PetService:GetRate(data.Pets[petId]) * multiplier else 0
		if not earnings then
			earnings = Earnings.New(data.PedestalEarnings[slotKey(slot)] or 0, now)
			session.Slots[slot] = earnings
		end
		Earnings.SetRate(earnings, rate, now)
	end
	services.PetService:SyncTools(player)

	local plot = services.BaseService:GetPlot(player)
	if not plot then
		return
	end
	local isHolding = services.PetService:GetHeldPetId(player) ~= nil
	local nextSlot, nextPrice = PedestalSlots.Next(data.PedestalSlots)
	for slot, pedestal in Display.Pedestals(plot) do
		local isUnlocked = PedestalSlots.IsUnlocked(data.PedestalSlots, slot)
		local petId = if isUnlocked then placed[slot] else nil
		Display.Render(pedestal, player, {
			State = if not isUnlocked then "Locked" elseif petId then "Placed" else "Empty",
			PetKey = if petId then data.Pets[petId].Key else nil,
			Modifier = if petId then data.Pets[petId].Modifier else nil,
			Size = if petId then data.Pets[petId].Size else nil,
			Income = if petId then data.Pets[petId].Income else nil,
			Price = if slot == nextSlot then nextPrice else nil,
			Earnings = session.Slots[slot],
			CanPlace = isHolding,
		})
	end
end

local function flush(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local now = Earnings.Now()
	for slot, earnings in session.Slots do
		if earnings.Rate > 0 then
			context.Services.DataService:Set(
				player,
				{ "PedestalEarnings", slotKey(slot) },
				Earnings.Exact(earnings, now)
			)
		end
	end
end

local function collect(player: Player, slot: number)
	local session = sessions[player]
	local earnings = if session then session.Slots[slot] else nil
	if not session or not earnings then
		return
	end
	local clock = os.clock()
	if clock - (session.LastCollect[slot] or 0) < PedestalConfig.CollectCooldownSeconds then
		return
	end
	session.LastCollect[slot] = clock
	local now = Earnings.Now()
	if Earnings.Current(earnings, now) < 1 then
		return
	end
	local amount = Earnings.Take(earnings, now)
	local services = context.Services
	if not services.DataService:AdjustCash(player, amount) then
		earnings.Banked += amount
		return
	end
	local data = services.DataService:GetData(player)
	local pending = session.Offline[slot] or 0
	local offline = math.min(amount, math.floor(pending))
	if pending - offline >= 1 then
		session.Offline[slot] = pending - offline
	else
		session.Offline[slot] = nil
	end
	if data then
		Analytics.LogCash(player, AnalyticsConfig.Sources.Offline, offline, data.Cash - (amount - offline))
		Analytics.LogCash(player, AnalyticsConfig.Sources.Pad, amount - offline, data.Cash)
	end
	services.DataService:Set(player, { "PedestalEarnings", slotKey(slot) }, Earnings.Exact(earnings, now))
	Packets.PadCollected:FireClient(player)
	PedestalService.Collected:Fire(player)
	refresh(player)
end

local function onPromptTriggered(plot: Model, slot: number, player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data or services.BaseService:GetPlot(player) ~= plot then
		return
	end
	local changed = false
	if not PedestalSlots.IsUnlocked(data.PedestalSlots, slot) then
		if PedestalSlots.Next(data.PedestalSlots) == slot then
			changed = Placement.BuySlot(context, player)
		end
	elseif PedestalSlots.Placed(data.Pets)[slot] then
		changed = Placement.PickUp(context, player, slot)
	else
		local petId = services.PetService:GetHeldPetId(player)
		changed = petId ~= nil and Placement.Place(context, player, slot, petId)
	end
	if changed then
		services.DataService:RequestSave(player)
		refresh(player)
	end
end

local function onPadTouched(plot: Model, slot: number, hit: BasePart)
	local character = hit.Parent
	local player = if character then Players:GetPlayerFromCharacter(character) else nil
	if player and context.Services.BaseService:GetPlot(player) == plot then
		collect(player, slot)
	end
end

local function setupPlot(plot: Model)
	if setupPlots[plot] then
		return
	end
	setupPlots[plot] = true
	for slot, pedestal in Display.Pedestals(plot) do
		local prompt = Display.EnsurePrompt(pedestal)
		if prompt then
			trove:Add(prompt.Triggered:Connect(function(player: Player)
				onPromptTriggered(plot, slot, player)
			end))
		end
		local pad = Display.Pad(pedestal)
		if pad then
			trove:Add(pad.Touched:Connect(function(hit: BasePart)
				onPadTouched(plot, slot, hit)
			end))
		end
	end
end

local function clearPlot(plot: Model)
	for _, pedestal in Display.Pedestals(plot) do
		Display.Clear(pedestal)
	end
end

local function start(player: Player, isFirstLoad: boolean)
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	Placement.Sanitize(context, player)
	local session: Types.Session = { Slots = {}, LastCollect = {}, Offline = {} }
	sessions[player] = session
	if isFirstLoad then
		local seconds = Earnings.OfflineSeconds(data.LastSeenAt, os.time())
		if seconds > 0 then
			local placed = PedestalSlots.Placed(data.Pets)
			local multiplier = services.IndexService:GetCashMultiplier(player)
			local total = 0
			for slot, petId in placed do
				local key = slotKey(slot)
				local earned =
					Earnings.Offline(services.PetService:GetRate(data.Pets[petId]) * multiplier, seconds)
				total += earned
				session.Offline[slot] = earned
				services.DataService:Set(
					player,
					{ "PedestalEarnings", key },
					(data.PedestalEarnings[key] or 0) + earned
				)
			end
			PedestalService.OfflineEarned:Fire(player, total, seconds)
		end
	end
	refresh(player)
end

local function release(player: Player, data: any)
	local session = sessions[player]
	sessions[player] = nil
	if not session then
		return
	end
	local now = Earnings.Now()
	for slot, earnings in session.Slots do
		data.PedestalEarnings[slotKey(slot)] = Earnings.Exact(earnings, now)
	end
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

function PedestalService.CollectAll(_self: any, player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	for slot in session.Slots do
		collect(player, slot)
	end
end

function PedestalService.Refresh(_self: any, player: Player)
	refresh(player)
end

function PedestalService.ShowRok(_self: any, pedestal: Model, petKey: string?, scale: number?)
	Display.ShowRok(pedestal, petKey, scale)
end

function PedestalService.EquipBest(_self: any, player: Player): boolean
	return respond(player, Placement.EquipBest(context, player))
end

function PedestalService.GetIncomeRate(_self: any, player: Player): number
	local session = sessions[player]
	if not session then
		return 0
	end
	local total = 0
	for _, earnings in session.Slots do
		total += earnings.Rate
	end
	return total
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
	local services = context.Services
	local data = services.DataService:GetData(player)
	local session = sessions[player]
	if not data or not session then
		return 0
	end
	local capped = math.clamp(seconds, 0, EconomyConfig.OfflineCapSeconds)
	local multiplier = services.IndexService:GetCashMultiplier(player)
	local total = 0
	for slot, petId in PedestalSlots.Placed(data.Pets) do
		local earnings = session.Slots[slot]
		if earnings then
			local earned =
				Earnings.Offline(services.PetService:GetRate(data.Pets[petId]) * multiplier, capped)
			earnings.Banked += earned
			session.Offline[slot] = (session.Offline[slot] or 0) + earned
			total += earned
		end
	end
	PedestalService.OfflineEarned:Fire(player, total, capped)
	flush(player)
	refresh(player)
	return total
end

function PedestalService.ClearEarnings(_self: any, player: Player)
	local session = sessions[player]
	if session then
		local now = Earnings.Now()
		for _, earnings in session.Slots do
			earnings.Banked = 0
			earnings.BankedAt = now
		end
		table.clear(session.Offline)
	end
	context.Services.DataService:Set(player, { "PedestalEarnings" }, {})
	refresh(player)
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
		release(player, data)
	end)
	trove:Add(services.BaseService.PlotClaimed:Connect(function(player: Player, plot: Model)
		setupPlot(plot)
		refresh(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(_player: Player, plot: Model)
		clearPlot(plot)
	end))
	trove:Add(services.PetService.HeldChanged:Connect(refresh))
	trove:Add(services.PetService.ModifierChanged:Connect(refresh))
	trove:Add(services.IndexService.CashMultiplierChanged:Connect(refresh))
	local function autoEquip(player: Player)
		local data = services.DataService:GetData(player)
		if data and data.Settings.AutoEquip ~= false then
			respond(player, Placement.EquipBest(context, player))
		end
	end
	trove:Add(services.PetService.Granted:Connect(function(player: Player, equipDelay: number)
		if equipDelay > 0 then
			task.delay(equipDelay, autoEquip, player)
		else
			autoEquip(player)
		end
	end))
	for _, player in Players:GetPlayers() do
		local plot = services.BaseService:GetPlot(player)
		if plot then
			setupPlot(plot)
		end
	end

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
		while true do
			task.wait(PedestalConfig.FlushSeconds)
			for player in sessions do
				flush(player)
			end
		end
	end))
end

function PedestalService.Destroy(_self: any)
	Packets.UnequipPet.OnServerInvoke = nil
	Packets.EquipBestPets.OnServerInvoke = nil
	Packets.BuyPedestalSlot.OnServerInvoke = nil
	trove:Clean()
	for plot in setupPlots do
		clearPlot(plot)
	end
	table.clear(setupPlots)
end

return PedestalService
