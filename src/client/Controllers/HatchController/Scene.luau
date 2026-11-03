--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HatchRevealConfig = require(ReplicatedStorage.Config.HatchRevealConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetModifier = require(ReplicatedStorage.PetModifier)
local PetSize = require(ReplicatedStorage.PetSize)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RarityRibbon = require(ReplicatedStorage.Utils.RarityRibbon)
local Typography = require(ReplicatedStorage.Utils.Typography)
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

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name)
	if found and found:IsA("TextLabel") then
		return found
	end
	warn(`[HatchController] Missing TextLabel "{name}" in {root:GetFullName()}`)
	return nil
end

local function addLabel(scene: Types.Scene, hatch: Types.Hatch, topHeight: number)
	local asset = AssetRegistry.get(HatchRevealConfig.LabelKey)
	if not asset:IsA("BillboardGui") then
		asset:Destroy()
		warn(`[HatchController] Asset "{HatchRevealConfig.LabelKey}" is not a BillboardGui`)
		return
	end
	local gui = asset :: BillboardGui
	Typography.Apply(gui)
	local anchor = Instance.new("Part")
	anchor.Name = "LabelAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(
		scene.Origin.Position
			+ Vector3.new(0, topHeight + HatchRevealConfig.LabelGapStuds + gui.Size.Y.Scale / 2, 0)
	)
	anchor.Parent = scene.Folder
	gui.Adornee = anchor
	gui.MaxDistance = HatchRevealConfig.LabelMaxDistance

	local title = findLabel(gui, "Title")
	if title then
		title.Text = PetModifier.Name(hatch.PetKey, hatch.Modifier)
	end
	local detail = findLabel(gui, "Detail")
	if detail then
		detail.Text = `${NumberFormat.Rate(PetModifier.Rate(hatch.PetKey, hatch.Modifier))}/s`
	end
	local newLabel = findLabel(gui, "New")
	if newLabel then
		newLabel.Visible = hatch.IsNew
	end
	local sizeLabel = findLabel(gui, "Size")
	if sizeLabel then
		local isSized = PetSize.IsShown(hatch.Size)
		sizeLabel.Visible = isSized
		if isSized then
			local size = PetSize.Get(hatch.Size)
			sizeLabel.Text = size.DisplayName
			Typography.ApplyTextStyle(sizeLabel, size.TextStyle)
		end
	end
	local modifierLabel = findLabel(gui, "Modifier")
	if modifierLabel then
		local modifier = PetModifier.Get(hatch.Modifier)
		modifierLabel.Visible = modifier ~= nil
		if modifier then
			modifierLabel.Text = modifier.DisplayName
			PetModifier.PaintLabel(modifierLabel, hatch.Modifier)
		end
	end
	local rarityLabel = findLabel(gui, "Rarity")
	local rarity = RarityConfig.Rarities[hatch.Rarity]
	if rarityLabel and rarity then
		rarityLabel.Text = rarity.DisplayName
		local gradient = rarityLabel:FindFirstChildWhichIsA("UIGradient")
		if gradient then
			gradient.Color = RarityRibbon.Colors(hatch.Rarity)
			gradient.Rotation = if rarity.RainbowLabel then 0 else 90
		end
		local stroke = rarityLabel:FindFirstChildWhichIsA("UIStroke")
		if stroke then
			stroke.Color = rarity.Color:Lerp(Color3.new(0, 0, 0), RarityConfig.RibbonDarken)
		end
	end
	gui.Parent = anchor
end

function Scene.SizePet(shown: Types.ShownPet, amount: number)
	local clamped = math.max(amount, 0.05)
	shown.Model:ScaleTo(shown.Scale * clamped)
	shown.Model:PivotTo(shown.Facing + Vector3.new(0, shown.Lift * clamped, 0))
end

function Scene.ShowPet(scene: Types.Scene, hatch: Types.Hatch): Types.ShownPet?
	local pet = PetConfig.Pets[hatch.PetKey]
	local asset = if pet then AssetRegistry.get(pet.ModelKey) else nil
	if not asset then
		return nil
	end
	if not asset:IsA("Model") then
		asset:Destroy()
		return nil
	end
	local model = asset :: Model
	PetModifier.Tint(model, hatch.Modifier)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	local position = scene.Origin.Position
	local camera = workspace.CurrentCamera
	local toward = if camera then camera.CFrame.Position - position else scene.Origin.LookVector
	local flat = Vector3.new(toward.X, 0, toward.Z)
	local facing = if flat.Magnitude > 0.1 then CFrame.lookAt(position, position + flat) else scene.Origin
	local scale = model:GetScale() * PetSize.Scale(hatch.Size)
	model:ScaleTo(scale)
	model:PivotTo(facing)
	local box, size = model:GetBoundingBox()
	local bottom = box.Position.Y - size.Y / 2
	addLabel(scene, hatch, size.Y)
	model.Parent = scene.Folder
	local shown: Types.ShownPet =
		{ Model = model, Scale = scale, Facing = facing, Lift = position.Y - bottom }
	Scene.SizePet(shown, 0)
	return shown
end

function Scene.Destroy(scene: Types.Scene)
	scene.Model:Destroy()
	scene.Folder:Destroy()
end

return Scene
