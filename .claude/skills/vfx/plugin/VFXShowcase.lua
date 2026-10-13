--!strict

local RunService = game:GetService("RunService")
if not RunService:IsEdit() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local showcaseName = "VFXShowcase"
local white = Color3.new(1, 1, 1)

local toolbar = plugin:CreateToolbar("VFX Showcase")
local button = toolbar:CreateButton(
	"Loop VFX",
	"Replays every effect on the Workspace.VFXShowcase stands. Toggle off and on to reload templates and configs.",
	"rbxasset://textures/StudioToolbox/AssetPreview/play.png"
)
button.ClickableWhenViewportHidden = true

local isOn = plugin:GetSetting("IsOn") ~= false
local generation = 0
local spawned: { [Instance]: true } = {}

local function fresh(module: Instance?): any
	if not module or not module:IsA("ModuleScript") then
		return nil
	end
	local copy = module:Clone()
	copy.Archivable = false
	copy.Parent = module.Parent
	local ok, result = pcall(require, copy)
	copy:Destroy()
	if not ok then
		warn(`[VFXShowcase] {module.Name}: {result}`)
		return nil
	end
	return result
end

local function track(instance: Instance, seconds: number?)
	instance.Archivable = false
	spawned[instance] = true
	if seconds then
		task.delay(seconds, function()
			spawned[instance] = nil
			instance:Destroy()
		end)
	end
end

local function clearSpawned()
	for instance in spawned do
		instance:Destroy()
	end
	table.clear(spawned)
end

local function scaleSequence(sequence: NumberSequence, scale: number): NumberSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * scale, keypoint.Envelope * scale)
		)
	end
	return NumberSequence.new(keypoints)
end

type Context = {
	VFXEmit: any,
	Templates: Instance,
	ChopStyle: any,
	ChopEffect: any,
	HotStreak: any,
	Aura: any,
}

local function qualityColor(context: Context, quality: number): Color3
	local style = context.ChopStyle
	if not style then
		return white
	end
	return (style.Qualities[quality] or style.Fallback).Color
end

local function prepareEmitter(context: Context, emitter: ParticleEmitter, stand: Instance, scale: number)
	local quality = stand:GetAttribute("Quality")
	local color = stand:GetAttribute("Color")
	if typeof(color) == "Color3" then
		emitter.Color = ColorSequence.new(color)
	elseif type(quality) == "number" then
		local minQuality = emitter:GetAttribute("MinQuality")
		if type(minQuality) == "number" and quality < minQuality then
			emitter:Destroy()
			return
		end
		local rockColor = stand:GetAttribute("RockColor")
		local rock = if typeof(rockColor) == "Color3" then rockColor else Color3.fromRGB(128, 128, 128)
		local lighten = if context.ChopEffect then context.ChopEffect.DustLightenAmount else 0.35
		local kind = emitter:GetAttribute("Tint")
		if kind == "Quality" then
			emitter.Color = ColorSequence.new(qualityColor(context, quality))
		elseif kind == "QualityHot" then
			local hot = qualityColor(context, quality)
			emitter.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, white),
				ColorSequenceKeypoint.new(0.35, hot),
				ColorSequenceKeypoint.new(1, hot),
			})
		elseif kind == "Rock" then
			emitter.Color = ColorSequence.new(rock)
		elseif kind == "Dust" then
			emitter.Color = ColorSequence.new(rock:Lerp(white, lighten))
		end
	end
	local countScale = stand:GetAttribute("CountScale")
	local count = emitter:GetAttribute("EmitCount")
	if type(countScale) == "number" and type(count) == "number" and count > 1 then
		emitter:SetAttribute("EmitCount", math.max(1, math.floor(count * countScale + 0.5)))
	end
	if scale ~= 1 then
		emitter.Size = scaleSequence(emitter.Size, scale)
		emitter.Speed = NumberRange.new(emitter.Speed.Min * scale, emitter.Speed.Max * scale)
		emitter.Acceleration *= scale
	end
end

local function anchorOf(stand: Instance): BasePart?
	local anchor = stand:FindFirstChild("EffectAnchor")
	return if anchor and anchor:IsA("BasePart") then anchor else nil
end

local function playModel(context: Context, stand: Instance, key: string)
	local template = context.Templates:FindFirstChild(key, true)
	local anchor = anchorOf(stand)
	if not template or not template:IsA("Model") or not anchor then
		return
	end
	local scaleAttribute = stand:GetAttribute("Scale")
	local scale = if type(scaleAttribute) == "number" then scaleAttribute else 1
	local model = template:Clone()
	local root = model.PrimaryPart
	local origin = if root then root.CFrame else model:GetPivot()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			prepareEmitter(context, descendant, stand, scale)
		elseif scale == 1 then
			continue
		elseif descendant:IsA("Attachment") then
			descendant.Position *= scale
		elseif descendant:IsA("PointLight") then
			descendant.Range *= scale
		elseif descendant:IsA("BasePart") and descendant ~= root then
			local offset = origin:ToObjectSpace(descendant.CFrame)
			descendant.Size *= scale
			descendant.CFrame = origin * (offset.Rotation + offset.Position * scale)
		end
	end
	model:PivotTo(anchor.CFrame)
	track(model, 15)
	model.Parent = stand
	context.VFXEmit.emit(model, {
		onDone = function()
			spawned[model] = nil
			model:Destroy()
		end,
	})
end

local function playAttachment(context: Context, stand: Instance, key: string)
	local template = context.Templates:FindFirstChild(key, true)
	local anchor = anchorOf(stand)
	if not template or not template:IsA("Attachment") or not anchor then
		return
	end
	local attachment = template:Clone()
	for _, descendant in attachment:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			prepareEmitter(context, descendant, stand, 1)
		end
	end
	track(attachment, 6)
	attachment.Parent = anchor
	for _, descendant in attachment:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			local count = descendant:GetAttribute("EmitCount")
			descendant:Emit(if type(count) == "number" then count else 20)
		end
	end
end

local function applyHeadFire(context: Context, stand: Instance)
	local config = context.HotStreak
	local tier = stand:GetAttribute("Tier")
	local dummy = stand:FindFirstChild("Dummy")
	local head = if dummy then dummy:FindFirstChild("Head") else nil
	local template = context.Templates:FindFirstChild(if config then config.FireAssetKey else "VFX_HotStreak", true)
	if not config or type(tier) ~= "number" or not head or not template then
		return
	end
	local definition = config.Tiers[tier]
	local source = template:FindFirstChild(config.FireAttachmentName, true)
	if not definition or not source or not source:IsA("Attachment") then
		return
	end
	local old = head:FindFirstChild(config.FireAttachmentName)
	if old then
		old:Destroy()
	end
	local attachment = source:Clone()
	local scale = definition.FireScale
	for _, descendant in attachment:GetDescendants() do
		if not descendant:IsA("ParticleEmitter") then
			continue
		end
		descendant.Size = scaleSequence(descendant.Size, scale)
		descendant.Speed = NumberRange.new(descendant.Speed.Min * scale, descendant.Speed.Max * scale)
		descendant.Rate *= scale
		if descendant.Name == config.FlameEmitter then
			descendant.Color = ColorSequence.new(definition.Main)
		elseif descendant.Name == config.FlameBackEmitter then
			descendant.Color = ColorSequence.new(definition.Dark)
		elseif descendant.Name == config.EmbersEmitter then
			descendant.Color = ColorSequence.new(definition.Light)
		end
	end
	attachment.Position = Vector3.new(
		attachment.Position.X,
		config.FireBaseHeight + config.FireHeightPerScale * scale,
		attachment.Position.Z
	)
	track(attachment)
	attachment.Parent = head
end

local function setHidden(model: Instance, hidden: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function wearAura(context: Context, source: Instance, target: BasePart, spinners: { any })
	local copies = {}
	for _, child in source:GetChildren() do
		if child:IsA("Attachment") then
			local copy = child:Clone()
			copy.Parent = target
			copies[child] = copy
			local speed = child:GetAttribute(if context.Aura then context.Aura.SpinAttribute else "SpinDegreesPerSecond")
			if type(speed) == "number" and speed ~= 0 then
				table.insert(spinners, { Attachment = copy, Base = copy.CFrame, Speed = speed, Angle = 0 })
			end
		end
	end
	for _, child in source:GetChildren() do
		if child:IsA("Beam") or child:IsA("Trail") then
			local copy = child:Clone()
			copy.Attachment0 = if child.Attachment0 then copies[child.Attachment0] else nil
			copy.Attachment1 = if child.Attachment1 then copies[child.Attachment1] else nil
			copy.Parent = target
		elseif child:IsA("ParticleEmitter") or child:IsA("PointLight") then
			child:Clone().Parent = target
		end
	end
end

local function applyAura(context: Context, stand: Instance, myGeneration: number)
	local config = context.Aura
	local key = stand:GetAttribute("Effect")
	local dummy = stand:FindFirstChild("Dummy")
	local template = if type(key) == "string" then context.Templates:FindFirstChild(key, true) else nil
	if not config or not dummy or not dummy:IsA("Model") or not template then
		return
	end
	local walker = dummy:Clone()
	walker.Name = "AuraWalker"
	for _, descendant in walker:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	walker.Parent = stand
	track(walker)
	setHidden(dummy, true)
	local spinners = {}
	local limbSource = template:FindFirstChild(config.LimbTemplate)
	if limbSource then
		for _, partName in config.LimbParts do
			local part = walker:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				wearAura(context, limbSource, part, spinners)
			end
		end
	end
	local bodySource = template:FindFirstChild(config.BodyTemplate)
	local body = walker:FindFirstChild(config.BodyPart)
	if bodySource and body and body:IsA("BasePart") then
		wearAura(context, bodySource, body, spinners)
	end
	local origin = dummy:GetPivot()
	local distance = stand:GetAttribute("WalkStuds")
	local studs = if type(distance) == "number" then distance else 8
	local started = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if generation ~= myGeneration or not walker.Parent then
			connection:Disconnect()
			if not stand:FindFirstChild("AuraWalker") then
				setHidden(dummy, false)
			end
			return
		end
		local t = os.clock() - started
		local direction = if math.cos(t * 1.2) >= 0 then 0 else math.pi
		walker:PivotTo(origin * CFrame.new(math.sin(t * 1.2) * studs, 0, 0) * CFrame.Angles(0, direction + math.pi / 2, 0))
		for _, spinner in spinners do
			spinner.Angle = (spinner.Angle + spinner.Speed * dt) % 360
			spinner.Attachment.CFrame = CFrame.Angles(0, math.rad(spinner.Angle), 0) * spinner.Base
		end
	end)
end

local function playStand(context: Context, stand: Instance)
	local mode = stand:GetAttribute("Mode")
	local key = stand:GetAttribute("Effect")
	if mode == "HeadFire" or mode == "Aura" then
		return
	end
	if type(key) ~= "string" then
		return
	end
	if mode == "Attachment" then
		playAttachment(context, stand, key)
		return
	end
	playModel(context, stand, key)
	local nextKey = stand:GetAttribute("Then")
	local nextDelay = stand:GetAttribute("ThenDelay")
	if type(nextKey) == "string" then
		local myGeneration = generation
		task.delay(if type(nextDelay) == "number" then nextDelay else 0, function()
			if generation == myGeneration and stand.Parent then
				playModel(context, stand, nextKey)
			end
		end)
	end
end

local function start()
	generation += 1
	local myGeneration = generation
	clearSpawned()
	local showcase = workspace:FindFirstChild(showcaseName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local templates = if assets then assets:FindFirstChild("VFX") else nil
	local emitModule = ReplicatedStorage:FindFirstChild("VFXEmit")
	if not showcase or not templates or not emitModule or not emitModule:IsA("ModuleScript") then
		return
	end
	local config = ReplicatedStorage:FindFirstChild("Config")
	local context: Context = {
		VFXEmit = fresh(emitModule),
		Templates = templates,
		ChopStyle = fresh(config and config:FindFirstChild("ChopStyleConfig")),
		ChopEffect = fresh(config and config:FindFirstChild("ChopEffectConfig")),
		HotStreak = fresh(config and config:FindFirstChild("HotStreakConfig")),
		Aura = fresh(config and config:FindFirstChild("AuraConfig")),
	}
	if not context.VFXEmit then
		warn("[VFXShowcase] Could not load ReplicatedStorage.VFXEmit")
		return
	end
	for _, stand in showcase:GetDescendants() do
		if stand:GetAttribute("Mode") == "HeadFire" then
			applyHeadFire(context, stand)
			continue
		end
		if stand:GetAttribute("Mode") == "Aura" then
			applyAura(context, stand, myGeneration)
			continue
		end
		if type(stand:GetAttribute("Effect")) ~= "string" then
			continue
		end
		local loopAttribute = stand:GetAttribute("Loop")
		local loop = if type(loopAttribute) == "number" then math.max(0.5, loopAttribute) else 3
		task.spawn(function()
			task.wait(math.random() * 0.5)
			while generation == myGeneration and stand.Parent do
				local ok, problem = pcall(playStand, context, stand)
				if not ok then
					warn(`[VFXShowcase] {stand.Name}: {problem}`)
				end
				task.wait(loop)
			end
		end)
	end
end

local function stop()
	generation += 1
	clearSpawned()
end

local function setOn(value: boolean)
	isOn = value
	plugin:SetSetting("IsOn", value)
	button:SetActive(value)
	if value then
		start()
	else
		stop()
	end
end

button.Click:Connect(function()
	setOn(not isOn)
end)

plugin.Unloading:Connect(stop)

workspace.ChildAdded:Connect(function(child)
	if isOn and child.Name == showcaseName then
		task.wait(0.5)
		start()
	end
end)

button:SetActive(isOn)
task.delay(2, function()
	if isOn then
		start()
	end
end)
