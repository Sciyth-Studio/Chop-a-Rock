--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

type Spinner = {
	Attachment: Attachment,
	Base: CFrame,
	DegreesPerSecond: number,
	Angle: number,
}

type Worn = {
	Key: string,
	Character: Model,
	Instances: { Instance },
	Spinners: { Spinner },
}

local AuraController = {
	Name = "AuraController",
}

local trove = Trove.new()
local templates: { [string]: Model } = {}
local missing: { [string]: true } = {}
local worn: { [Player]: Worn } = {}
local playerTroves: { [Player]: TroveInstance } = {}
local aurasByKey: { [string]: AuraConfig.Aura } = {}

for _, aura in AuraConfig.Auras do
	aurasByKey[aura.Key] = aura
end

local function getTemplate(aura: AuraConfig.Aura): Model?
	local cached = templates[aura.Key]
	if cached or missing[aura.Key] then
		return cached
	end
	local asset = AssetRegistry.get(aura.AssetKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[AuraController] {aura.AssetKey} is not a Model`)
		missing[aura.Key] = true
		return nil
	end
	templates[aura.Key] = asset
	return asset
end

local function remove(player: Player)
	local current = worn[player]
	if not current then
		return
	end
	worn[player] = nil
	for _, instance in current.Instances do
		instance:Destroy()
	end
end

local function attach(source: Instance, target: BasePart, emitScale: number, current: Worn)
	local copies: { [Attachment]: Attachment } = {}
	for _, child in source:GetChildren() do
		if child:IsA("Attachment") then
			local copy = child:Clone()
			for _, descendant in copy:GetDescendants() do
				if descendant:IsA("ParticleEmitter") then
					descendant.Rate *= emitScale
				end
			end
			copy.Parent = target
			copies[child] = copy
			table.insert(current.Instances, copy)
			local speed = child:GetAttribute(AuraConfig.SpinAttribute)
			if type(speed) == "number" and speed ~= 0 then
				table.insert(
					current.Spinners,
					{ Attachment = copy, Base = copy.CFrame, DegreesPerSecond = speed, Angle = 0 }
				)
			end
		end
	end
	for _, child in source:GetChildren() do
		if child:IsA("Beam") then
			local copy = child:Clone()
			copy.Attachment0 = if child.Attachment0 then copies[child.Attachment0] else nil
			copy.Attachment1 = if child.Attachment1 then copies[child.Attachment1] else nil
			copy.Parent = target
			table.insert(current.Instances, copy)
		elseif child:IsA("Trail") then
			local copy = child:Clone()
			copy.Attachment0 = if child.Attachment0 then copies[child.Attachment0] else nil
			copy.Attachment1 = if child.Attachment1 then copies[child.Attachment1] else nil
			copy.Parent = target
			table.insert(current.Instances, copy)
		elseif child:IsA("ParticleEmitter") then
			local copy = child:Clone()
			copy.Rate *= emitScale
			copy.Parent = target
			table.insert(current.Instances, copy)
		elseif child:IsA("PointLight") then
			local copy = child:Clone()
			copy.Parent = target
			table.insert(current.Instances, copy)
		end
	end
end

local function apply(player: Player)
	local key = player:GetAttribute(AuraConfig.Attribute)
	local aura = if type(key) == "string" then aurasByKey[key] else nil
	local character = player.Character
	local current = worn[player]
	if current and aura and current.Key == aura.Key and current.Character == character then
		return
	end
	remove(player)
	if not aura or not character then
		return
	end
	local template = getTemplate(aura)
	if not template then
		return
	end
	local emitScale = if player == Players.LocalPlayer then 1 else LowGraphics.EmitScale()
	local nextWorn: Worn = { Key = aura.Key, Character = character, Instances = {}, Spinners = {} }
	local limbSource = template:FindFirstChild(AuraConfig.LimbTemplate)
	if limbSource then
		for _, partName in AuraConfig.LimbParts do
			local part = character:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				attach(limbSource, part, emitScale, nextWorn)
			end
		end
	end
	local bodySource = template:FindFirstChild(AuraConfig.BodyTemplate)
	local body = character:FindFirstChild(AuraConfig.BodyPart)
	if bodySource and body and body:IsA("BasePart") then
		attach(bodySource, body, emitScale, nextWorn)
	end
	worn[player] = nextWorn
end

local function track(player: Player)
	if playerTroves[player] then
		return
	end
	local playerTrove = Trove.new()
	playerTroves[player] = playerTrove
	playerTrove:Connect(player:GetAttributeChangedSignal(AuraConfig.Attribute), function()
		apply(player)
	end)
	playerTrove:Connect(player.CharacterAdded, function(character: Model)
		remove(player)
		for _, partName in AuraConfig.LimbParts do
			character:WaitForChild(partName, 10)
		end
		character:WaitForChild(AuraConfig.BodyPart, 10)
		if character.Parent and player.Character == character then
			apply(player)
		end
	end)
	playerTrove:Add(function()
		remove(player)
	end)
	task.spawn(apply, player)
end

local function untrack(player: Player)
	local playerTrove = playerTroves[player]
	if playerTrove then
		playerTroves[player] = nil
		playerTrove:Destroy()
	end
end

local function spin(dt: number)
	for _, current in worn do
		for _, spinner in current.Spinners do
			spinner.Angle = (spinner.Angle + spinner.DegreesPerSecond * dt) % 360
			spinner.Attachment.CFrame = CFrame.Angles(0, math.rad(spinner.Angle), 0) * spinner.Base
		end
	end
end

function AuraController.Init(_self: any, _controllers: { [string]: any }) end

function AuraController.Start(_self: any)
	trove:Connect(Players.PlayerAdded, track)
	trove:Connect(Players.PlayerRemoving, untrack)
	trove:Connect(RunService.RenderStepped, spin)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

function AuraController.Destroy(_self: any)
	for player in playerTroves do
		untrack(player)
	end
	for _, template in templates do
		template:Destroy()
	end
	table.clear(templates)
	table.clear(missing)
	trove:Clean()
end

return AuraController
