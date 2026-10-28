--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockHint = require(ReplicatedStorage.RockHint)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local RockHintService = {
	Name = "RockHintService",
	Finished = Signal.new() :: Signal.Signal<Player>,
}

local settings = TutorialConfig.RockHint
local trove = Trove.new()
local services: { [string]: any } = {}

local function logEvent(player: Player, stage: number)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, settings.EventName, stage)
	end)
	if not ok then
		warn(`[RockHintService] {settings.EventName} event failed: {err}`)
	end
end

local function setStage(player: Player, data: any, stage: number)
	local previous = RockHint.StageOf(data)
	if previous == stage then
		return
	end
	local dataService = services.DataService
	dataService:Set(player, { "Hints", settings.Key }, stage)
	local isSilent = previous == RockHint.Locked and stage == RockHint.Done
	if not isSilent and stage > RockHint.FurthestOf(data) then
		dataService:Set(player, { "Hints", settings.FurthestKey }, stage)
		logEvent(player, stage)
	end
	print(`[RockHintService] {player.Name} rock hint {previous} -> {stage}`)
	dataService:RequestSave(player)
	if stage == RockHint.Done then
		RockHintService.Finished:Fire(player)
	end
end

local function check(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, RockHint.Decide(data))
end

function RockHintService.Reset(_self: any, player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	setStage(player, data, RockHint.Locked)
	services.DataService:Set(player, { "Hints", settings.FurthestKey }, nil)
	check(player)
end

function RockHintService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function RockHintService.Start(_self: any)
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

function RockHintService.Destroy(_self: any)
	trove:Destroy()
end

return RockHintService
