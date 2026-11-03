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
