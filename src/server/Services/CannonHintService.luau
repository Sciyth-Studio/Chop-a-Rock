--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local CannonHint = require(ReplicatedStorage.CannonHint)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local CannonHintService = { Name = "CannonHintService" }

local settings = TutorialConfig.CannonHint
local trove = Trove.new()
local services: { [string]: any } = {}

local function logEvent(player: Player, name: string, stage: number)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, name, stage)
	end)
	if not ok then
		warn(`[CannonHintService] {name} event failed: {err}`)
	end
end

local function setStage(player: Player, data: any, stage: number, isSkip: boolean?)
	local previous = CannonHint.StageOf(data)
	if previous == stage then
		return
	end
	local dataService = services.DataService
	dataService:Set(player, { "Hints", settings.Key }, stage)
	if not isSkip and stage > CannonHint.FurthestOf(data) then
		dataService:Set(player, { "Hints", settings.FurthestKey }, stage)
		logEvent(player, settings.EventName, stage)
	end
	local cannon = CannonHint.Cannon()
	if previous == CannonHint.Locked and CannonHint.IsActive(stage) and cannon then
		services.NotificationService:Notify(player, settings.UnlockKind, `{cannon.DisplayName} unlocked!`)
	end
	print(`[CannonHintService] {player.Name} cannon hint {previous} -> {stage}`)
	dataService:RequestSave(player)
end

local function check(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, CannonHint.Decide(data))
end

local function onLanded(player: Player, key: string)
	local data = services.DataService:GetData(player)
	if not data or CannonHint.StageOf(data) == CannonHint.Done then
		return
	end
	local wasShown = CannonHint.IsActive(CannonHint.StageOf(data))
	setStage(player, data, CannonHint.Done)
	if not wasShown then
		return
	end
	for _, cannon in CannonConfig.Cannons do
		if cannon.Key == key then
			services.NotificationService:Notify(player, "Info", `Welcome to the {cannon.ZoneName}!`)
		end
	end
end

local function onSkip(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local stage = CannonHint.StageOf(data)
	if not CannonHint.IsActive(stage) then
		return
	end
	logEvent(player, settings.SkippedEventName, stage)
	setStage(player, data, CannonHint.Done, true)
end

function CannonHintService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function CannonHintService.Start(_self: any)
	trove:Add(services.CannonService.Landed:Connect(onLanded))
	trove:Add(services.DataService.PlayerLoaded:Connect(check))
	trove:Add(Packets.CannonHintSkip.OnServerEvent:Connect(onSkip))
	trove:Add(task.spawn(function()
		while true do
			task.wait(TutorialConfig.CheckSeconds)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end))
end

function CannonHintService.Destroy(_self: any)
	trove:Destroy()
end

return CannonHintService
