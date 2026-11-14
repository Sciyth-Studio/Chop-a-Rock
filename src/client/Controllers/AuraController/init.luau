--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local KiAura = require(ReplicatedStorage.Utils.KiAura)
local KiAuraConfig = require(ReplicatedStorage.Config.KiAuraConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

type Worn = {
	Tier: number,
	Character: Model,
	Aura: KiAura.Aura,
}

local AuraController = {
	Name = "AuraController",
}

local trove = Trove.new()
local worn: { [Player]: Worn } = {}
local playerTroves: { [Player]: TroveInstance } = {}

local function remove(player: Player)
	local current = worn[player]
	if not current then
		return
	end
	worn[player] = nil
	current.Aura:Destroy()
end

local function mainColor(tier: AuraConfig.AuraTier): Color3?
	local palette = tier.Palette
	local main = if palette then palette.Main else nil
	return if main and main[1] then main[1] else tier.Color
end

local function accentColor(tier: AuraConfig.AuraTier): Color3?
	local palette = tier.Palette
	local edge = if palette then palette.Edge else nil
	return if edge then edge[1] else nil
end

local function intensityOf(tier: AuraConfig.AuraTier): number
	local index = math.clamp(tier.Stage or 3, 1, #AuraConfig.Stages)
	return AuraConfig.Stages[index].Intensity
end

local function apply(player: Player)
	local tierIndex = player:GetAttribute(AuraConfig.Attribute)
	local tier = if type(tierIndex) == "number" then AuraConfig.Tiers[tierIndex] else nil
	local main = if tier then mainColor(tier) else nil
	local character = player.Character
	local current: Worn? = worn[player]
	if current and current.Character ~= character then
		remove(player)
		current = nil
	end
	if not tier or not main or not character or type(tierIndex) ~= "number" then
		remove(player)
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	if current and current.Tier == tierIndex then
		return
	end
	root:SetAttribute(KiAuraConfig.ColorAttribute, main)
	root:SetAttribute(KiAuraConfig.AccentAttribute, accentColor(tier))
	root:SetAttribute(KiAuraConfig.IntensityAttribute, intensityOf(tier))
	if current then
		current.Tier = tierIndex
		current.Aura:SetEnabled(false)
		current.Aura:SetEnabled(true)
		return
	end
	local emitScale = if player == Players.LocalPlayer then 1 else LowGraphics.EmitScale()
	local aura = KiAura.Attach(character, emitScale)
	if not aura then
		return
	end
	worn[player] = { Tier = tierIndex, Character = character, Aura = aura }
	aura:SetEnabled(true)
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
		for _, partName in AuraConfig.WaitParts do
			character:WaitForChild(partName, 10)
		end
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

function AuraController.Init(_self: any, _controllers: { [string]: any }) end

function AuraController.Start(_self: any)
	trove:Connect(Players.PlayerAdded, track)
	trove:Connect(Players.PlayerRemoving, untrack)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

function AuraController.Destroy(_self: any)
	for player in playerTroves do
		untrack(player)
	end
	trove:Clean()
end

return AuraController
