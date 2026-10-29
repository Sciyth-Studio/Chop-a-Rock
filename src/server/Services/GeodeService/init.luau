--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AutoOpenConfig = require(ReplicatedStorage.Config.AutoOpenConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local Packets = require(ReplicatedStorage.Packets)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Trove = require(ReplicatedStorage.Packages.Trove)
local AutoOpen = require(script.AutoOpen)
local Cracking = require(script.Cracking)
local Effects = require(script.Effects)
local Purchasing = require(script.Purchasing)
local Types = require(script.Types)

local PIT_PROMPT_NAME = "CrackPrompt"
local PICK_PROMPT_NAME = "PickPrompt"
local OWNED_PROMPT_TAG = "OwnedPrompt"

local GeodeService = { Name = "GeodeService" }

local trove = Trove.new()
local context: Types.Context = { Services = {}, ForcedRarities = {} }
local random = Random.new()
local sessions: { [Player]: Types.Session } = {}
local pitPrompts: { [Attachment]: ProximityPrompt } = {}
local pickPrompts: { [Attachment]: ProximityPrompt } = {}
local autoPrompts: { [Attachment]: ProximityPrompt } = {}
local autoCounts: { [Player]: number } = {}
local pits: { [Attachment]: Types.Pit } = {}
local lockedUntil: { [Player]: number } = {}
local luckyZones: { [Player]: string } = {}

local function isLocked(player: Player): boolean
	return os.clock() < (lockedUntil[player] or 0)
end

local function ensurePit(spot: Attachment, modelKey: string): Types.Pit?
	local pit = pits[spot]
	if pit and pit.ModelKey == modelKey and pit.Model.Parent then
		return pit
	end
	if pit then
		pit.Model:Destroy()
		pits[spot] = nil
	end
	local prepared = Effects.Prepare(modelKey, spot)
	if prepared then
		pits[spot] = prepared
	end
	return prepared
end

local function setCracking(player: Player, isCracking: boolean)
	player:SetAttribute(GeodeConfig.CrackingAttribute, if isCracking then true else nil)
end

local function endSession(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	setCracking(player, false)
	Effects.Hide(session.Model, 0)
end

local function stopAuto(player: Player, message: string?)
	if not autoCounts[player] then
		return
	end
	autoCounts[player] = nil
	player:SetAttribute(AutoOpenConfig.RunningAttribute, nil)
	player:SetAttribute(AutoOpenConfig.CountAttribute, nil)
	local session = sessions[player]
	if session and session.IsAuto then
		endSession(player)
	end
	if message then
		local kind = if message == AutoOpenConfig.DoneText or message == AutoOpenConfig.StoppedText
			then "Info"
			else "Error"
		context.Services.NotificationService:Notify(player, kind, message)
	end
end

local function autoPromptText(player: Player): string
	if context.Services.PassService:Owns(player, AutoOpenConfig.PassKey) then
		return AutoOpenConfig.PromptText
	end
	local pass = context.Services.PassService:GetPass(AutoOpenConfig.PassKey)
	return if pass
		then string.format(AutoOpenConfig.PromptPriceFormat, MonetizationConfig.RobuxGlyph, pass.RobuxPrice)
		else AutoOpenConfig.PromptText
end

local function refreshPit(player: Player)
	local spot = context.Services.BaseService:GetCrackSpot(player)
	local prompt = if spot then pitPrompts[spot] else nil
	local data = context.Services.DataService:GetData(player)
	if not prompt or not data then
		return
	end
	local count = Purchasing.UnopenedCount(data)
	local geodeKey = Cracking.PickGeode(data)
	local geode = if geodeKey then GeodeConfig.Geodes[geodeKey] else nil
	if geode and spot and not sessions[player] then
		ensurePit(spot, geode.ModelKey)
	end
	local isIdle = sessions[player] == nil and not isLocked(player) and not autoCounts[player]
	prompt.ObjectText = if geode then geode.DisplayName else ""
	prompt.ActionText = `Crack ({count} left)`
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt:SetAttribute("Active", count > 0 and isIdle)
	local pickPrompt = if spot then pickPrompts[spot] else nil
	if pickPrompt then
		pickPrompt:SetAttribute("OwnerUserId", player.UserId)
		pickPrompt:SetAttribute("Active", Purchasing.OwnedKinds(data) > 1 and isIdle)
	end
	local autoPrompt = if spot then autoPrompts[spot] else nil
	if autoPrompt then
		local ownsPass = context.Services.PassService:Owns(player, AutoOpenConfig.PassKey)
		autoPrompt.ActionText = autoPromptText(player)
		autoPrompt.HoldDuration = if ownsPass then ChopConfig.PromptHoldSeconds else 0
		autoPrompt:SetAttribute("OwnerUserId", player.UserId)
		autoPrompt:SetAttribute(
			"Active",
			count > 0 and isIdle and not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
		)
	end
end

local releaseLock: (Player, number) -> ()

local function autoCrack(player: Player)
	if not autoCounts[player] or sessions[player] then
		return
	end
	local spot = context.Services.BaseService:GetCrackSpot(player)
	if not spot then
		stopAuto(player, AutoOpenConfig.StoppedText)
		return
	end
	local geodeKey, stopMessage = AutoOpen.Next(context, player, spot)
	local geode = if geodeKey then GeodeConfig.Geodes[geodeKey] else nil
	local pit = if geode then ensurePit(spot, geode.ModelKey) else nil
	local session = if geodeKey and pit
		then Cracking.Begin(context, player, geodeKey, spot, pit, random, true)
		else nil
	if not session then
		stopAuto(player, stopMessage or AutoOpenConfig.StoppedText)
		refreshPit(player)
		return
	end
	sessions[player] = session
	setCracking(player, true)
	refreshPit(player)
	task.delay(AutoOpenConfig.StartDelaySeconds, function()
		if sessions[player] ~= session then
			return
		end
		sessions[player] = nil
		local data = context.Services.DataService:GetData(player)
		local before = if data then data.Geodes[session.GeodeKey] or 0 else 0
		local lockSeconds = Cracking.Finish(context, player, session, random, AutoOpen.RollQuality(random))
		local after = if data then data.Geodes[session.GeodeKey] or 0 else 0
		local count = autoCounts[player]
		if count and after < before then
			autoCounts[player] = count + 1
			player:SetAttribute(AutoOpenConfig.CountAttribute, count + 1)
		end
		releaseLock(player, lockSeconds)
	end)
end

releaseLock = function(player: Player, lockSeconds: number)
	lockedUntil[player] = os.clock() + lockSeconds
	refreshPit(player)
	task.delay(lockSeconds, function()
		if player.Parent then
			if not sessions[player] then
				setCracking(player, false)
			end
			refreshPit(player)
			autoCrack(player)
		end
	end)
end

local function onAutoTriggered(spot: Attachment, player: Player)
	local services = context.Services
	if
		autoCounts[player]
		or sessions[player]
		or isLocked(player)
		or services.RockService:HasSession(player)
	then
		return
	end
	local data = services.DataService:GetData(player)
	if not data or services.BaseService:GetCrackSpot(player) ~= spot then
		return
	end
	if not AutoOpen.IsAllowed(context, player, data) then
		return
	end
	autoCounts[player] = 0
	player:SetAttribute(AutoOpenConfig.RunningAttribute, true)
	player:SetAttribute(AutoOpenConfig.CountAttribute, 0)
	refreshPit(player)
	autoCrack(player)
end

local function checkAutoRange()
	for player in autoCounts do
		local spot = context.Services.BaseService:GetCrackSpot(player)
		if not spot or not AutoOpen.InRange(player, spot) then
			stopAuto(player, AutoOpenConfig.StoppedText)
			refreshPit(player)
		end
	end
end

local function onPitTriggered(spot: Attachment, player: Player)
	local services = context.Services
	if
		sessions[player]
		or isLocked(player)
		or autoCounts[player]
		or services.RockService:HasSession(player)
	then
		return
	end
	local data = services.DataService:GetData(player)
	if not data or services.BaseService:GetCrackSpot(player) ~= spot then
		return
	end
	local geodeKey = Cracking.PickGeode(data)
	local geode = if geodeKey then GeodeConfig.Geodes[geodeKey] else nil
	local pit = if geode then ensurePit(spot, geode.ModelKey) else nil
	if not geodeKey or not pit then
		return
	end
	local session = Cracking.Begin(context, player, geodeKey, spot, pit, random, false)
	if session then
		sessions[player] = session
		setCracking(player, true)
		refreshPit(player)
	end
end

local function setupPit(plot: Model)
	local spot = plot:FindFirstChild("GeodeSpot", true)
	if not spot or not spot:IsA("Attachment") or pitPrompts[spot] then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PIT_PROMPT_NAME
	prompt.ActionText = "Crack"
	prompt.HoldDuration = ChopConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = GeodeConfig.PitPromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Active", false)
	CollectionService:AddTag(prompt, OWNED_PROMPT_TAG)
	prompt.Parent = spot
	pitPrompts[spot] = prompt
	trove:Add(prompt)
	trove:Add(prompt.Triggered:Connect(function(player: Player)
		onPitTriggered(spot, player)
	end))
	local pickSpot = Instance.new("Attachment")
	pickSpot.Name = "GeodePickSpot"
	pickSpot.CFrame = spot.CFrame + GeodeConfig.PickPromptOffset
	pickSpot.Parent = spot.Parent
	trove:Add(pickSpot)
	local pickPrompt = Instance.new("ProximityPrompt")
	pickPrompt.Name = PICK_PROMPT_NAME
	pickPrompt.ActionText = GeodeConfig.PickPromptText
	pickPrompt.KeyboardKeyCode = GeodeConfig.PickPromptKey
	pickPrompt.GamepadKeyCode = GeodeConfig.PickPromptGamepadKey
	pickPrompt.HoldDuration = 0
	pickPrompt.Style = Enum.ProximityPromptStyle.Custom
	pickPrompt.MaxActivationDistance = GeodeConfig.PitPromptRangeStuds
	pickPrompt.RequiresLineOfSight = false
	pickPrompt:SetAttribute("Active", false)
	CollectionService:AddTag(pickPrompt, OWNED_PROMPT_TAG)
	CollectionService:AddTag(pickPrompt, GeodeConfig.PickPromptTag)
	pickPrompt.Parent = pickSpot
	pickPrompts[spot] = pickPrompt
	local autoSpot = Instance.new("Attachment")
	autoSpot.Name = "GeodeAutoSpot"
	autoSpot.CFrame = spot.CFrame + AutoOpenConfig.PromptOffset
	autoSpot.Parent = spot.Parent
	trove:Add(autoSpot)
	local autoPrompt = Instance.new("ProximityPrompt")
	autoPrompt.Name = AutoOpenConfig.PromptName
	autoPrompt.ActionText = AutoOpenConfig.PromptText
	autoPrompt.KeyboardKeyCode = AutoOpenConfig.PromptKey
	autoPrompt.GamepadKeyCode = AutoOpenConfig.PromptGamepadKey
	autoPrompt.HoldDuration = 0
	autoPrompt.Style = Enum.ProximityPromptStyle.Custom
	autoPrompt.MaxActivationDistance = GeodeConfig.PitPromptRangeStuds
	autoPrompt.RequiresLineOfSight = false
	autoPrompt:SetAttribute("Active", false)
	CollectionService:AddTag(autoPrompt, OWNED_PROMPT_TAG)
	CollectionService:AddTag(autoPrompt, AutoOpenConfig.PromptTag)
	autoPrompt.Parent = autoSpot
	autoPrompts[spot] = autoPrompt
	trove:Add(autoPrompt.Triggered:Connect(function(player: Player)
		onAutoTriggered(spot, player)
	end))
end

local function clearPit(plot: Model)
	local spot = plot:FindFirstChild("GeodeSpot", true)
	local prompt = if spot and spot:IsA("Attachment") then pitPrompts[spot] else nil
	local pickPrompt = if spot and spot:IsA("Attachment") then pickPrompts[spot] else nil
	if prompt then
		prompt:SetAttribute("OwnerUserId", nil)
		prompt:SetAttribute("Active", false)
	end
	if pickPrompt then
		pickPrompt:SetAttribute("OwnerUserId", nil)
		pickPrompt:SetAttribute("Active", false)
	end
	local autoPrompt = if spot and spot:IsA("Attachment") then autoPrompts[spot] else nil
	if autoPrompt then
		autoPrompt:SetAttribute("OwnerUserId", nil)
		autoPrompt:SetAttribute("Active", false)
	end
end

function GeodeService.GrantGeodes(_self: any, player: Player, geodeKey: string, amount: number): boolean
	local data = context.Services.DataService:GetData(player)
	if not data or not GeodeConfig.Geodes[geodeKey] then
		return false
	end
	context.Services.DataService:Set(player, { "Geodes", geodeKey }, (data.Geodes[geodeKey] or 0) + amount)
	context.Services.DataService:RequestSave(player)
	refreshPit(player)
	return true
end

local function luckyKeyFor(player: Player, data: any): string?
	local chosen = luckyZones[player]
	local chosenGeode = if chosen then GeodeConfig.Geodes[chosen] else nil
	local baseKey = if chosenGeode and data.Strength >= chosenGeode.StrengthRequired
		then chosen
		else GeodeOrder.ForStrength(data.Strength)
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

function GeodeService.EndSession(_self: any, player: Player)
	if autoCounts[player] then
		stopAuto(player, AutoOpenConfig.StoppedText)
		refreshPit(player)
	end
	if sessions[player] then
		endSession(player)
		refreshPit(player)
	end
end

function GeodeService.IsRevealing(_self: any, player: Player): boolean
	return isLocked(player)
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
		setupPit(plot)
		refreshPit(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(player: Player, plot: Model)
		stopAuto(player, nil)
		endSession(player)
		clearPit(plot)
	end))
	for _, player in Players:GetPlayers() do
		local plot = services.BaseService:GetPlot(player)
		if plot then
			setupPit(plot)
			refreshPit(player)
		end
	end
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		refreshPit(player)
	end)

	Packets.BuyGeode.OnServerInvoke = function(player: Player, geodeKey: string, amount: number): boolean
		local bought = Purchasing.Buy(context, player, geodeKey, amount)
		if bought then
			refreshPit(player)
		end
		return bought
	end
	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(function(player: Player, claimed: number)
		local session = sessions[player]
		if not session or session.IsAuto or not Cracking.IsReady(session) then
			return
		end
		sessions[player] = nil
		releaseLock(player, Cracking.Release(context, player, session, random, claimed))
	end))
	trove:Add(Packets.StopAutoOpen.OnServerEvent:Connect(function(player: Player)
		stopAuto(player, nil)
		refreshPit(player)
	end))
	trove:Add(services.PassService.PassChanged:Connect(function(player: Player)
		refreshPit(player)
	end))
	local rangeElapsed = 0
	trove:Add(RunService.Heartbeat:Connect(function(dt: number)
		rangeElapsed += dt
		if rangeElapsed >= AutoOpenConfig.RangeCheckSeconds then
			rangeElapsed = 0
			checkAutoRange()
		end
	end))
	trove:Add(Packets.SetLuckyGeodeZone.OnServerEvent:Connect(function(player: Player, baseKey: string)
		local geode = if type(baseKey) == "string" then GeodeConfig.Geodes[baseKey] else nil
		if geode and not geode.RobuxOnly then
			luckyZones[player] = baseKey
		end
	end))
	trove:Add(Packets.SelectGeode.OnServerEvent:Connect(function(player: Player, geodeKey: string)
		local data = services.DataService:GetData(player)
		if not data or type(geodeKey) ~= "string" or not GeodeConfig.Geodes[geodeKey] then
			return
		end
		if (data.Geodes[geodeKey] or 0) < 1 or data.SelectedGeode == geodeKey then
			return
		end
		services.DataService:Set(player, { "SelectedGeode" }, geodeKey)
		refreshPit(player)
	end))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(function(player: Player)
		local session = sessions[player]
		if session and not session.IsAuto then
			endSession(player)
			refreshPit(player)
		end
	end))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		autoCounts[player] = nil
		endSession(player)
		lockedUntil[player] = nil
		luckyZones[player] = nil
		context.ForcedRarities[player] = nil
	end))
end

function GeodeService.Destroy(_self: any)
	Packets.BuyGeode.OnServerInvoke = nil
	for player in sessions do
		endSession(player)
	end
	for _, pit in pits do
		pit.Model:Destroy()
	end
	table.clear(pits)
	trove:Clean()
	table.clear(pitPrompts)
	table.clear(pickPrompts)
	table.clear(autoPrompts)
	table.clear(autoCounts)
end

return GeodeService
