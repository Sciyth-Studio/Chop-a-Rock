--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Packets = require(ReplicatedStorage.Packets)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ArmService = require(script.Parent.ArmService)
local SplitModel = require(script.Parent.Parent.Utils.SplitModel)
local StatsService = require(script.Parent.StatsService)

local TRAINING_TAG = "TrainingBoard"

local TrainingService = {
	Name = "TrainingService",
}

local trove = Trove.new()
local services: { [string]: any } = {}

type Training = {
	Board: BasePart,
	LastChopClock: number,
	SavedWalkSpeed: number,
	SavedJumpPower: number,
	SavedJumpHeight: number,
}
local trainings: { [Player]: Training } = {}
local brokenBoards: { [BasePart]: true } = {}

local boardPush: SplitModel.Push = {
	OutwardStuds = TrainingConfig.BoardSplitOutwardStuds,
	UpStuds = TrainingConfig.BoardSplitUpStuds,
	TorqueRadPerSec = TrainingConfig.BoardSplitTorqueRadPerSec,
}

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

local function playBoardBurst(board: BasePart)
	local asset = AssetRegistry.get("VFX_Board_Break")
	if not asset:IsA("Attachment") then
		asset:Destroy()
		return
	end
	asset.Parent = board
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Color = ColorSequence.new(board.Color)
			local count = descendant:GetAttribute("EmitCount")
			descendant:Emit(if type(count) == "number" then count else TrainingConfig.BoardBurstEmitCount)
		end
	end
	task.delay(TrainingConfig.BoardBurstLifetimeSeconds, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function fadePieces(model: Model)
	local fade = TweenInfo.new(
		TrainingConfig.BoardPieceLifetimeSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			TweenService:Create(descendant, fade, { Transparency = 1 }):Play()
		end
	end
end

local function breakBoard(board: BasePart)
	if brokenBoards[board] then
		return
	end
	local model = SplitModel.Spawn(board, boardPush)
	if not model then
		return
	end
	brokenBoards[board] = true
	services.CollisionService:MarkDebris(model)
	board.Transparency = 1
	board.CanCollide = false
	playBoardBurst(board)
	fadePieces(model)
	task.delay(TrainingConfig.BoardPieceLifetimeSeconds, function()
		if model.Parent then
			model:Destroy()
		end
	end)
	task.delay(TrainingConfig.BoardRespawnSeconds, function()
		brokenBoards[board] = nil
		if board.Parent then
			board.Transparency = 0
			board.CanCollide = true
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
	if not services.DataService:GetData(player) then
		return
	end
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
		* CFrame.new(-TrainingConfig.SnapLeftShiftStuds, 0, 0)

	trainings[player] = {
		Board = board,
		LastChopClock = os.clock(),
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
			local gain = math.max(
				1,
				math.floor(
					TrainingConfig.StrengthPerChop
							* ArmService:GetTrainingMultiplier(player)
							* services.RebirthService:GetStrengthMultiplier(player)
						+ 0.5
				)
			)
			local newStrength = StatsService:AddStrength(player, gain)
			playSoundOnPart("SFX_Train_Chop", training.Board)
			breakBoard(training.Board)
			Packets.TrainingChop:FireClient(player)
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
	prompt.Style = Enum.ProximityPromptStyle.Custom
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

function TrainingService.Init(_self: any, registry: { [string]: any })
	services = registry
end

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
	table.clear(brokenBoards)
end

return TrainingService
