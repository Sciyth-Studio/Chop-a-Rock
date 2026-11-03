--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Effects = require(script.Effects)
local HatchPads = require(script.HatchPads)
local Opening = require(script.Opening)
local Tools = require(script.Tools)
local Types = require(script.Types)

local GeodeService = { Name = "GeodeService" }

local trove = Trove.new()
local context: Types.Context = { Services = {}, ForcedRarities = {} }
local random = Random.new()
local plots: { [Model]: { Types.Pad } } = {}
local placeAllPrompts: { [Model]: ProximityPrompt } = {}
local oddsPrompts: { [Model]: ProximityPrompt } = {}
local padLocks: { [BasePart]: number } = {}
local revealUntil: { [Player]: number } = {}
local luckyZones: { [Player]: string } = {}

local function isPadLocked(pad: Types.Pad): boolean
	return os.clock() < (padLocks[pad.Part] or 0)
end

local function padsOf(player: Player): { Types.Pad }?
	local plot = context.Services.BaseService:GetPlot(player)
	return if plot then plots[plot] else nil
end

local function refresh(player: Player)
	local data = context.Services.DataService:GetData(player)
	local plot = context.Services.BaseService:GetPlot(player)
	local pads = if plot then plots[plot] else nil
	if not data or not plot or not pads then
		return
	end
	Tools.Sync(player, data.Geodes)
	local nextGeode = GeodeOrder.Pick(data.Geodes, Tools.Held(player))
	local geode = if nextGeode then GeodeConfig.Geodes[nextGeode] else nil
	local empty = 0
	for index, pad in pads do
		local record = data.HatchPads[tostring(index)]
		if not record then
			empty += 1
		end
		HatchPads.Render(pad, player, record, not isPadLocked(pad), geode)
	end
	local odds = oddsPrompts[plot]
	if odds then
		odds:SetAttribute("OwnerUserId", player.UserId)
		odds:SetAttribute("Active", not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)))
	end
	local placeAll = placeAllPrompts[plot]
	if placeAll then
		placeAll:SetAttribute("OwnerUserId", player.UserId)
		placeAll:SetAttribute("Active", empty > 1 and HatchPads.OwnedCount(data) > 1)
	end
end

local function lockPad(player: Player, pad: Types.Pad, seconds: number)
	local now = os.clock()
	padLocks[pad.Part] = now + seconds
	revealUntil[player] = math.max(revealUntil[player] or 0, now + seconds)
	refresh(player)
	task.delay(seconds, function()
		if player.Parent then
			refresh(player)
		end
	end)
end

local function onPad(plot: Model, index: number, player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	if
		not data
		or services.BaseService:GetPlot(player) ~= plot
		or services.RockService:HasSession(player)
	then
		return
	end
	local pad = plots[plot][index]
	if isPadLocked(pad) then
		return
	end
	local record = data.HatchPads[tostring(index)]
	if not record then
		HatchPads.Place(context, player, index, GeodeOrder.Pick(data.Geodes, Tools.Held(player)))
		services.DataService:RequestSave(player)
		refresh(player)
	elseif HatchPads.IsReady(record) then
		if not services.PetService:CanAdd(player, 1) then
			services.NotificationService:Notify(player, "Error", "Bag full! Sell Pets", IconConfig.Backpack)
			return
		end
		local seconds = Opening.Open(context, player, record.GeodeKey, pad, random)
		if seconds then
			HatchPads.Clear(context, player, index)
			services.DataService:RequestSave(player)
			lockPad(player, pad, seconds)
		end
	end
end

local function onPlaceAll(plot: Model, player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data or services.BaseService:GetPlot(player) ~= plot then
		return
	end
	for index, pad in plots[plot] do
		if not data.HatchPads[tostring(index)] and not isPadLocked(pad) then
			local geodeKey = GeodeOrder.Pick(data.Geodes)
			if not geodeKey then
				break
			end
			HatchPads.Place(context, player, index, geodeKey)
		end
	end
	services.DataService:RequestSave(player)
	refresh(player)
end

local function setupPlot(plot: Model)
	if plots[plot] then
		return
	end
	local pads = HatchPads.Setup(plot)
	plots[plot] = pads
	for index, pad in pads do
		trove:Add(pad.Prompt)
		trove:Add(pad.Spot)
		trove:Add(pad.Prompt.Triggered:Connect(function(player: Player)
			onPad(plot, index, player)
		end))
	end
	local odds = HatchPads.SetupOdds(plot)
	if odds then
		oddsPrompts[plot] = odds
		trove:Add(odds)
	end
	local placeAll = HatchPads.SetupPlaceAll(plot)
	if placeAll then
		placeAllPrompts[plot] = placeAll
		trove:Add(placeAll)
		trove:Add(placeAll.Triggered:Connect(function(player: Player)
			onPlaceAll(plot, player)
		end))
	end
end

function GeodeService.GrantGeodes(_self: any, player: Player, geodeKey: string, amount: number): boolean
	local data = context.Services.DataService:GetData(player)
	if not data or not GeodeConfig.Geodes[geodeKey] then
		return false
	end
	context.Services.DataService:Set(player, { "Geodes", geodeKey }, (data.Geodes[geodeKey] or 0) + amount)
	context.Services.DataService:RequestSave(player)
	refresh(player)
	return true
end

function GeodeService.HasBagRoom(_self: any, player: Player): boolean
	local data = context.Services.DataService:GetData(player)
	if not data then
		return false
	end
	local held = context.Services.PetService:Count(player) + HatchPads.OwnedCount(data)
	for _ in data.HatchPads do
		held += 1
	end
	return held < context.Services.PassService:GetBackpackSize(player)
end

function GeodeService.SkipHatch(_self: any, player: Player, padIndex: number): boolean
	local data = context.Services.DataService:GetData(player)
	local record = if data then data.HatchPads[tostring(padIndex)] else nil
	if not record or HatchPads.IsReady(record) then
		return false
	end
	context.Services.DataService:Set(player, { "HatchPads", tostring(padIndex), "ReadyAt" }, os.time())
	refresh(player)
	return true
end

local function luckyKeyFor(player: Player, data: any): string?
	local chosen = luckyZones[player]
	local chosenGeode = if chosen then GeodeConfig.Geodes[chosen] else nil
	local baseKey = if chosenGeode and data.PeakStrength >= chosenGeode.StrengthRequired
		then chosen
		else GeodeOrder.ForStrength(data.PeakStrength)
	return if baseKey then GeodeOrder.LuckyKey(baseKey) else nil
end

function GeodeService.GrantLucky(_self: any, player: Player, amount: number): string?
	local data = context.Services.DataService:GetData(player)
	local luckyKey = if data then luckyKeyFor(player, data) else nil
	if not luckyKey or not GeodeService:GrantGeodes(player, luckyKey, amount) then
		return nil
	end
	return luckyKey
end

function GeodeService.IsRevealing(_self: any, player: Player): boolean
	return os.clock() < (revealUntil[player] or 0)
end

function GeodeService.ForceNextRarity(_self: any, player: Player, rarityKey: string)
	context.ForcedRarities[player] = rarityKey
end

function GeodeService.Init(_self: any, registry: { [string]: any })
	context.Services = registry
end

function GeodeService.Start(_self: any)
	local services = context.Services
	trove:Add(services.BaseService.PlotClaimed:Connect(function(player: Player, plot: Model)
		setupPlot(plot)
		refresh(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(_player: Player, plot: Model)
		local pads = plots[plot]
		if pads then
			for _, pad in pads do
				HatchPads.ClearDisplay(pad)
			end
		end
		local placeAll = placeAllPrompts[plot]
		if placeAll then
			placeAll:SetAttribute("OwnerUserId", nil)
			placeAll:SetAttribute("Active", false)
		end
	end))
	for _, player in Players:GetPlayers() do
		local plot = services.BaseService:GetPlot(player)
		if plot then
			setupPlot(plot)
			refresh(player)
		end
	end
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		refresh(player)
	end)

	local elapsed = 0
	trove:Add(RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= GeodeConfig.HatchRefreshSeconds then
			elapsed = 0
			for _, player in Players:GetPlayers() do
				if padsOf(player) then
					refresh(player)
				end
			end
		end
	end))
	trove:Add(Packets.SetLuckyGeodeZone.OnServerEvent:Connect(function(player: Player, baseKey: string)
		local geode = if type(baseKey) == "string" then GeodeConfig.Geodes[baseKey] else nil
		if geode and not geode.RobuxOnly then
			luckyZones[player] = baseKey
		end
	end))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		revealUntil[player] = nil
		luckyZones[player] = nil
		context.ForcedRarities[player] = nil
	end))
end

function GeodeService.Destroy(_self: any)
	for _, pads in plots do
		for _, pad in pads do
			HatchPads.ClearDisplay(pad)
		end
	end
	table.clear(plots)
	table.clear(placeAllPrompts)
	table.clear(oddsPrompts)
	table.clear(padLocks)
	table.clear(revealUntil)
	Effects.Reset()
	trove:Clean()
end

return GeodeService
