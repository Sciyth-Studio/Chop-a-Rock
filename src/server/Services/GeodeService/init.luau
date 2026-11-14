--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local LuckConfig = require(ReplicatedStorage.Config.LuckConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local EggLuck = require(script.EggLuck)
local Effects = require(script.Effects)
local HatchPads = require(script.HatchPads)
local Luck = require(script.Luck)
local Opening = require(script.Opening)
local Tools = require(script.Tools)
local Types = require(script.Types)

local GeodeService = { Name = "GeodeService" }

local trove = Trove.new()
local context: Types.Context = { Services = {}, ForcedRarities = {} }
local random = Random.new()
local plots: { [Model]: { Types.Pad } } = {}
local placeAllPrompts: { [Model]: ProximityPrompt } = {}
local padLocks: { [BasePart]: number } = {}
local revealUntil: { [Player]: number } = {}
local luckyZones: { [Player]: string } = {}
local skipPauses: { [Player]: { [number]: number } } = {}
local skipPrompts: { [Player]: number } = {}
local skipProductIds: { [number]: boolean } = {}
for _, productId in MonetizationConfig.SkipHatch.Products do
	skipProductIds[productId] = true
end

local function isPadLocked(pad: Types.Pad): boolean
	return os.clock() < (padLocks[pad.Part] or 0)
end

local function pausedSeconds(player: Player, index: number, record: any): number?
	local pauses = skipPauses[player]
	local startedAt = if pauses then pauses[index] else nil
	if not startedAt then
		return nil
	end
	return math.max(0, record.ReadyAt - startedAt)
end

local function isReady(player: Player, index: number, record: any): boolean
	return pausedSeconds(player, index, record) == nil and HatchPads.IsReady(record)
end

local function publishLuck(player: Player)
	player:SetAttribute(LuckConfig.LuckAttribute, Luck.Total(context, player))
end

local function padsOf(player: Player): { Types.Pad }?
	local plot = context.Services.BaseService:GetPlot(player)
	return if plot then plots[plot] else nil
end

local function isReserved(player: Player, index: number): boolean
	local starterEgg = context.Services.StarterEggService
	return starterEgg ~= nil and starterEgg:PadIndexOf(player) == index
end

local function refresh(player: Player)
	local data = context.Services.DataService:GetData(player)
	local plot = context.Services.BaseService:GetPlot(player)
	local pads = if plot then plots[plot] else nil
	if not data or not plot or not pads then
		return
	end
	Tools.Sync(player, data.Geodes, function(key: string): number
		return EggLuck.Best(data, key)
	end)
	local nextGeode = GeodeOrder.Pick(data.Geodes, Tools.Held(player))
	local geode = if nextGeode then GeodeConfig.Geodes[nextGeode] else nil
	local empty = 0
	for index, pad in pads do
		local record = data.HatchPads[tostring(index)]
		if not record and isReserved(player, index) then
			HatchPads.Render(pad, player, nil, false, nil, false, nil)
			continue
		end
		if not record then
			empty += 1
		end
		HatchPads.Render(
			pad,
			player,
			record,
			not isPadLocked(pad),
			geode,
			HatchPads.CanSkip(data),
			if record then pausedSeconds(player, index, record) else nil
		)
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
	if not record and isReserved(player, index) then
		return
	elseif not record then
		HatchPads.Place(context, player, index, GeodeOrder.Pick(data.Geodes, Tools.Held(player)))
		services.DataService:RequestSave(player)
		refresh(player)
	elseif isReady(player, index, record) then
		if not services.PetService:CanAdd(player, 1) then
			services.NotificationService:Notify(player, "Error", "Bag full! Sell Pets", IconConfig.Backpack)
			return
		end
		local seconds = Opening.Open(context, player, record.GeodeKey, pad, random, record.Luck)
		if seconds then
			HatchPads.Clear(context, player, index)
			services.DataService:RequestSave(player)
			lockPad(player, pad, seconds)
		end
	elseif HatchPads.CanSkip(data) and pausedSeconds(player, index, record) == nil then
		local geode = GeodeConfig.Geodes[record.GeodeKey]
		if geode and services.PurchaseService:PromptSkipHatch(player, index, geode.TabName) then
			local pauses = skipPauses[player]
			if not pauses then
				pauses = {}
				skipPauses[player] = pauses
			end
			pauses[index] = os.time()
			skipPrompts[player] = index
			refresh(player)
		end
	end
end

local function resumeSkipPause(player: Player, index: number)
	local pauses = skipPauses[player]
	local startedAt = if pauses then pauses[index] else nil
	if not pauses or not startedAt then
		return
	end
	pauses[index] = nil
	local data = context.Services.DataService:GetData(player)
	local record = if data then data.HatchPads[tostring(index)] else nil
	if record then
		context.Services.DataService:Set(
			player,
			{ "HatchPads", tostring(index), "ReadyAt" },
			record.ReadyAt + math.max(0, os.time() - startedAt)
		)
	end
	refresh(player)
end

local function onPlaceAll(plot: Model, player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data or services.BaseService:GetPlot(player) ~= plot then
		return
	end
	for index, pad in plots[plot] do
		if not data.HatchPads[tostring(index)] and not isPadLocked(pad) and not isReserved(player, index) then
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

local plotBounds: { [Model]: { CFrame: CFrame, Size: Vector3 } } = {}

local function isOnPlot(player: Player, plot: Model): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return false
	end
	local bounds = plotBounds[plot]
	if not bounds then
		local cframe, size = plot:GetBoundingBox()
		bounds = { CFrame = cframe, Size = size }
		plotBounds[plot] = bounds
	end
	local offset = bounds.CFrame:PointToObjectSpace(root.Position)
	return math.abs(offset.X) <= bounds.Size.X / 2 and math.abs(offset.Z) <= bounds.Size.Z / 2
end

local function autoPlace(player: Player)
	local services = context.Services
	local data = services.DataService:GetData(player)
	local plot = services.BaseService:GetPlot(player)
	local pads = if plot then plots[plot] else nil
	if not data or not plot or not pads or HatchPads.OwnedCount(data) <= 0 then
		return
	end
	if services.RockService:HasSession(player) or not isOnPlot(player, plot) then
		return
	end
	local placed = false
	for index, pad in pads do
		if data.HatchPads[tostring(index)] or isPadLocked(pad) or isReserved(player, index) then
			continue
		end
		local geodeKey = GeodeOrder.Pick(data.Geodes, Tools.Held(player))
		if not geodeKey then
			break
		end
		if HatchPads.Place(context, player, index, geodeKey) then
			placed = true
		end
	end
	if placed then
		services.DataService:RequestSave(player)
		refresh(player)
	end
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
	local placeAll = HatchPads.SetupPlaceAll(plot)
	if placeAll then
		placeAllPrompts[plot] = placeAll
		trove:Add(placeAll)
		trove:Add(placeAll.Triggered:Connect(function(player: Player)
			onPlaceAll(plot, player)
		end))
	end
end

function GeodeService.GrantGeodes(
	_self: any,
	player: Player,
	geodeKey: string,
	amount: number,
	luck: number?
): boolean
	local data = context.Services.DataService:GetData(player)
	if not data or not GeodeConfig.Geodes[geodeKey] then
		return false
	end
	context.Services.DataService:Set(player, { "Geodes", geodeKey }, (data.Geodes[geodeKey] or 0) + amount)
	local boosted = (luck or EggLuck.Base) * context.Services.PotionService:LuckMultiplier(player)
	if boosted > EggLuck.Base then
		EggLuck.Add(context, player, geodeKey, boosted, amount)
	end
	context.Services.DataService:RequestSave(player)
	refresh(player)
	return true
end

function GeodeService.GetHeldKey(_self: any, player: Player): string?
	return Tools.Held(player)
end

function GeodeService.TakeOne(_self: any, player: Player, geodeKey: string): number?
	local data = context.Services.DataService:GetData(player)
	local count = if data then data.Geodes[geodeKey] or 0 else 0
	if not data or count < 1 then
		return nil
	end
	context.Services.DataService:Set(player, { "Geodes", geodeKey }, count - 1)
	local luck = EggLuck.Take(context, player, geodeKey, count - 1)
	context.Services.DataService:RequestSave(player)
	refresh(player)
	return luck
end

function GeodeService.Equip(_self: any, player: Player, geodeKey: string): boolean
	refresh(player)
	return Tools.Equip(player, geodeKey)
end

function GeodeService.Refresh(_self: any, player: Player)
	refresh(player)
end

function GeodeService.FreePadIndex(_self: any, player: Player): number?
	local data = context.Services.DataService:GetData(player)
	local pads = padsOf(player)
	if not data or not pads then
		return nil
	end
	for index, pad in pads do
		if not data.HatchPads[tostring(index)] and not isPadLocked(pad) then
			return index
		end
	end
	return nil
end

function GeodeService.GetPadSpot(_self: any, player: Player, index: number): Attachment?
	local pads = padsOf(player)
	local pad = if pads then pads[index] else nil
	return if pad then pad.Spot else nil
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

function GeodeService.SkipHatch(_self: any, player: Player, padIndex: number, zone: string): boolean
	local data = context.Services.DataService:GetData(player)
	local record = if data then data.HatchPads[tostring(padIndex)] else nil
	local geode = if record then GeodeConfig.Geodes[record.GeodeKey] else nil
	if not record or not geode or geode.TabName ~= zone or isReady(player, padIndex, record) then
		return false
	end
	local pauses = skipPauses[player]
	if pauses then
		pauses[padIndex] = nil
	end
	context.Services.DataService:Set(player, { "HatchPads", tostring(padIndex), "ReadyAt" }, os.time())
	refresh(player)
	return true
end

function GeodeService.IsHatching(_self: any, player: Player): boolean
	local data = context.Services.DataService:GetData(player)
	if not data then
		return false
	end
	for indexText, record in data.HatchPads do
		local index = tonumber(indexText)
		if index and not isReady(player, index, record) and pausedSeconds(player, index, record) == nil then
			return true
		end
	end
	return false
end

function GeodeService.AdvanceHatching(_self: any, player: Player, seconds: number)
	local data = context.Services.DataService:GetData(player)
	if not data or seconds <= 0 then
		return
	end
	local now = os.time()
	local changed = false
	for indexText, record in data.HatchPads do
		local index = tonumber(indexText)
		if index and record.ReadyAt > now and pausedSeconds(player, index, record) == nil then
			local readyAt = math.max(now, record.ReadyAt - seconds)
			context.Services.DataService:Set(player, { "HatchPads", indexText, "ReadyAt" }, readyAt)
			changed = true
		end
	end
	if changed then
		refresh(player)
	end
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
		publishLuck(player)
		refresh(player)
	end)
	services.DataService.PlayerReleasing:Connect(function(player: Player, data: any)
		local pauses = skipPauses[player]
		skipPauses[player] = nil
		if not pauses then
			return
		end
		for index, startedAt in pauses do
			local record = data.HatchPads[tostring(index)]
			if record then
				record.ReadyAt += math.max(0, os.time() - startedAt)
			end
		end
	end)
	trove:Connect(
		MarketplaceService.PromptProductPurchaseFinished,
		function(userId: number, productId: number, isPurchased: boolean)
			local player = Players:GetPlayerByUserId(userId)
			if not player or not skipProductIds[productId] then
				return
			end
			local index = skipPrompts[player]
			skipPrompts[player] = nil
			if index and not isPurchased then
				resumeSkipPause(player, index)
			end
		end
	)

	local elapsed = 0
	trove:Add(RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= GeodeConfig.HatchRefreshSeconds then
			elapsed = 0
			for _, player in Players:GetPlayers() do
				if services.DataService:GetData(player) then
					publishLuck(player)
				end
				if padsOf(player) then
					autoPlace(player)
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
		skipPrompts[player] = nil
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
	table.clear(padLocks)
	table.clear(revealUntil)
	table.clear(skipPrompts)
	Effects.Reset()
	trove:Clean()
end

return GeodeService
