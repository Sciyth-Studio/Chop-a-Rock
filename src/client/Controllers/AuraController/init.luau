--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Paint = require(script.Paint)

type TroveInstance = typeof(Trove.new())

type Spinner = {
	Attachment: Attachment,
	Base: CFrame,
	DegreesPerSecond: number,
	Angle: number,
}

type Worn = {
	Tier: number,
	Character: Model,
	Instances: { Instance },
	Spinners: { Spinner },
}

local AuraController = {
	Name = "AuraController",
}

local trove = Trove.new()
local template: Model? = nil
local isMissing = false
local worn: { [Player]: Worn } = {}
local playerTroves: { [Player]: TroveInstance } = {}

local function getTemplate(): Model?
	if template or isMissing then
		return template
	end
	local asset = AssetRegistry.get(AuraConfig.AssetKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[AuraController] {AuraConfig.AssetKey} is not a Model`)
		isMissing = true
		return nil
	end
	template = asset
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

local function attach(
	source: Instance,
	target: BasePart,
	emitScale: number,
	tier: AuraConfig.AuraTier,
	current: Worn
)
	local copies: { [Attachment]: Attachment } = {}
	for _, child in source:GetChildren() do
		if child:IsA("Attachment") then
			local copy = child:Clone()
			if Paint.Apply(copy, tier, emitScale) then
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
	end
	local function place(copy: Instance)
		if Paint.Apply(copy, tier, emitScale) then
			copy.Parent = target
			table.insert(current.Instances, copy)
		end
	end
	for _, child in source:GetChildren() do
		if child:IsA("Beam") then
			local copy = child:Clone()
			copy.Attachment0 = if child.Attachment0 then copies[child.Attachment0] else nil
			copy.Attachment1 = if child.Attachment1 then copies[child.Attachment1] else nil
			place(copy)
		elseif child:IsA("Trail") then
			local copy = child:Clone()
			copy.Attachment0 = if child.Attachment0 then copies[child.Attachment0] else nil
			copy.Attachment1 = if child.Attachment1 then copies[child.Attachment1] else nil
			place(copy)
		elseif child:IsA("ParticleEmitter") or child:IsA("PointLight") then
			place(child:Clone())
		end
	end
end

local function apply(player: Player)
	local tierIndex = player:GetAttribute(AuraConfig.Attribute)
	local tier = if type(tierIndex) == "number" then AuraConfig.Tiers[tierIndex] else nil
	local color = if tier then tier.Color else nil
	local character = player.Character
	local current = worn[player]
	if current and color and current.Tier == tierIndex and current.Character == character then
		return
	end
	remove(player)
	if not tier or not color or not character or type(tierIndex) ~= "number" then
		return
	end
	local source = getTemplate()
	if not source then
		return
	end
	local emitScale = if player == Players.LocalPlayer then 1 else LowGraphics.EmitScale()
	local nextWorn: Worn = { Tier = tierIndex, Character = character, Instances = {}, Spinners = {} }
	local limbSource = source:FindFirstChild(AuraConfig.LimbTemplate)
	if limbSource then
		for _, partName in AuraConfig.LimbParts do
			local part = character:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				attach(limbSource, part, emitScale, tier, nextWorn)
			end
		end
	end
	local bodySource = source:FindFirstChild(AuraConfig.BodyTemplate)
	local body = character:FindFirstChild(AuraConfig.BodyPart)
	if bodySource and body and body:IsA("BasePart") then
		attach(bodySource, body, emitScale, tier, nextWorn)
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
	if template then
		template:Destroy()
		template = nil
	end
	isMissing = false
	trove:Clean()
end

return AuraController
