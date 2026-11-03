--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

local Effects = {}

local soundSeconds = 5
local templates: { [string]: Model } = {}

local function anchorAt(position: Vector3): Attachment
	local anchor = Instance.new("Attachment")
	anchor.Name = "EnemyEffect"
	anchor.WorldPosition = position
	anchor.Parent = workspace.Terrain
	task.delay(soundSeconds, function()
		anchor:Destroy()
	end)
	return anchor
end

local function sound(key: string, parent: Instance, volume: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	if volume then
		asset.Volume *= volume
	end
	asset.Parent = parent
	asset:Play()
	task.delay(soundSeconds, function()
		asset:Destroy()
	end)
end

local function dust(parent: Instance)
	if LowGraphics.IsOn() then
		return
	end
	local asset = AssetRegistry.get(EnemyConfig.DustKey)
	if not asset:IsA("Attachment") then
		asset:Destroy()
		return
	end
	asset.Parent = parent
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant:Emit(EnemyConfig.DustEmitCount)
		end
	end
	task.delay(EnemyConfig.DustLifetimeSeconds, function()
		asset:Destroy()
	end)
end

local function burst(key: string, position: Vector3)
	if LowGraphics.IsOn() then
		return
	end
	local template = templates[key]
	if not template then
		local asset = AssetRegistry.get(key)
		if not asset:IsA("Model") then
			asset:Destroy()
			return
		end
		template = asset
		templates[key] = asset
	end
	VFXEmit.play(template, CFrame.new(position))
end

function Effects.Hit(position: Vector3)
	burst(EnemyConfig.HitEffectKey, position)
	sound(EnemyConfig.HitSoundKey, anchorAt(position), EnemyConfig.HitSoundVolume)
end

function Effects.Slam(position: Vector3)
	local anchor = anchorAt(position)
	dust(anchor)
	sound(EnemyConfig.SlamSoundKey, anchor)
end

function Effects.Defeat(position: Vector3)
	burst(EnemyConfig.DefeatEffectKey, position)
	local anchor = anchorAt(position)
	dust(anchor)
	sound(EnemyConfig.DefeatSoundKey, anchor)
end

function Effects.Flee(position: Vector3)
	local anchor = anchorAt(position)
	dust(anchor)
	sound(EnemyConfig.FleeSoundKey, anchor)
end

function Effects.Launch(position: Vector3)
	local anchor = anchorAt(position)
	dust(anchor)
	sound(EnemyConfig.LaunchSoundKey, anchor)
end

function Effects.Swirl(position: Vector3)
	burst(EnemyConfig.SwirlKey, position)
end

local function makeDentPart(size: Vector3, color: Color3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = "FightDent"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Slate
	part.Size = size
	part.Color = color
	part.CFrame = cframe
	part.Parent = workspace
	task.delay(EnemyConfig.DentSeconds, function()
		part:Destroy()
	end)
	return part
end

function Effects.Dent(hit: RaycastResult)
	local instance = hit.Instance
	local ground = if instance:IsA("BasePart") and not instance:IsA("Terrain")
		then instance.Color
		else EnemyConfig.DentFallbackColor
	local radius = EnemyConfig.DentRadiusStuds
	local hole = makeDentPart(
		Vector3.new(0.1, radius * 2, radius * 2),
		ground:Lerp(Color3.new(0, 0, 0), EnemyConfig.DentDarken),
		CFrame.new(hit.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	)
	hole.Shape = Enum.PartType.Cylinder
	for index = 1, EnemyConfig.DentChunkCount do
		local angle = index / EnemyConfig.DentChunkCount * math.pi * 2
		local chunk = CFrame.new(hit.Position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius)
			* CFrame.Angles(math.rad(25), angle, math.rad(25))
		local size = EnemyConfig.DentChunkStuds
		makeDentPart(Vector3.new(size, size, size), ground, chunk)
	end
	local anchor = anchorAt(hit.Position)
	dust(anchor)
	sound(EnemyConfig.SlamSoundKey, anchor)
end

function Effects.Shown(position: Vector3, kind: string)
	if kind == "Won" then
		Effects.Defeat(position)
	elseif kind == "Lost" then
		Effects.Launch(position)
	else
		local anchor = anchorAt(position)
		dust(anchor)
		sound(EnemyConfig.HitSoundKey, anchor, EnemyConfig.HitSoundVolume)
	end
end

return Effects
