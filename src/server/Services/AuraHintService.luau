--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraHint = require(ReplicatedStorage.AuraHint)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local AuraHintService = { Name = "AuraHintService" }

local settings = TutorialConfig.AuraHint
local trove = Trove.new()
local services: { [string]: any } = {}

local function logEvent(player: Player, stage: number)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, settings.EventName, stage)
	end)
	if not ok then
		warn(`[AuraHintService] {settings.EventName} event failed: {err}`)
	end
end

local function setStage(player: Player, data: any, stage: number)
	local previous = AuraHint.StageOf(data)
	if previous == stage then
		return
	end
	local dataService = services.DataService
	dataService:Set(player, { "Hints", settings.Key }, stage)
	if stage == AuraHint.Done or stage == AuraHint.Locked then
		dataService:Set(player, { "Hints", settings.RepsKey }, nil)
	elseif stage == AuraHint.Train and AuraHint.RepsOf(data) < 1 then
		dataService:Set(player, { "Hints", settings.RepsKey }, 1)
	end
	local isSilent = previous == AuraHint.Locked and stage == AuraHint.Done
	if not isSilent and stage > AuraHint.FurthestOf(data) then
		dataService:Set(player, { "Hints", settings.FurthestKey }, stage)
		logEvent(player, stage)
	end
	local aura = AuraHint.Aura()
	if previous == AuraHint.Locked and AuraHint.IsActive(stage) and aura then
		services.NotificationService:Notify(player, settings.UnlockKind, `{aura.DisplayName} unlocked!`)
	end
	print(`[AuraHintService] {player.Name} aura hint {previous} -> {stage}`)
	dataService:RequestSave(player)
end

local function check(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, AuraHint.Decide(data))
end

local function onTrained(player: Player)
	local data = services.DataService:GetData(player)
	if not data or AuraHint.StageOf(data) ~= AuraHint.Train then
		return
	end
	services.DataService:Set(player, { "Hints", settings.RepsKey }, AuraHint.RepsOf(data) + 1)
	check(player)
end

function AuraHintService.Reset(_self: any, player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, AuraHint.Locked)
	services.DataService:Set(player, { "Hints", settings.FurthestKey }, nil)
	check(player)
end

function AuraHintService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function AuraHintService.Start(_self: any)
	trove:Add(services.TrainingService.Trained:Connect(onTrained))
	trove:Add(services.DataService.PlayerLoaded:Connect(check))
	trove:Add(task.spawn(function()
		while true do
			task.wait(TutorialConfig.CheckSeconds)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end))
end

function AuraHintService.Destroy(_self: any)
	trove:Destroy()
end

return AuraHintService
