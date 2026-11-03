--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraHint = require(ReplicatedStorage.AuraHint)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local TutorialService = {
	Name = "TutorialService",
	Finished = Signal.new() :: Signal.Signal<Player>,
}

local trove = Trove.new()
local services: { [string]: any } = {}
local finishing: { [Player]: boolean } = {}

local function logFunnel(player: Player, step: number)
	local name = Tutorial.Funnel[step]
	if not name then
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
	if not ok then
		warn(`[TutorialService] Funnel step {step} failed: {err}`)
	end
end

local function logFurthest(player: Player, data: any, upTo: number)
	local furthest = data.Tutorial.Furthest or 0
	if upTo <= furthest then
		return
	end
	for step = furthest + 1, upTo do
		logFunnel(player, step)
	end
	services.DataService:Set(player, { "Tutorial", "Furthest" }, upTo)
end

local function setStep(player: Player, step: number)
	local data = services.DataService:GetData(player)
	if not data or data.Tutorial.Step == step then
		return
	end
	local previous = data.Tutorial.Step
	services.DataService:Set(player, { "Tutorial", "Step" }, step)
	services.DataService:Set(player, { "Tutorial", "Taps" }, 0)
	if step > previous then
		logFurthest(player, data, math.min(step, Tutorial.Done))
	end
	if Tutorial.IsTraining(previous) and not Tutorial.IsTraining(step) then
		services.TrainingService:Stop(player)
	end
	print(`[TutorialService] {player.Name} step {previous} -> {step}`)
	services.DataService:RequestSave(player)
	if step == Tutorial.Done and previous ~= Tutorial.Done then
		TutorialService.Finished:Fire(player)
	end
end

local function padCount(data: any): number
	local total = 0
	for _ in data.HatchPads do
		total += 1
	end
	return total
end

local function bagCount(data: any): number
	local total = 0
	for _, count in data.Geodes do
		total += count
	end
	return total
end

local function decide(player: Player, data: any, step: number): number
	local hasPet = next(data.Pets) ~= nil
	if step == Tutorial.Final then
		return step
	end
	if hasPet then
		return if services.GeodeService:IsRevealing(player) then step else Tutorial.Final
	end
	if padCount(data) > 0 then
		return Tutorial.Open
	end
	if bagCount(data) > 0 then
		return Tutorial.Place
	end
	if step == Tutorial.Place or step == Tutorial.Open then
		return Tutorial.GetGeode
	end
	local taps = data.Tutorial.Taps or 0
	if step == Tutorial.Train then
		return if data.Strength >= TutorialConfig.TrainGoal and taps > 0 then Tutorial.Chop else step
	elseif step == Tutorial.Chop then
		return if Tutorial.RocksBroken(data) >= TutorialConfig.FirstChopRocks then Tutorial.GetGeode else step
	end
	return step
end

local function petKinds(data: any): number
	local index = data.Index
	local pets = if type(index) == "table" then index.Pets else nil
	local total = 0
	if type(pets) == "table" then
		for _ in pets do
			total += 1
		end
	end
	return total
end

local function milestone(data: any): number
	local playtime = data.Playtime or 0
	if playtime >= TutorialConfig.Played60MinSeconds then
		return Tutorial.Played60Min
	elseif playtime >= TutorialConfig.Played30MinSeconds then
		return Tutorial.Played30Min
	elseif (data.Rebirths or 0) > 0 then
		return Tutorial.FirstRebirth
	elseif petKinds(data) >= TutorialConfig.SecondPetCount then
		return Tutorial.SecondPet
	elseif (data.AuraTier or 1) >= TutorialConfig.AuraHint.Tier then
		return if AuraHint.StageOf(data) == AuraHint.Done then Tutorial.AuraTrained else Tutorial.AuraBought
	end
	return Tutorial.Done
end

local function finish(player: Player)
	if finishing[player] then
		return
	end
	finishing[player] = true
	task.delay(TutorialConfig.FinalHoldSeconds, function()
		finishing[player] = nil
		local data = services.DataService:GetData(player)
		if data and data.Tutorial.Step == Tutorial.Final then
			setStep(player, Tutorial.Done)
		end
	end)
end

local function check(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local step = Tutorial.StepOf(data.Tutorial)
	if not Tutorial.IsActive(step) then
		logFurthest(player, data, milestone(data))
		return
	end
	logFurthest(player, data, step)
	local nextStep = decide(player, data, step)
	if nextStep ~= step then
		setStep(player, nextStep)
	end
	if nextStep == Tutorial.Final then
		finish(player)
	end
end

local function onTrained(player: Player)
	local data = services.DataService:GetData(player)
	if not data or not Tutorial.IsTraining(Tutorial.StepOf(data.Tutorial)) then
		return
	end
	services.DataService:Set(player, { "Tutorial", "Taps" }, (data.Tutorial.Taps or 0) + 1)
	check(player)
end

function TutorialService.Reset(_self: any, player: Player)
	if not services.DataService:GetData(player) then
		return
	end
	finishing[player] = nil
	setStep(player, Tutorial.Train)
	services.DataService:Set(player, { "Tutorial", "Taps" }, 0)
	check(player)
end

function TutorialService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function TutorialService.Start(_self: any)
	trove:Add(services.TrainingService.Trained:Connect(onTrained))
	trove:Add(services.DataService.PlayerLoaded:Connect(function(player: Player)
		finishing[player] = nil
		check(player)
	end))
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		finishing[player] = nil
	end)
	trove:Add(task.spawn(function()
		while true do
			task.wait(TutorialConfig.CheckSeconds)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end))
end

function TutorialService.Destroy(_self: any)
	trove:Destroy()
	table.clear(finishing)
end

return TutorialService
