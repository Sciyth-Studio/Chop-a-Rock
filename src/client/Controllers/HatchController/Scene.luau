--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HatchRevealConfig = require(ReplicatedStorage.Config.HatchRevealConfig)
local Types = require(script.Parent.Types)

local Scene = {}

function Scene.Animate(seconds: number, isCancelled: () -> boolean, step: (alpha: number) -> ())
	local start = os.clock()
	while true do
		if isCancelled() then
			return
		end
		local alpha = if seconds > 0 then math.min(1, (os.clock() - start) / seconds) else 1
		step(alpha)
		if alpha >= 1 then
			return
		end
		RunService.Heartbeat:Wait()
	end
end

function Scene.Build(spot: Attachment, geodeKey: string): Types.Scene?
	local geode = GeodeConfig.Geodes[geodeKey]
	if not geode then
		return nil
	end
	local asset = AssetRegistry.get(geode.ModelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[HatchController] Asset "{geode.ModelKey}" is not a Model`)
		return nil
	end
	local model = asset :: Model
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	local origin = spot.WorldCFrame
	local _, size = model:GetBoundingBox()
	local folder = Instance.new("Folder")
	folder.Name = HatchRevealConfig.FolderName
	folder.Parent = workspace
	model:PivotTo(origin)
	model.Parent = folder

	local highlight = Instance.new("Highlight")
	highlight.FillColor = HatchRevealConfig.WhiteColor
	highlight.OutlineColor = HatchRevealConfig.WhiteColor
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = folder

	local anchor = Instance.new("Part")
	anchor.Name = "BurstAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = origin
	anchor.Parent = folder

	local scene: Types.Scene = {
		Folder = folder,
		Model = model,
		Origin = origin,
		Scale = model:GetScale(),
		CenterHeight = size.Y / 2,
		Highlight = highlight,
		Anchor = anchor :: BasePart,
	}
	return scene
end

function Scene.Apply(scene: Types.Scene, pose: Types.Pose, elapsed: number)
	local spin = pose.Spin
	local wobble = math.rad(pose.Shake) * math.sin(elapsed * HatchRevealConfig.ShakeFrequency)
	local center = scene.CenterHeight * pose.Scale
	scene.Model:ScaleTo(scene.Scale * pose.Scale)
	scene.Model:PivotTo(
		scene.Origin
			* CFrame.new(0, pose.Height + center, 0)
			* CFrame.Angles(0, spin, wobble)
			* CFrame.new(0, -center, 0)
	)
	scene.Anchor.CFrame = scene.Origin * CFrame.new(0, pose.Height + center, 0)
end

function Scene.Pop(scene: Types.Scene, color: Color3)
	scene.Model.Parent = nil
	scene.Highlight.Adornee = nil
	local asset = AssetRegistry.get(HatchRevealConfig.BurstKey)
	if not asset:IsA("Attachment") then
		asset:Destroy()
		return
	end
	asset.Parent = scene.Anchor
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Color = ColorSequence.new(color)
			local count = descendant:GetAttribute("EmitCount")
			descendant:Emit(if type(count) == "number" then count else HatchRevealConfig.BurstEmitCount)
		end
	end
end

function Scene.Destroy(scene: Types.Scene)
	scene.Model:Destroy()
	scene.Folder:Destroy()
end

return Scene
