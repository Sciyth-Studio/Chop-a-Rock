--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Packets = require(ReplicatedStorage.Packets)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ArmService = require(script.Parent.ArmService)
local SplitModel = require(ReplicatedStorage.Utils.SplitModel)
local StatsService = require(script.Parent.StatsService)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local Stands = require(script.Stands)
local Upgrade = require(script.Upgrade)

local TRAINING_TAG = "TrainingBoard"
local PLOT_TAG = "BasePlot"
local OWNER_ATTRIBUTE = "OwnerUserId"

local TrainingService = {
	Name = "TrainingService",
	Trained = Signal.new() :: Signal.Signal<Player>,
}

local trove = Trove.new()
local services: { [string]: any } = {}

type Training = {
	Board: BasePart,
	Plot: Model?,
	LastChopClock: number,
	ReleaseSpeed: () -> (),
	SavedJumpPower: number,
	SavedJumpHeight: number,
}
local trainings: { [Player]: Training } = {}
local strengthCarry: { [Player]: number } = {}
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

local function findPlot(part: BasePart): Model?
	local ancestor = part.Parent
	while ancestor and ancestor ~= workspace do
		if ancestor:IsA("Model") and CollectionService:HasTag(ancestor, PLOT_TAG) then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

local function canUse(player: Player, plot: Model?): boolean
	return plot == nil or services.BaseService:GetOwner(plot) == player
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

local function emitBurst(key: string, board: BasePart, tint: Color3?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Attachment") then
		asset:Destroy()
		return
	end
	asset.Parent = board
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			if tint then
				descendant.Color = ColorSequence.new(tint)
			end
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

local function setEffectsEnabled(board: BasePart, isEnabled: boolean, saved: { [Instance]: boolean })
	for _, descendant in board:GetDescendants() do
		if not descendant:IsA("ParticleEmitter") and not descendant:IsA("Light") then
			continue
		end
		local effect = descendant :: any
		if isEnabled then
			local wasEnabled = saved[descendant]
			if wasEnabled ~= nil then
				effect.Enabled = wasEnabled
			end
		else
			saved[descendant] = effect.Enabled
			effect.Enabled = false
		end
	end
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

local function breakBoard(board: BasePart, effectKey: string)
	if brokenBoards[board] then
		return
	end
	local model = SplitModel.Spawn(board, boardPush)
	if not model then
		return
	end
	brokenBoards[board] = true
	services.CollisionService:MarkDebris(model)
	local saved: { [BasePart]: { Transparency: number, CanCollide: boolean } } = {}
	local parts: { BasePart } = { board }
	for _, descendant in board:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	for _, part in parts do
		saved[part] = { Transparency = part.Transparency, CanCollide = part.CanCollide }
		part.Transparency = 1
		part.CanCollide = false
	end
	local savedEffects: { [Instance]: boolean } = {}
	setEffectsEnabled(board, false, savedEffects)
	emitBurst("VFX_Board_Break", board, board.Color)
	if effectKey ~= "" then
		emitBurst(effectKey, board, nil)
	end
	fadePieces(model)
	task.delay(TrainingConfig.BoardPieceLifetimeSeconds, function()
		if model.Parent then
			model:Destroy()
		end
	end)
	task.delay(TrainingConfig.BoardRespawnSeconds, function()
		brokenBoards[board] = nil
		for part, state in saved do
			if part.Parent then
				part.Transparency = state.Transparency
				part.CanCollide = state.CanCollide
			end
		end
		if board.Parent then
			setEffectsEnabled(board, true, savedEffects)
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
	training.ReleaseSpeed()
	local _, humanoid = playerRootAndHumanoid(player)
	if humanoid and humanoid.Parent then
		humanoid.JumpPower = training.SavedJumpPower
		humanoid.JumpHeight = training.SavedJumpHeight
	end
	if player.Parent then
		Packets.TrainingStopped:FireClient(player)
	end
end

local function startTraining(player: Player, board: BasePart, plot: Model?)
	if not services.DataService:GetData(player) or not canUse(player, plot) then
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
		Plot = plot,
		LastChopClock = os.clock(),
		ReleaseSpeed = services.WalkSpeedService:Freeze(player),
		SavedJumpPower = humanoid.JumpPower,
		SavedJumpHeight = humanoid.JumpHeight,
	}
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	services.PetService:PutAway(player)
	Packets.TrainingStarted:FireClient(player)
end

local function syncStand(plot: Model)
	local owner = services.BaseService:GetOwner(plot)
	local data = if owner then services.DataService:GetData(owner) else nil
	Stands.Apply(plot, TrainingStands.Get(if data then data.TrainingTier else 1))
end

local lastStandCheck = 0

local function tick()
	local now = os.clock()
	if now - lastStandCheck >= TrainingConfig.StandCheckSeconds then
		lastStandCheck = now
		for _, plot in CollectionService:GetTagged(PLOT_TAG) do
			if plot:IsA("Model") and plot:IsDescendantOf(workspace) then
				syncStand(plot)
			end
		end
	end
	for player, training in trainings do
		local root, _ = playerRootAndHumanoid(player)
		if not root or not training.Board.Parent or not canUse(player, training.Plot) then
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
			local data = services.DataService:GetData(player)
			local stand = TrainingStands.Get(if data then data.TrainingTier else 1)
			local exact = stand.StrengthPerRep * ArmService:GetTrainingMultiplier(player)
				+ (strengthCarry[player] or 0)
			local gain = math.floor(exact)
			strengthCarry[player] = exact - gain
			local newStrength = StatsService:AddStrength(player, gain)
			playSoundOnPart(stand.BreakSound, training.Board)
			breakBoard(training.Board, stand.BreakEffect)
			Packets.TrainingChop:FireClient(player)
			TrainingService.Trained:Fire(player)
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
	if not part:IsDescendantOf(workspace) or part:FindFirstChild("TrainingPrompt") then
		return
	end
	local plot = findPlot(part)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TrainingPrompt"
	prompt.ActionText = "Train"
	prompt.ObjectText = "Training Board"
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	if plot then
		local ownedPlot = plot
		prompt:SetAttribute("Active", true)
		prompt:SetAttribute(OWNER_ATTRIBUTE, ownedPlot:GetAttribute(OWNER_ATTRIBUTE))
		ownedPlot:GetAttributeChangedSignal(OWNER_ATTRIBUTE):Connect(function()
			prompt:SetAttribute(OWNER_ATTRIBUTE, ownedPlot:GetAttribute(OWNER_ATTRIBUTE))
		end)
		CollectionService:AddTag(prompt, "OwnedPrompt")
	end
	prompt.Parent = part

	prompt.Triggered:Connect(function(player: Player)
		local existing = trainings[player]
		if existing and existing.Board == part then
			stopTraining(player)
			return
		end
		startTraining(player, part, plot)
	end)
end

function TrainingService.Stop(_self: any, player: Player)
	stopTraining(player)
end

local function syncPlayerStand(player: Player)
	local plot = services.BaseService:GetPlot(player)
	if plot then
		syncStand(plot)
	end
end

function TrainingService.SetTier(_self: any, player: Player, tier: number): boolean
	local isSet = services.DataService:Set(player, { "TrainingTier" }, TrainingStands.ClampTier(tier))
	if isSet then
		syncPlayerStand(player)
	end
	return isSet
end

function TrainingService.GrantStandCash(_self: any, player: Player, tier: number): boolean
	return Upgrade.GrantStandCash(services, player, tier)
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

	trove:Add(services.BaseService.PlotClaimed:Connect(function(_player: Player, plot: Model)
		syncStand(plot)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(_player: Player, plot: Model)
		syncStand(plot)
	end))

	trove:Add(Packets.TrainingStopRequest.OnServerEvent:Connect(function(player: Player)
		stopTraining(player)
	end))

	Packets.UpgradeTraining.OnServerInvoke = function(player: Player)
		local result = Upgrade.Buy(services, player)
		if result == "Upgraded" then
			syncPlayerStand(player)
		end
		return result
	end

	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		trainings[player] = nil
		strengthCarry[player] = nil
	end))
end

function TrainingService.Destroy(_self: any)
	for player in trainings do
		stopTraining(player)
	end
	Packets.UpgradeTraining.OnServerInvoke = nil
	trove:Clean()
	table.clear(trainings)
	table.clear(brokenBoards)
end

return TrainingService
