--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Original = { Material: Enum.Material, Color: Color3 }

local ARM_PARTS =
	{ "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }
local HAND_PARTS = { LeftHand = true, RightHand = true }
local EFFECT_NAME = "ArmEffect"
local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local trove = Trove.new()
local services: { [string]: any } = {}
local playerTroves: { [Player]: any } = {}
local originals: { [BasePart]: Original } = setmetatable({}, { __mode = "k" }) :: any

local ArmVisualService = {
	Name = "ArmVisualService",
}

local function makeEffect(visual: ArmConfig.ArmVisual): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = EFFECT_NAME
	emitter.Texture = SPARK_TEXTURE
	emitter.Color = ColorSequence.new(visual.EffectColor or Color3.new(1, 1, 1))
	emitter.LightEmission = 1
	emitter.Rate = visual.EffectRate
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	return emitter
end

local function apply(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local tier = ArmConfig.Tiers[services.ArmService:GetTier(player)] or ArmConfig.Tiers[1]
	local visual = tier.Visual

	for _, partName in ARM_PARTS do
		local part = character:FindFirstChild(partName)
		if not part or not part:IsA("BasePart") then
			continue
		end
		local original = originals[part]
		if not original then
			original = { Material = part.Material, Color = part.Color }
			originals[part] = original
		end
		part.Material = visual.Material or original.Material
		part.Color = visual.Color or original.Color

		local existing = part:FindFirstChild(EFFECT_NAME)
		if existing then
			existing:Destroy()
		end
		if HAND_PARTS[partName] and visual.EffectRate > 0 then
			makeEffect(visual).Parent = part
		end
	end
end

local function track(player: Player)
	local playerTrove = Trove.new()
	playerTroves[player] = playerTrove

	local function applyWhenReady(character: Model)
		task.spawn(function()
			character:WaitForChild("LeftHand", 10)
			character:WaitForChild("RightHand", 10)
			if character.Parent then
				apply(player)
			end
		end)
	end

	playerTrove:Connect(player.CharacterAdded, applyWhenReady)
	if player.Character then
		applyWhenReady(player.Character)
	end
end

function ArmVisualService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ArmVisualService.Start(_self: any)
	trove:Add(services.ArmService.TierChanged:Connect(function(player: Player)
		apply(player)
	end))
	trove:Add(Players.PlayerAdded:Connect(track))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		local playerTrove = playerTroves[player]
		if playerTrove then
			playerTrove:Destroy()
			playerTroves[player] = nil
		end
	end))
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

function ArmVisualService.Destroy(_self: any)
	for _, playerTrove in playerTroves do
		playerTrove:Destroy()
	end
	table.clear(playerTroves)
	trove:Clean()
end

return ArmVisualService
