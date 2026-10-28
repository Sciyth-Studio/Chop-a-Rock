--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthHint = require(ReplicatedStorage.RebirthHint)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local RebirthHintService = { Name = "RebirthHintService" }

local settings = TutorialConfig.RebirthHint
local trove = Trove.new()
local services: { [string]: any } = {}

local function logEvent(player: Player, stage: number)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, settings.EventName, stage)
	end)
	if not ok then
		warn(`[RebirthHintService] {settings.EventName} event failed: {err}`)
	end
end

local function setStage(player: Player, data: any, stage: number)
	local previous = RebirthHint.StageOf(data)
	if previous == stage then
		return
	end
	local dataService = services.DataService
	dataService:Set(player, { "Hints", settings.Key }, stage)
	local isSilent = previous == RebirthHint.Locked and stage == RebirthHint.Done
	if not isSilent and stage > RebirthHint.FurthestOf(data) then
		dataService:Set(player, { "Hints", settings.FurthestKey }, stage)
		logEvent(player, stage)
	end
	print(`[RebirthHintService] {player.Name} rebirth hint {previous} -> {stage}`)
	dataService:RequestSave(player)
end

local function check(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, RebirthHint.Decide(data))
end

function RebirthHintService.Reset(_self: any, player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, RebirthHint.Locked)
	services.DataService:Set(player, { "Hints", settings.FurthestKey }, nil)
	check(player)
end

function RebirthHintService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function RebirthHintService.Start(_self: any)
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

function RebirthHintService.Destroy(_self: any)
	trove:Destroy()
end

return RebirthHintService
