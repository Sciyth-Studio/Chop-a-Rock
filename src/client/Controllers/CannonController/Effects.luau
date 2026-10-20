--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

type TroveInstance = typeof(Trove.new())

export type Cache = { [string]: Model }

local Effects = {}

local soundSeconds = 8

function Effects.Load(): Cache
	local cache: Cache = {}
	local names = CannonConfig.Effects
	for _, key in { names.Fuse, names.Charge, names.Blast, names.Trail, names.Land, names.Equip } do
		local asset = AssetRegistry.get(key)
		if asset:IsA("Model") then
			cache[key] = asset
		else
			asset:Destroy()
		end
	end
	return cache
end

local function tintSequence(sequence: ColorSequence, color: Color3): ColorSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		local value = keypoint.Value
		local spread = math.max(value.R, value.G, value.B) - math.min(value.R, value.G, value.B)
		table.insert(
			keypoints,
			ColorSequenceKeypoint.new(
				keypoint.Time,
				if spread >= CannonConfig.TintSaturation then color else value
			)
		)
	end
	return ColorSequence.new(keypoints)
end

local function tint(root: Instance, color: Color3)
	for _, item in root:GetDescendants() do
		if item:GetAttribute(CannonConfig.TintAttribute) ~= true then
			continue
		end
		if item:IsA("ParticleEmitter") then
			item.Color = tintSequence(item.Color, color)
		elseif item:IsA("Trail") then
			item.Color = tintSequence(item.Color, color)
		elseif item:IsA("Beam") then
			item.Color = tintSequence(item.Color, color)
		elseif item:IsA("Light") then
			item.Color = color
		end
	end
end

function Effects.Play(cache: Cache, key: string, cframe: CFrame, color: Color3)
	local template = cache[key]
	if not template then
		return
	end
	local copy = template:Clone()
	tint(copy, color)
	VFXEmit.play(copy, cframe)
	copy:Destroy()
end

function Effects.Sound(key: string, parent: Instance)
	local sound = AssetRegistry.get(key)
	if not sound:IsA("Sound") then
		sound:Destroy()
		return
	end
	sound.Parent = parent
	sound:Play()
	task.delay(soundSeconds, function()
		sound:Destroy()
	end)
end

function Effects.SoundAt(key: string, position: Vector3)
	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = position
	anchor.Parent = workspace.Terrain
	Effects.Sound(key, anchor)
	task.delay(soundSeconds, function()
		anchor:Destroy()
	end)
end

function Effects.Trail(cache: Cache, color: Color3, part: BasePart): () -> ()
	local template = cache[CannonConfig.Effects.Trail]
	local root = if template then template.PrimaryPart or template:FindFirstChild("Root") else nil
	if not template or not root then
		return function() end
	end
	local copy = template:Clone()
	tint(copy, color)
	local copyRoot = copy:FindFirstChild(root.Name)
	local moved: { Instance } = {}
	if copyRoot then
		for _, child in copyRoot:GetChildren() do
			child.Parent = part
			table.insert(moved, child)
		end
	end
	copy:Destroy()
	local function setEnabled(isEnabled: boolean)
		for _, child in moved do
			if child:IsA("Trail") then
				child.Enabled = isEnabled
			end
			for _, item in child:GetDescendants() do
				if item:IsA("ParticleEmitter") then
					item.Enabled = isEnabled
				end
			end
		end
	end
	setEnabled(true)
	local stopped = false
	return function()
		if stopped then
			return
		end
		stopped = true
		setEnabled(false)
		task.delay(CannonConfig.TrailFadeSeconds, function()
			for _, child in moved do
				child:Destroy()
			end
		end)
	end
end

function Effects.Pulse(trove: TroveInstance, model: Instance, seconds: number, onDone: () -> ())
	local parts: { [BasePart]: Color3 } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute(CannonConfig.TintAttribute) == true then
			parts[part] = part.Color
		end
	end
	local began = os.clock()
	local connection: any
	connection = trove:Connect(RunService.Heartbeat, function()
		local alpha = math.min((os.clock() - began) / seconds, 1)
		local flicker = 0.75 + 0.25 * math.sin(alpha * math.pi * 12)
		local lighten = CannonConfig.ChargeLighten * alpha * alpha * flicker
		for part, base in parts do
			part.Color = base:Lerp(Color3.new(1, 1, 1), lighten)
		end
		if alpha >= 1 then
			trove:Remove(connection)
			onDone()
		end
	end)
end

return Effects
