--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local MusicConfig = require(ReplicatedStorage.Config.MusicConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local soundGroupName = "Music"

local fightPhases: { [number]: boolean } = {
	[BossConfig.Phases.Fighting] = true,
	[BossConfig.Phases.Mad] = true,
	[BossConfig.Phases.Finish] = true,
}

local Boss = {}

local function tracks(folderName: string): { Sound }
	local found: { Sound } = {}
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local music = if assets then assets:FindFirstChild(MusicConfig.FolderName) else nil
	local folder = if music then music:FindFirstChild(folderName) else nil
	if not folder then
		return found
	end
	for _, child in folder:GetChildren() do
		if child:IsA("Sound") then
			table.insert(found, child)
		end
	end
	return found
end

local function cloneTrack(source: Sound, name: string): Sound
	local sound = source:Clone()
	sound.Name = name
	sound.Volume = 0
	local group = SoundService:FindFirstChild(soundGroupName)
	if group and group:IsA("SoundGroup") then
		sound.SoundGroup = group
	end
	sound.Parent = SoundService
	return sound
end

local function isNearArena(): boolean
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local position: Vector3
	if root and root:IsA("BasePart") then
		position = root.Position
	else
		local camera = workspace.CurrentCamera
		if not camera then
			return false
		end
		position = camera.Focus.Position
	end
	local min, max = MusicConfig.BossHearMin, MusicConfig.BossHearMax
	return position.X >= min.X and position.X <= max.X and position.Z >= min.Y and position.Z <= max.Y
end

function Boss.Start(trove: TroveInstance, hold: () -> () -> ())
	local model: Model? = nil
	local track: Sound? = nil
	local trackVolume = 0
	local release: (() -> ())? = nil
	local lastPhase: any = nil
	local isStopped = false
	local modelTrove = trove:Extend()
	local diamond: Model? = nil
	local diamondPart: BasePart? = nil
	local diamondTrove = trove:Extend()
	local targetSpeed = 1

	local function phase(): any
		return if model then model:GetAttribute(BossConfig.PhaseAttribute) else nil
	end

	local function isDiamondLow(): boolean
		local part = diamondPart
		if not part then
			return false
		end
		local health = part:GetAttribute(DiamondRockConfig.HealthAttribute)
		local maxHealth = part:GetAttribute(DiamondRockConfig.MaxHealthAttribute)
		return type(health) == "number"
			and type(maxHealth) == "number"
			and maxHealth > 0
			and health / maxHealth <= DiamondRockConfig.LowHealthRatio
	end

	local function speed(): number
		local isMad = model ~= nil and model:GetAttribute(BossConfig.MadAttribute) == true
		return if isMad or isDiamondLow() then 2 ^ (MusicConfig.BossMadSemitones / 12) else 1
	end

	local function shouldPlay(): boolean
		local current = phase()
		local isBossFighting = type(current) == "number" and fightPhases[current] == true
		local isDiamondOut = diamond ~= nil and diamond.Parent ~= nil
		return not isStopped and (isBossFighting or isDiamondOut) and isNearArena()
	end

	local function trackKey(): string?
		local current = phase()
		if type(current) == "number" and fightPhases[current] == true and model then
			local key = model:GetAttribute(BossConfig.BossAttribute)
			return if type(key) == "string" then key else nil
		end
		return if diamond then DiamondRockConfig.ModelName else nil
	end

	local function startTrack()
		local choices = tracks(MusicConfig.BossFightFolderName)
		if #choices == 0 then
			return
		end
		local key = trackKey()
		local source = choices[math.random(1, #choices)]
		for _, choice in choices do
			if choice.Name == key then
				source = choice
			end
		end
		release = hold()
		local sound = cloneTrack(source, "BossFightMusic")
		sound.Looped = true
		targetSpeed = speed()
		sound.PlaybackSpeed = targetSpeed
		sound:Play()
		trackVolume = source.Volume
		track = sound
		TweenService:Create(sound, TweenInfo.new(MusicConfig.BossFadeInSeconds), { Volume = trackVolume })
			:Play()
	end

	local function stopTrack()
		local sound = track
		track = nil
		if sound then
			local fadeOut =
				TweenService:Create(sound, TweenInfo.new(MusicConfig.BossFadeOutSeconds), { Volume = 0 })
			fadeOut.Completed:Once(function()
				sound:Destroy()
			end)
			fadeOut:Play()
		end
		if release then
			release()
			release = nil
		end
	end

	local function refresh()
		local wants = shouldPlay()
		if wants and not track then
			startTrack()
		elseif not wants and track then
			stopTrack()
		end
	end

	local function playSting()
		local sound = track
		if not sound then
			return
		end
		local choices = tracks(MusicConfig.BossStingFolderName)
		if #choices == 0 then
			return
		end
		local source = choices[math.random(1, #choices)]
		local sting = cloneTrack(source, "BossFinishSting")
		sting.Volume = source.Volume
		sting.Looped = false
		sting.Ended:Once(function()
			sting:Destroy()
		end)
		sting:Play()
		TweenService:Create(sound, TweenInfo.new(0.2), { Volume = trackVolume * MusicConfig.BossStingDuck })
			:Play()
		task.delay(MusicConfig.BossStingDuckSeconds, function()
			if track == sound then
				TweenService:Create(sound, TweenInfo.new(1), { Volume = trackVolume }):Play()
			end
		end)
	end

	local function onPhase()
		local current = phase()
		refresh()
		if current == BossConfig.Phases.Finish and lastPhase ~= BossConfig.Phases.Finish then
			playSting()
		end
		lastPhase = current
	end

	local function retune()
		local sound = track
		local target = speed()
		if sound and target ~= targetSpeed then
			targetSpeed = target
			TweenService:Create(sound, TweenInfo.new(MusicConfig.BossMadSeconds), { PlaybackSpeed = target })
				:Play()
		end
	end

	local function bindDiamondPart(part: Instance)
		if diamondPart or not part:IsA("BasePart") then
			return
		end
		if part:GetAttribute(DiamondRockConfig.MaxHealthAttribute) == nil then
			return
		end
		diamondPart = part
		diamondTrove:Add(part:GetAttributeChangedSignal(DiamondRockConfig.HealthAttribute):Connect(retune))
		retune()
	end

	local function bindDiamond(candidate: Model)
		diamondTrove:Clean()
		diamond = candidate
		diamondPart = nil
		for _, descendant in candidate:GetDescendants() do
			bindDiamondPart(descendant)
		end
		diamondTrove:Add(candidate.DescendantAdded:Connect(bindDiamondPart))
		refresh()
	end

	local function bind(candidate: Instance)
		if not candidate:IsA("Model") then
			return
		end
		if candidate.Name == DiamondRockConfig.ModelName then
			bindDiamond(candidate)
			return
		end
		if candidate.Name ~= BossConfig.ModelName then
			return
		end
		modelTrove:Clean()
		model = candidate
		lastPhase = phase()
		modelTrove:Add(candidate:GetAttributeChangedSignal(BossConfig.PhaseAttribute):Connect(onPhase))
		modelTrove:Add(candidate:GetAttributeChangedSignal(BossConfig.MadAttribute):Connect(retune))
		refresh()
	end

	trove:Add(workspace.ChildAdded:Connect(bind))
	trove:Add(workspace.ChildRemoved:Connect(function(child)
		if child == model then
			modelTrove:Clean()
			model = nil
			lastPhase = nil
			refresh()
		elseif child == diamond then
			diamondTrove:Clean()
			diamond = nil
			diamondPart = nil
			refresh()
		end
	end))
	for _, name in { BossConfig.ModelName, DiamondRockConfig.ModelName } do
		local existing = workspace:FindFirstChild(name)
		if existing then
			bind(existing)
		end
	end

	trove:Add(task.spawn(function()
		while true do
			task.wait(MusicConfig.BossCheckSeconds)
			if model or diamond then
				refresh()
			end
		end
	end))
	trove:Add(function()
		isStopped = true
		stopTrack()
	end)
end

return Boss
