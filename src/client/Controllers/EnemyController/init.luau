--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)
local Arrows = require(script.Arrows)
local Effects = require(script.Effects)
local Launch = require(script.Launch)
local Motion = require(script.Motion)
local Sequence = require(script.Sequence)

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

local HIT_ACTION = "EnemyFightHit"

local enemies: { [string]: Motion.Enemy } = {}
local folder: Folder? = nil
local dataController: any = nil
local uiController: any = nil
local fight: FightView? = nil
local inputTrove: TroveInstance? = nil
local launchTrove: TroveInstance? = nil
local stageTrove: TroveInstance? = nil
local screensTrove: TroveInstance? = nil
local arrowTrove: TroveInstance? = nil
local strike: (() -> ())? = nil
local holdUntil: number? = nil
local holdEnemy: Motion.Enemy? = nil
local dangerNow = 0
local lastClick = 0

local EnemyController = {
	Name = "EnemyController",
	FightChanged = nil :: any,
	HealthChanged = nil :: any,
	ResultShown = nil :: any,
	Clicked = nil :: any,
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
	}
	model:PivotTo(CFrame.lookAt(home, home + EnemyConfig.HomeFacing))
	model.Parent = folder
	addLabel(model, zone, size.Y)
end

local function click()
	local current = fight
	if not current then
		return
	end
	local now = os.clock()
	if now < current.FightsAt or now - lastClick < 1 / EnemyConfig.ClientClicksPerSecond then
		return
	end
	lastClick = now
	Packets.EnemyClick:Fire()
	local enemy = enemies[current.Zone]
	if enemy then
		Motion.Stagger(enemy, now)
		Effects.Hit(enemy.Position + Vector3.new(0, enemy.Height / 2, 0))
	end
	if strike then
		strike()
	end
	EnemyController.Clicked:Fire()
end

local function bindInput()
	local trove = Trove.new()
	inputTrove = trove
	local promptsWereEnabled = ProximityPromptService.Enabled
	ProximityPromptService.Enabled = false
	trove:Add(function()
		ProximityPromptService.Enabled = promptsWereEnabled
		ContextActionService:UnbindAction(HIT_ACTION)
	end)
	ContextActionService:BindAction(HIT_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			click()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle(HIT_ACTION, EnemyConfig.TouchButtonTitle)
	trove:Add(UserInputService.InputBegan:Connect(function(input: InputObject, isProcessed: boolean)
		local isPress = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		if isPress and not isProcessed then
			click()
		end
	end))
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
	startStage(enemy, now)
	uiController:Open(EnemyConfig.ScreenName)
	EnemyController.FightChanged:Fire(fight)
end

local function onFightHit(health: number)
	local current = fight
	if current then
		current.Health = health
		local share = 1 - math.clamp(health / math.max(current.MaxHealth, 1e-9), 0, 1)
		dangerNow = math.clamp(1 - share / EnemyConfig.StartShare, 0, 1)
		EnemyController.HealthChanged:Fire(health, current.MaxHealth)
	end
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
		if enemy.State == "Home" and not outgrown then
			if (enemy.Position - enemy.Home).Magnitude > 1 then
				Motion.Set(enemy, "Return", now)
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
		if isGone or (enemy.State == "Home" and distance > EnemyConfig.ActiveStuds * zoneScale) then
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
	self.Clicked = Signal.new()
	launchTrove = Trove.new()
	stageTrove = Trove.new()
	screensTrove = Trove.new()
	arrowTrove = Trove.new()
	dataController = controllers.DataController
	uiController = controllers.UIController
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
	trove:Add(Packets.EnemyFightHit.OnClientEvent:Connect(onFightHit))
	trove:Add(Packets.EnemyFightEnded.OnClientEvent:Connect(onFightEnded))
	trove:Add(Packets.EnemyFled.OnClientEvent:Connect(onFled))
	trove:Add(Packets.EnemyFightShown.OnClientEvent:Connect(Effects.Shown))
	trove:Add(RunService.Heartbeat:Connect(step))
	Packets.EnemyReady:Fire()
end

function EnemyController.Destroy(self: any)
	unbindInput()
	for _, owned: any in { launchTrove, stageTrove, screensTrove, arrowTrove } do
		if owned then
			owned:Destroy()
		end
	end
	launchTrove, stageTrove, screensTrove, arrowTrove = nil, nil, nil, nil
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
	for _, name in { "HealthChanged", "ResultShown", "Clicked" } do
		if self[name] then
			self[name]:Destroy()
			self[name] = nil
		end
	end
end

return EnemyController
