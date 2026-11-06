--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

local FallEffects = {}

local soundSeconds = 8

local function tintSequence(sequence: ColorSequence, color: Color3): ColorSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		local value = keypoint.Value
		local spread = math.max(value.R, value.G, value.B) - math.min(value.R, value.G, value.B)
		table.insert(
			keypoints,
			ColorSequenceKeypoint.new(
				keypoint.Time,
				if spread >= GeodeFallConfig.TintSaturation then color else value
			)
		)
	end
	return ColorSequence.new(keypoints)
end

function FallEffects.Tint(root: Instance, color: Color3)
	for _, item in root:GetDescendants() do
		if item:GetAttribute(GeodeFallConfig.TintAttribute) ~= true then
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

function FallEffects.Play(key: string, cframe: CFrame, color: Color3, scale: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	FallEffects.Tint(asset, color)
	if scale and scale ~= 1 then
		asset:ScaleTo(scale)
	end
	VFXEmit.play(asset, cframe)
	asset:Destroy()
end

function FallEffects.AddMeteor(trove: any, part: BasePart): () -> ()
	local asset = AssetRegistry.get(GeodeFallConfig.MeteorKey)
	local root = if asset:IsA("Model") then asset.PrimaryPart or asset:FindFirstChild("Root") else nil
	if not root then
		asset:Destroy()
		return function() end
	end
	local moved: { Instance } = {}
	for _, child in root:GetChildren() do
		child.Parent = part
		trove:Add(child)
		table.insert(moved, child)
		for _, item in child:GetDescendants() do
			if item:IsA("ParticleEmitter") then
				item.Enabled = true
			end
		end
	end
	asset:Destroy()
	return function()
		for _, child in moved do
			for _, item in child:GetDescendants() do
				if item:IsA("ParticleEmitter") then
					item.Enabled = false
				end
			end
		end
	end
end

function FallEffects.SoundAt(key: string, position: Vector3)
	local sound = AssetRegistry.get(key)
	if not sound:IsA("Sound") then
		sound:Destroy()
		return
	end
	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = position
	anchor.Parent = workspace.Terrain
	sound.Parent = anchor
	sound:Play()
	task.delay(soundSeconds, function()
		anchor:Destroy()
	end)
end

function FallEffects.ShakeCamera(position: Vector3, studs: number?, seconds: number?)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end
	if (root.Position - position).Magnitude > GeodeFallConfig.ShakeDistance then
		return
	end
	local strength = studs or GeodeFallConfig.ShakeStuds
	local duration = seconds or GeodeFallConfig.ShakeSeconds
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local progress = (os.clock() - started) / duration
		if progress >= 1 or not humanoid.Parent then
			connection:Disconnect()
			humanoid.CameraOffset = Vector3.zero
			return
		end
		local shake = strength * (1 - progress)
		humanoid.CameraOffset = Vector3.new(
			(math.random() * 2 - 1) * shake,
			(math.random() * 2 - 1) * shake,
			(math.random() * 2 - 1) * shake
		)
	end)
end

function FallEffects.AddIdle(trove: any, ground: CFrame, color: Color3, scale: number?, hasPillar: boolean?)
	local asset = AssetRegistry.get(GeodeFallConfig.IdleKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	if hasPillar == false then
		for _, item in asset:GetDescendants() do
			if item:IsA("Beam") then
				item:Destroy()
			end
		end
	end
	FallEffects.Tint(asset, color)
	if scale and scale ~= 1 then
		asset:ScaleTo(scale)
	end
	local top = asset:FindFirstChild(GeodeFallConfig.PillarTopName, true)
	if top and top:IsA("Attachment") then
		top.Position = Vector3.new(0, GeodeFallConfig.PillarHeightStuds, 0)
	end
	asset:PivotTo(ground)
	asset.Parent = workspace
	trove:Add(asset)
end

function FallEffects.PaintLabel(label: TextLabel?, color: Color3)
	if not label then
		return
	end
	local light = color:Lerp(Color3.new(1, 1, 1), GeodeFallConfig.LabelLightLerp)
	local dark = color:Lerp(Color3.new(0, 0, 0), GeodeFallConfig.LabelDarkLerp)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, light),
			ColorSequenceKeypoint.new(1, color),
		})
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = dark
	end
end

return FallEffects
