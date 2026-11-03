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
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)
local Effects = require(script.Effects)
local Launch = require(script.Launch)
local Motion = require(script.Motion)

type TroveInstance = typeof(Trove.new())

export type FightView = {
	Zone: string,
	Name: string,
	Health: number,
	MaxHealth: number,
}

local HIT_ACTION = "EnemyFightHit"

local enemies: { [string]: Motion.Enemy } = {}
local folder: Folder? = nil
local dataController: any = nil
local uiController: any = nil
local fight: FightView? = nil
local inputTrove: TroveInstance? = nil
local launchTrove: TroveInstance? = nil
local lastClick = 0

local EnemyController = {
	Name = "EnemyController",
	FightChanged = nil :: any,
	HealthChanged = nil :: any,
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

local function spawnEnemy(zone: string, petKey: string, home: Vector3, scale: number)
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
		Facing = Vector3.zAxis,
		State = "Home",
		StateAt = os.clock(),
		From = home,
		StaggerAt = 0,
		SlamAt = 0,
		Away = Vector3.zAxis,
	}
	model:PivotTo(CFrame.lookAt(home, home + Vector3.zAxis))
	model.Parent = folder
end

local function click()
	local current = fight
	if not current then
		return
	end
	local now = os.clock()
	if now - lastClick < 1 / EnemyConfig.ClientClicksPerSecond then
		return
	end
	lastClick = now
	Packets.EnemyClick:Fire()
	local enemy = enemies[current.Zone]
	if enemy then
		Motion.Stagger(enemy, now)
		Effects.Hit(enemy.Position + Vector3.new(0, enemy.Height / 2, 0))
	end
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

local function onFightStarted(zone: string, maxHealth: number, startHealth: number)
	local pet = PetConfig.Pets[EnemyRules.PetKey(zone)]
	fight = {
		Zone = zone,
		Name = if pet then pet.DisplayName else zone,
		Health = startHealth,
		MaxHealth = maxHealth,
	}
	unbindInput()
	bindInput()
	local enemy = enemies[zone]
	if enemy then
		if enemy.State == "Gone" or enemy.State == "Defeat" then
			Motion.Set(enemy, "Rise", os.clock())
		end
		setVisible(enemy, true)
		Motion.Set(enemy, "Charge", os.clock())
	end
	uiController:Open(EnemyConfig.ScreenName)
	EnemyController.FightChanged:Fire(fight)
end

local function onFightHit(health: number)
	local current = fight
	if current then
		current.Health = health
		EnemyController.HealthChanged:Fire(health, current.MaxHealth)
	end
end

local function onFightEnded(zone: string, result: string)
	fight = nil
	unbindInput()
	uiController:Close(EnemyConfig.ScreenName)
	EnemyController.FightChanged:Fire(nil)
	local enemy = enemies[zone]
	local now = os.clock()
	if enemy then
		if result == "Won" then
			Effects.Defeat(enemy.Position + Vector3.new(0, enemy.Height / 2, 0))
			Motion.Set(enemy, "Defeat", now)
		else
			Motion.Set(enemy, "Return", now)
		end
	end
	if result == "Lost" then
		local character, root = characterParts()
		if character and root and launchTrove then
			Effects.Launch(root.Position)
			Launch.Play(
				launchTrove,
				character,
				if enemy then enemy.Position else root.Position,
				ZoneScale.Of(zone)
			)
		end
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
	local feet = feetPosition()
	local strength = dataController:Get({ "Strength" })
	local strengthNumber = if type(strength) == "number" then strength else 0
	for zone, enemy in enemies do
		local distance = if feet then (feet - enemy.Home).Magnitude else math.huge
		local zoneScale = ZoneScale.Of(zone)
		local outgrown = EnemyRules.Flees(strengthNumber, zone)
		if enemy.State == "Home" and outgrown and distance <= EnemyConfig.FleeNearStuds * zoneScale then
			flee(enemy, now)
		elseif enemy.State == "Gone" then
			local waited = now - enemy.StateAt >= EnemyConfig.DefeatedSeconds
			local isClear = not outgrown or distance > EnemyConfig.FleeReturnStuds * zoneScale
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
	launchTrove = Trove.new()
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
	if launchTrove then
		launchTrove:Destroy()
		launchTrove = nil
	end
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
	if self.HealthChanged then
		self.HealthChanged:Destroy()
		self.HealthChanged = nil
	end
end

return EnemyController
