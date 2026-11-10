--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)
local Arrows = require(script.Arrows)
local Audio = require(script.Audio)
local Effects = require(script.Effects)
local Hitstop = require(script.Hitstop)
local Launch = require(script.Launch)
local Motion = require(script.Motion)
local Sequence = require(script.Sequence)
local Wander = require(script.Wander)

type TroveInstance = typeof(Trove.new())

export type FightView = {
	Zone: string,
	Name: string,
	Health: number,
	MaxHealth: number,
	StartedAt: number,
	FightsAt: number,
	Anchor: Vector3?,
}

local enemies: { [string]: Motion.Enemy } = {}
local folder: Folder? = nil
local dataController: any = nil
local uiController: any = nil
local chopController: any = nil
local musicController: any = nil
local musicTrove: TroveInstance? = nil
local fightMusic: Sound? = nil
local musicSpedUp = false
local musicMuffled = false
local lastTick = math.huge
local baseFov: number? = nil
local fight: FightView? = nil
local inputTrove: TroveInstance? = nil
local launchTrove: TroveInstance? = nil
local stageTrove: TroveInstance? = nil
local screensTrove: TroveInstance? = nil
local arrowTrove: TroveInstance? = nil
local strike: (() -> ())? = nil
local holdUntil: number? = nil
local holdEnemy: Motion.Enemy? = nil
local danger: ColorCorrectionEffect? = nil
local dangerTotal = 0

local function stopDanger()
	if danger then
		danger:Destroy()
		danger = nil
	end
	local camera = workspace.CurrentCamera
	if baseFov and camera then
		camera.FieldOfView = baseFov
	end
	baseFov = nil
end

local function startDanger(secondsLeft: number)
	stopDanger()
	if secondsLeft <= 0 then
		return
	end
	dangerTotal = secondsLeft
	musicSpedUp = false
	musicMuffled = false
	lastTick = math.huge
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "EnemyFightDanger"
	effect.Parent = Lighting
	danger = effect
end

local function finalTick(secondsLeft: number)
	local count = math.ceil(secondsLeft)
	if count > EnemyConfig.FinalSeconds or count >= lastTick or secondsLeft <= 0 then
		return
	end
	lastTick = count
	Audio.Play(EnemyConfig.TickSoundKey)
	local music = fightMusic
	if music and not musicMuffled then
		musicMuffled = true
		Audio.Muffle(music)
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	baseFov = baseFov or camera.FieldOfView
	local base = baseFov :: number
	camera.FieldOfView = base - EnemyConfig.FinalFovKick
	TweenService:Create(
		camera,
		TweenInfo.new(EnemyConfig.FinalFovSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = base }
	):Play()
end

local function stepDanger()
	local effect = danger
	if not effect then
		return
	end
	local left = chopController:GetSecondsLeft()
	if not left then
		stopDanger()
		return
	end
	local share = 1 - math.clamp(left / math.max(dangerTotal, 1e-3), 0, 1)
	local music = fightMusic
	if music and not musicSpedUp and share >= EnemyConfig.MusicSpeedUpShare then
		musicSpedUp = true
		Audio.SpeedUp(music)
	end
	finalTick(left)
	effect.TintColor = Color3.new(1, 1, 1):Lerp(EnemyConfig.DangerTint, share)
	effect.Saturation = -EnemyConfig.DangerDesaturate * share
end
local dangerNow = 0

local EnemyController = {
	Name = "EnemyController",
	FightChanged = nil :: any,
	HealthChanged = nil :: any,
	ResultShown = nil :: any,
	_trove = nil :: TroveInstance?,
}

local function characterParts(): (Model?, BasePart?, Humanoid?)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if root and root:IsA("BasePart") and humanoid then
		return character, root, humanoid
	end
	return nil, nil, nil
end

local function feetPosition(): Vector3?
	local _character, root, humanoid = characterParts()
	if not root or not humanoid then
		return nil
	end
	return root.Position - Vector3.new(0, root.Size.Y / 2 + humanoid.HipHeight, 0)
end

local function setVisible(enemy: Motion.Enemy, isVisible: boolean)
	local parent: Instance? = if isVisible then folder else nil
	if enemy.Model.Parent ~= parent then
		enemy.Model.Parent = parent
	end
end

local function addLabel(model: Model, zone: string, height: number)
	local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	local template = AssetRegistry.get(EnemyConfig.LabelTemplateKey)
	if not adornee or not template:IsA("BillboardGui") then
		template:Destroy()
		return
	end
	local gui = template :: BillboardGui
	Typography.Apply(gui)
	gui.Adornee = adornee
	gui.MaxDistance = EnemyConfig.LabelMaxDistance
	local labelScale = EnemyConfig.LabelScale
	gui.Size = UDim2.new(
		gui.Size.X.Scale * labelScale,
		gui.Size.X.Offset * labelScale,
		gui.Size.Y.Scale * labelScale,
		gui.Size.Y.Offset * labelScale
	)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height / 2 + EnemyConfig.LabelGapStuds, 0)
	for _, descendant in gui:GetDescendants() do
		if descendant:IsA("TextLabel") then
			if descendant.Name == "Title" then
				descendant.Text = string.format(EnemyConfig.GuardianText, zone)
			else
				descendant.Visible = false
			end
		end
	end
	gui.Parent = model
end

local function spawnEnemy(
	zone: string,
	petKey: string,
	home: Vector3,
	scale: number,
	areaMin: Vector3,
	areaMax: Vector3
)
	local pet = PetConfig.Pets[petKey]
	if enemies[zone] or not pet or not folder then
		return
	end
	local asset = AssetRegistry.get(pet.ModelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[EnemyController] {pet.ModelKey} is not a Model`)
		return
	end
	local model: Model = asset
	model.Name = `Enemy_{zone}`
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	model:ScaleTo(scale)
	local size = model:GetExtentsSize()
	enemies[zone] = {
		Zone = zone,
		Model = model,
		Home = home,
		Scale = scale,
		Height = size.Y,
		Radius = math.max(size.X, size.Z) / 2,
		Position = home,
		Facing = EnemyConfig.HomeFacing,
		State = "Home",
		StateAt = os.clock(),
		From = home,
		StaggerAt = 0,
		SlamAt = 0,
		Away = Vector3.zAxis,
		AreaMin = areaMin,
		AreaMax = areaMax,
		FleeTo = home,
		WanderTo = home,
		WanderAt = os.clock() + math.random() * EnemyConfig.WanderPauseMaxSeconds,
		FrozenUntil = 0,
	}
	local outline = Instance.new("Highlight")
	outline.Name = EnemyConfig.OutlineName
	outline.FillTransparency = 1
	outline.OutlineColor = EnemyConfig.OutlineColor
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
	model:PivotTo(CFrame.lookAt(home, home + EnemyConfig.HomeFacing))
	model.Parent = folder
	addLabel(model, zone, size.Y)
end

local function onChopResult(quality: number)
	local current = fight
	local enemy = if current then enemies[current.Zone] else nil
	if not enemy then
		return
	end
	if quality < ChopQuality.Good then
		Audio.Play(EnemyConfig.MissSoundKey)
		return
	end
	local now = os.clock()
	local freeze = EnemyConfig.HitstopSeconds[quality]
	if freeze then
		Motion.Hitstop(enemy, now, freeze)
		local character = characterParts()
		if character then
			Hitstop.Character(character, freeze)
		end
	else
		Motion.Stagger(enemy, now)
	end
	Effects.Hit(enemy.Position + Vector3.new(0, enemy.Height / 2, 0))
end

local function bindInput()
	local trove = Trove.new()
	inputTrove = trove
	local promptsWereEnabled = ProximityPromptService.Enabled
	ProximityPromptService.Enabled = false
	trove:Add(function()
		ProximityPromptService.Enabled = promptsWereEnabled
	end)
end

local function unbindInput()
	if inputTrove then
		inputTrove:Destroy()
		inputTrove = nil
	end
end

local function hideScreens()
	local trove = screensTrove
	if not trove then
		return
	end
	trove:Clean()
	for _, name in EnemyConfig.HiddenScreens do
		if uiController:IsOpen(name) then
			uiController:Close(name)
			trove:Add(function()
				uiController:Open(name)
			end)
		end
	end
end

local function endStage()
	holdUntil = nil
	local enemy = holdEnemy
	holdEnemy = nil
	if enemy and enemy.State == "Hold" then
		Motion.Set(enemy, "Return", os.clock())
	end
	strike = nil
	dangerNow = 0
	if stageTrove then
		stageTrove:Clean()
	end
	uiController:Close(EnemyConfig.ScreenName)
end

local function startStage(enemy: Motion.Enemy?, startedAt: number)
	local character, root, humanoid = characterParts()
	local feet = feetPosition()
	local trove = stageTrove
	if not trove or not character or not root or not humanoid or not feet then
		return
	end
	local context: Sequence.Context = {
		Trove = trove,
		Character = character,
		Root = root,
		Humanoid = humanoid,
		Enemy = enemy,
		Feet = feet,
		StartedAt = startedAt,
		GetDanger = function(): number
			return dangerNow
		end,
	}
	Sequence.Hold(context)
	Sequence.Camera(context)
	Sequence.Tint(context)
	strike = Sequence.Strikes(context)
end

local function onFightStarted(zone: string, maxHealth: number, startHealth: number, introSeconds: number)
	endStage()
	if arrowTrove then
		arrowTrove:Clean()
	end
	local now = os.clock()
	fight = {
		Zone = zone,
		Name = string.format(EnemyConfig.GuardianText, zone),
		Health = startHealth,
		MaxHealth = maxHealth,
		StartedAt = now,
		FightsAt = now + introSeconds,
		Anchor = feetPosition(),
	}
	unbindInput()
	bindInput()
	local enemy = enemies[zone]
	if enemy then
		if enemy.State == "Gone" or enemy.State == "Defeat" then
			Motion.Set(enemy, "Rise", now)
		end
		setVisible(enemy, true)
		Motion.Set(enemy, "Charge", now)
	end
	hideScreens()
	if musicTrove then
		musicTrove:Clean()
		fightMusic = Audio.StartMusic(musicTrove, musicController)
	end
	Audio.Play(EnemyConfig.RoarSoundKey)
	startStage(enemy, now)
	uiController:Open(EnemyConfig.ScreenName)
	EnemyController.FightChanged:Fire(fight)
end

local function onChopStart(
	zone: string,
	ratio: number,
	center: number,
	health: number,
	maxHealth: number,
	secondsLeft: number
)
	local current = fight
	local enemy = enemies[zone]
	if not current or current.Zone ~= zone or not enemy then
		Packets.ChopLeave:Fire()
		return
	end
	strike = nil
	dangerNow = 0
	if stageTrove then
		stageTrove:Clean()
	end
	local target = enemy.Model.PrimaryPart or enemy.Model:FindFirstChildWhichIsA("BasePart", true)
	if not target then
		Packets.ChopLeave:Fire()
		return
	end
	current.Health = health
	EnemyController.HealthChanged:Fire(health, maxHealth)
	chopController:BeginExternal(target, ratio, center, health, maxHealth, secondsLeft, EnemyRules.SweepSpeed)
	startDanger(secondsLeft)
end

local function launchPlayer(zone: string, enemy: Motion.Enemy?, target: Vector3?)
	local character, root = characterParts()
	if not character or not root or not launchTrove then
		return
	end
	Effects.Launch(root.Position)
	Launch.Play(
		launchTrove,
		character,
		if enemy then enemy.Position else root.Position,
		ZoneScale.Of(zone),
		function(hit: RaycastResult)
			Effects.Dent(hit)
			if target and arrowTrove then
				Arrows.Show(arrowTrove, character, target)
			end
		end
	)
end

local function onFightEnded(zone: string, result: string)
	stopDanger()
	fightMusic = nil
	if musicTrove then
		musicTrove:Clean()
	end
	if result == "Won" then
		Audio.Play(EnemyConfig.WinSoundKey)
	elseif result == "Lost" then
		Audio.Play(EnemyConfig.LoseSoundKey)
	end
	local target = fight and fight.Anchor
	fight = nil
	unbindInput()
	if screensTrove then
		screensTrove:Clean()
	end
	EnemyController.FightChanged:Fire(nil)
	local enemy = enemies[zone]
	local now = os.clock()
	if result == "Won" then
		if enemy then
			Effects.Defeat(enemy.Position + Vector3.new(0, enemy.Height / 2, 0))
			Motion.Knock(enemy, feetPosition() or enemy.Position, now)
		end
		holdUntil = now + EnemyConfig.WinHoldSeconds
		EnemyController.ResultShown:Fire(result)
	elseif result == "Lost" then
		if enemy then
			Motion.Set(enemy, "Hold", now)
			holdEnemy = enemy
		end
		holdUntil = now + EnemyConfig.LoseHoldSeconds
		EnemyController.ResultShown:Fire(result)
		launchPlayer(zone, enemy, target)
	else
		if enemy then
			Motion.Set(enemy, "Return", now)
		end
		endStage()
	end
end

local function flee(enemy: Motion.Enemy, now: number)
	local feet = feetPosition()
	Effects.Flee(enemy.Position)
	Motion.Flee(enemy, feet or enemy.Position, now)
end

local function onFled(zone: string)
	local enemy = enemies[zone]
	if enemy and enemy.State ~= "Flee" and enemy.State ~= "Gone" then
		flee(enemy, os.clock())
	end
end

local function step(dt: number)
	stepDanger()
	local now = os.clock()
	if holdUntil and now >= holdUntil then
		endStage()
	end
	local feet = feetPosition()
	local strength = dataController:Get({ "Strength" })
	local strengthNumber = if type(strength) == "number" then strength else 0
	for zone, enemy in enemies do
		local distance = if feet then (feet - enemy.Position).Magnitude else math.huge
		local zoneScale = ZoneScale.Of(zone)
		local outgrown = EnemyRules.Flees(strengthNumber, zone)
		local isActive = distance <= EnemyConfig.ActiveStuds * zoneScale
		if (enemy.State == "Home" or enemy.State == "Wander") and not outgrown then
			if (enemy.Position - enemy.Home).Magnitude > EnemyConfig.WanderLeashStuds * zoneScale then
				Motion.Set(enemy, "Return", now)
			elseif enemy.State == "Home" and isActive and now >= enemy.WanderAt and folder then
				local target = Wander.Pick(enemy, folder, zoneScale)
				if target then
					Motion.Wander(enemy, target, now)
				else
					Motion.Set(enemy, "Home", now)
				end
			end
		elseif enemy.State == "Home" and feet and distance <= EnemyConfig.FleeNearStuds * zoneScale then
			local run = (Motion.FurthestPoint(enemy, feet) - enemy.Position).Magnitude
			if run >= EnemyConfig.FleeMinRunStuds * zoneScale then
				flee(enemy, now)
			end
		elseif enemy.State == "Gone" then
			local waited = now - enemy.StateAt >= EnemyConfig.DefeatedSeconds
			local homeDistance = if feet then (feet - enemy.Home).Magnitude else math.huge
			local isClear = not outgrown or homeDistance > EnemyConfig.FleeReturnStuds * zoneScale
			if waited and isClear then
				Motion.Set(enemy, "Rise", now)
			end
		end
		local isGone = enemy.State == "Gone"
		setVisible(enemy, not isGone)
		local isIdle = enemy.State == "Home" or enemy.State == "Wander"
		if isGone or (isIdle and not isActive) then
			continue
		end
		if Motion.Step(enemy, dt, now, feet) then
			Effects.Slam(enemy.Position)
		end
	end
end

function EnemyController.GetFight(_self: any): FightView?
	return fight
end

function EnemyController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	self.FightChanged = Signal.new()
	self.HealthChanged = Signal.new()
	self.ResultShown = Signal.new()
	launchTrove = Trove.new()
	stageTrove = Trove.new()
	screensTrove = Trove.new()
	arrowTrove = Trove.new()
	musicTrove = Trove.new()
	musicController = controllers.MusicController
	dataController = controllers.DataController
	uiController = controllers.UIController
	chopController = controllers.ChopController
end

function EnemyController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local created = Instance.new("Folder")
	created.Name = EnemyConfig.ModelFolderName
	created.Parent = workspace
	folder = created
	trove:Add(created)
	trove:Add(Packets.EnemySpawned.OnClientEvent:Connect(spawnEnemy))
	trove:Add(Packets.EnemyFightStarted.OnClientEvent:Connect(onFightStarted))
	trove:Add(Packets.EnemyChopStart.OnClientEvent:Connect(onChopStart))
	trove:Add(chopController.ResultShown:Connect(onChopResult))
	trove:Add(Packets.EnemyFightEnded.OnClientEvent:Connect(onFightEnded))
	trove:Add(Packets.EnemyFled.OnClientEvent:Connect(onFled))
	trove:Add(Packets.EnemyFightShown.OnClientEvent:Connect(Effects.Shown))
	trove:Add(RunService.Heartbeat:Connect(step))
	Packets.EnemyReady:Fire()
end

function EnemyController.Destroy(self: any)
	stopDanger()
	unbindInput()
	for _, owned: any in { launchTrove, stageTrove, screensTrove, arrowTrove, musicTrove } do
		if owned then
			owned:Destroy()
		end
	end
	launchTrove, stageTrove, screensTrove, arrowTrove, musicTrove = nil, nil, nil, nil, nil
	holdUntil = nil
	holdEnemy = nil
	strike = nil
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
	for _, enemy in enemies do
		enemy.Model:Destroy()
	end
	table.clear(enemies)
	folder = nil
	fight = nil
	if self.FightChanged then
		self.FightChanged:Destroy()
		self.FightChanged = nil
	end
	for _, name in { "HealthChanged", "ResultShown" } do
		if self[name] then
			self[name]:Destroy()
			self[name] = nil
		end
	end
end

return EnemyController
