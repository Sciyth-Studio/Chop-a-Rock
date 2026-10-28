--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopApproach = require(ReplicatedStorage.Utils.ChopApproach)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local LiveSplit = require(ReplicatedStorage.Utils.LiveSplit)
local LoadingCoverConfig = require(ReplicatedStorage.Config.LoadingCoverConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local RockTemplate = require(ReplicatedStorage.RockTemplate)
local RushRockConfig = require(ReplicatedStorage.Config.RushRockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local Diamond = require(script.Diamond)
local Effects = require(script.Effects)
local GeodeFall = require(script.GeodeFall)
local Rush = require(script.Rush)
local SpotDots = require(script.SpotDots)

type TroveInstance = typeof(Trove.new())
type ClientRock = {
	Id: number,
	Key: string,
	Part: BasePart,
	Prompt: ProximityPrompt,
	IsUp: boolean,
	IsBroken: boolean,
	Rush: Rush.Look?,
	Split: LiveSplit.Prepared?,
}

local ROCK_TAG = "ChopRock"
local FOLDER_NAME = "Rocks"

local rocks: { [number]: ClientRock } = {}
local folder: Folder? = nil
local chopController: any = nil
local dataController: any = nil
local uiController: any = nil
local introController: any = nil

local RockController = {
	Name = "RockController",
	_trove = nil :: TroveInstance?,
}

local function isQuiet(): boolean
	local isCovered = uiController ~= nil and uiController:IsOpen(LoadingCoverConfig.ScreenName)
	local isIntro = introController ~= nil and introController:IsPlaying()
	return isCovered or isIntro
end

local function refreshPrompt(rock: ClientRock)
	rock.Prompt.Enabled = rock.IsUp
		and not rock.IsBroken
		and not chopController:IsMinigameActive()
		and Tutorial.CanChop(Tutorial.StepOf(dataController:Get({ "Tutorial" })))
end

local function refreshAll()
	for _, rock in rocks do
		refreshPrompt(rock)
	end
end

local function remove(id: number)
	local rock = rocks[id]
	if not rock then
		return
	end
	rocks[id] = nil
	if rock.Rush then
		rock.Rush.End(false)
	end
	if rock.Split then
		LiveSplit.Discard(rock.Split)
	end
	rock.Part:Destroy()
end

local function prepareSplit(id: number, canBreak: boolean)
	local rock = rocks[id]
	if not canBreak or not rock or rock.IsBroken or rock.Split then
		return
	end
	rock.Split =
		LiveSplit.Prepare(rock.Part, rock.Part.Position, ChopApproach.Rotation(rock.Part).RightVector)
end

local function sinkAway(id: number)
	local rock = rocks[id]
	if not rock or rock.IsBroken then
		return
	end
	rock.IsBroken = true
	CollectionService:RemoveTag(rock.Part, ROCK_TAG)
	refreshPrompt(rock)
	Effects.Sink(rock.Part, RockSpawnConfig.RiseSeconds, function()
		remove(id)
	end)
end

local function setWeather(id: number, weather: string)
	local rock = rocks[id]
	if rock and not rock.IsBroken then
		rock.Part:SetAttribute(WeatherConfig.RockWeatherAttribute, weather)
	end
end

local function endRush(id: number)
	local rock = rocks[id]
	local look = if rock then rock.Rush else nil
	if not rock or not look then
		return
	end
	rock.Rush = nil
	look.End(not rock.IsBroken)
end

local function spawn(
	id: number,
	key: string,
	position: Vector3,
	yaw: number,
	modifier: string,
	weather: string
)
	if rocks[id] or not folder then
		return
	end
	local part = RockTemplate.Build(key)
	if not part then
		return
	end
	local target = CFrame.Angles(0, yaw, 0) * part.CFrame.Rotation + position
	part.Name = `Rock_{key}`
	if weather ~= "" then
		part:SetAttribute(WeatherConfig.RockWeatherAttribute, weather)
	end
	part.Anchored = true
	part.CanCollide = true
	part.CFrame = target - Vector3.new(0, part.Size.Y + RockSpawnConfig.RiseDepthPaddingStuds, 0)
	part.Parent = folder

	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Chop"
	prompt.ObjectText = configs[key].DisplayName
	prompt.HoldDuration = ChopConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = ChopConfig.PromptRangeStuds + part.Size.X / 2
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = part

	local rock: ClientRock = {
		Id = id,
		Key = key,
		Part = part,
		Prompt = prompt,
		IsUp = false,
		IsBroken = false,
		Rush = nil,
		Split = nil,
	}
	rocks[id] = rock
	LiveSplit.Preload(part)
	if modifier == RushRockConfig.Modifier then
		rock.Rush = Rush.Start(
			part,
			target,
			os.clock() + RockSpawnConfig.RiseSeconds + RushRockConfig.CountdownSeconds
		)
	end
	prompt.Triggered:Connect(function()
		if rock.IsUp and not rock.IsBroken then
			Packets.RockChop:Fire(id)
		end
	end)
	Effects.Rise(part, target, function()
		if rocks[id] ~= rock then
			return
		end
		rock.IsUp = true
		CollectionService:AddTag(part, ROCK_TAG)
		refreshPrompt(rock)
	end, isQuiet())
end

local function breakRock(rock: ClientRock, quality: number)
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local piecesSeconds = configs[rock.Key].RespawnSeconds
	if rock.Rush then
		Rush.Burst(rock.Part)
		endRush(rock.Id)
	end
	Effects.Break(rock.Part, quality, piecesSeconds, rock.Split)
	task.delay(piecesSeconds, function()
		remove(rock.Id)
	end)
end

local function onChopped(id: number, quality: number, isBroken: boolean)
	local rock = rocks[id]
	if not rock then
		return
	end
	if quality == ChopQuality.Crack then
		Effects.Crack(rock.Part)
		return
	end
	if not isBroken then
		Effects.Hit(rock.Part, quality)
		return
	end
	rock.IsBroken = true
	CollectionService:RemoveTag(rock.Part, ROCK_TAG)
	refreshPrompt(rock)
	if quality == ChopQuality.Master then
		Effects.MasterStart(rock.Part)
		task.delay(MasterChopConfig.ImpactDelaySeconds, function()
			breakRock(rock, quality)
		end)
		return
	end
	breakRock(rock, quality)
end

function RockController.GetPart(_self: any, id: number): BasePart?
	local rock = rocks[id]
	return if rock and not rock.IsBroken then rock.Part else nil
end

function RockController.PlayMasterWindUp(_self: any, part: BasePart, isSilent: boolean?)
	Effects.MasterStart(part, isSilent)
end

function RockController.PlayBreak(_self: any, part: BasePart, quality: number, piecesSeconds: number)
	Effects.Break(part, quality, piecesSeconds, nil)
end

function RockController.PlayBreakBurst(_self: any, part: BasePart, quality: number)
	Effects.BreakBurst(part, quality)
end

function RockController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	chopController = controllers.ChopController
	dataController = controllers.DataController
	uiController = controllers.UIController
	introController = controllers.IntroController
end

function RockController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = workspace
	folder = created
	trove:Add(created)
	trove:Add(function()
		table.clear(rocks)
		SpotDots.Clear()
	end)

	trove:Add(Packets.RockSpawned.OnClientEvent:Connect(spawn))
	trove:Add(Packets.RockChopped.OnClientEvent:Connect(onChopped))
	trove:Add(Packets.RockMinigameStart.OnClientEvent:Connect(prepareSplit))
	trove:Add(Packets.RockRushEnded.OnClientEvent:Connect(endRush))
	trove:Add(Packets.RockRemoved.OnClientEvent:Connect(sinkAway))
	trove:Add(Packets.RockWeatherSet.OnClientEvent:Connect(setWeather))
	Diamond.Start(trove, chopController)
	GeodeFall.Start(trove, chopController)
	trove:Add(Packets.RockChopShown.OnClientEvent:Connect(Effects.Shown))
	trove:Add(Packets.RockSpawnSpots.OnClientEvent:Connect(SpotDots.Show))
	trove:Add(chopController.ActiveChanged:Connect(refreshAll))
	trove:Add(dataController:Observe({ "Tutorial", "Step" }, refreshAll))
	Packets.RockReady:Fire()
end

function RockController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
	folder = nil
end

return RockController
