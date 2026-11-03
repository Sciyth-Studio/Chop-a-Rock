--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)

local FirstMaster = {}

local settings = MasterChopConfig.FirstMaster
local random = Random.new()
local dueAt: { [Player]: number } = {}

local function stageOf(data: any): number?
	local hints = if type(data.Hints) == "table" then data.Hints else {}
	local stage = hints[settings.HintKey]
	return if type(stage) == "number" then stage else nil
end

function FirstMaster.Schedule(player: Player, data: any)
	if stageOf(data) == settings.Armed then
		dueAt[player] = os.clock() + random:NextNumber(settings.MinSeconds, settings.MaxSeconds)
	end
end

function FirstMaster.Arm(services: { [string]: any }, player: Player)
	local data = services.DataService:GetData(player)
	if not data or stageOf(data) ~= nil then
		return
	end
	services.DataService:Set(player, { "Hints", settings.HintKey }, settings.Armed)
	services.DataService:RequestSave(player)
	FirstMaster.Schedule(player, data)
end

function FirstMaster.IsDue(player: Player, data: any, quality: number): boolean
	local due = dueAt[player]
	return due ~= nil
		and os.clock() >= due
		and quality >= settings.MinQuality
		and stageOf(data) == settings.Armed
end

function FirstMaster.Claim(services: { [string]: any }, player: Player, data: any, isFree: boolean)
	if stageOf(data) ~= settings.Armed then
		return
	end
	dueAt[player] = nil
	services.DataService:Set(player, { "Hints", settings.HintKey }, settings.Done)
	services.DataService:RequestSave(player)
	task.delay(MasterChopConfig.ImpactDelaySeconds, function()
		services.NotificationService:Notify(player, settings.Kind, settings.Text)
	end)
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, settings.EventName, if isFree then 1 else 0)
	end)
	if not ok then
		warn(`[RockService] {settings.EventName} event failed: {err}`)
	end
	print(`[RockService] {player.Name} first Master Chop ({if isFree then "free" else "natural"})`)
end

function FirstMaster.Forget(player: Player)
	dueAt[player] = nil
end

return FirstMaster
