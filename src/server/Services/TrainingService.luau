--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Packets = require(ReplicatedStorage.Packets)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local StatsService = require(script.Parent.StatsService)

local TRAINING_TAG = "TrainingBoard"

local TrainingService = {
	Name = "TrainingService",
}

local trove = Trove.new()

type Training = {
	Board: BasePart,
	LastChopClock: number,
	SavedWalkSpeed: number,
	SavedJumpPower: number,
	SavedJumpHeight: number,
}
local trainings: { [Player]: Training } = {}

local function resolveBoardPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		local primary = instance.PrimaryPart
		if primary then
			return primary
		end
		local fallback = instance:FindFirstChild("TrainingBoard")
		if fallback and fallback:IsA("BasePart") then
			return fallback
		end
	end
	return nil
end

local function playSoundOnPart(key: string, part: BasePart)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	asset.Parent = part
	asset:Play()
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function playerRootAndHumanoid(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return root, humanoid
end

local function stopTraining(player: Player)
	local training = trainings[player]
	if not training then
		return
	end
	trainings[player] = nil
	local _, humanoid = playerRootAndHumanoid(player)
	if humanoid and humanoid.Parent then
		humanoid.WalkSpeed = training.SavedWalkSpeed
		humanoid.JumpPower = training.SavedJumpPower
		humanoid.JumpHeight = training.SavedJumpHeight
	end
	if player.Parent then
		Packets.TrainingStopped:FireClient(player)
	end
end

local function startTraining(player: Player, board: BasePart)
	if trainings[player] then
		stopTraining(player)
	end
	local root, humanoid = playerRootAndHumanoid(player)
	if not root or not humanoid then
		return
	end
	local snapPos = board.Position + board.CFrame.LookVector * TrainingConfig.SnapDistanceStuds
	snapPos = Vector3.new(snapPos.X, root.Position.Y, snapPos.Z)
	root.CFrame = CFrame.lookAt(snapPos, board.Position)

	trainings[player] = {
		Board = board,
		LastChopClock = 0,
		SavedWalkSpeed = humanoid.WalkSpeed,
		SavedJumpPower = humanoid.JumpPower,
		SavedJumpHeight = humanoid.JumpHeight,
	}
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	Packets.TrainingStarted:FireClient(player)
end

local function tick()
	local now = os.clock()
	for player, training in trainings do
		local root, _ = playerRootAndHumanoid(player)
		if not root or not training.Board.Parent then
			stopTraining(player)
			continue
		end
		local distance = (root.Position - training.Board.Position).Magnitude
		if distance > TrainingConfig.MaxLingerStuds then
			stopTraining(player)
			continue
		end
		if now - training.LastChopClock >= TrainingConfig.ChopIntervalSeconds then
			training.LastChopClock = now
			local newStrength = StatsService.addStrength(player, TrainingConfig.StrengthPerChop)
			playSoundOnPart("SFX_Train_Chop", training.Board)
			print(`[TrainingService] {player.Name} trained: strength={newStrength}`)
		end
	end
end

local function setupBoard(instance: Instance)
	local part = resolveBoardPart(instance)
	if not part then
		warn(`[TrainingService] TrainingBoard tag on unsupported instance: {instance:GetFullName()}`)
		return
	end
	if part:FindFirstChild("TrainingPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TrainingPrompt"
	prompt.ActionText = "Train"
	prompt.ObjectText = "Training Board"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function(player: Player)
		local existing = trainings[player]
		if existing and existing.Board == part then
			stopTraining(player)
			return
		end
		startTraining(player, part)
	end)
end

function TrainingService.Init(_self: any, _services: { [string]: any }) end

function TrainingService.Start(_self: any)
	for _, tagged in CollectionService:GetTagged(TRAINING_TAG) do
		setupBoard(tagged)
	end
	trove:Add(CollectionService:GetInstanceAddedSignal(TRAINING_TAG):Connect(setupBoard))

	trove:Add(RunService.Heartbeat:Connect(tick))

	trove:Add(Packets.TrainingStopRequest.OnServerEvent:Connect(function(player: Player)
		stopTraining(player)
	end))

	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		trainings[player] = nil
	end))
end

function TrainingService.Destroy(_self: any)
	for player in trainings do
		stopTraining(player)
	end
	trove:Clean()
	table.clear(trainings)
end

return TrainingService
