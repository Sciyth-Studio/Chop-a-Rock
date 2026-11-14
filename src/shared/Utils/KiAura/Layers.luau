--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KiAuraConfig = require(ReplicatedStorage.Config.KiAuraConfig)
local Types = require(script.Parent.Types)

type Spec = {
	Name: string,
	Role: Types.Role,
	Texture: string,
	Size: NumberSequence,
	Rate: number,
	Lifetime: NumberRange,
	Transparency: NumberSequence,
	LightEmission: number,
	Brightness: number,
	Burst: number,
	Speed: NumberRange?,
	Acceleration: Vector3?,
	Spread: Vector2?,
	Orientation: Enum.ParticleOrientation?,
	Squash: NumberSequence?,
	ZOffset: number?,
	Rotation: NumberRange?,
	RotSpeed: NumberRange?,
	Drag: number?,
	IsLocked: boolean?,
	IsFlat: boolean?,
	IsFlipbook: boolean?,
	FillsVolume: boolean?,
	Lifts: boolean?,
	Sways: boolean?,
}

local Layers = {}

local easeOut = { 0, 0.04, 0.12, 0.24, 0.4, 0.55, 0.68, 0.78, 0.86, 0.92, 0.96, 1 }

local function sequence(values: { number }, scale: number): NumberSequence
	if #values == 1 then
		return NumberSequence.new(values[1] * scale)
	end
	local keys = {}
	for i, value in values do
		keys[i] = NumberSequenceKeypoint.new((i - 1) / (#values - 1), value * scale)
	end
	return NumberSequence.new(keys)
end

local function growth(from: number, to: number, scale: number): NumberSequence
	local keys = {}
	for i, f in easeOut do
		keys[i] = NumberSequenceKeypoint.new((i - 1) / (#easeOut - 1), (from + (to - from) * f) * scale)
	end
	return NumberSequence.new(keys)
end

local function attachment(parent: BasePart, name: string, position: Vector3, rig: Types.Rig): Attachment
	local point = Instance.new("Attachment")
	point.Name = name
	point.Position = position
	point.Parent = parent
	table.insert(rig.Instances, point)
	return point
end

local function emitter(parent: Instance, spec: Spec, rig: Types.Rig): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = spec.Name
	e.Texture = spec.Texture
	e.Size = spec.Size
	e.Rate = spec.Rate
	e.Lifetime = spec.Lifetime
	e.Transparency = spec.Transparency
	e.LightEmission = spec.LightEmission
	e.LightInfluence = 0
	e.Brightness = spec.Brightness
	e.Speed = spec.Speed or NumberRange.new(0)
	e.Acceleration = spec.Acceleration or Vector3.zero
	e.SpreadAngle = spec.Spread or Vector2.zero
	e.Orientation = spec.Orientation or Enum.ParticleOrientation.FacingCamera
	e.Squash = spec.Squash or NumberSequence.new(0)
	e.ZOffset = spec.ZOffset or 0
	e.Rotation = spec.Rotation or NumberRange.new(0, 360)
	e.RotSpeed = spec.RotSpeed or NumberRange.new(0)
	e.Drag = spec.Drag or 0
	e.LockedToPart = spec.IsLocked == true
	e.EmissionDirection = Enum.NormalId.Top
	if spec.IsFlat then
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		e.Speed = NumberRange.new(0.001)
		e.LockedToPart = true
	end
	if spec.IsFlipbook then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	end
	if spec.FillsVolume then
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end
	e.Enabled = false
	e.Parent = parent
	if parent:IsA("BasePart") then
		table.insert(rig.Instances, e)
	end
	table.insert(rig.Emitters, {
		Emitter = e,
		Role = spec.Role,
		Rate = spec.Rate,
		Size = spec.Size,
		Speed = e.Speed,
		Acceleration = e.Acceleration,
		Burst = spec.Burst,
		Lifts = spec.Lifts == true,
		Sways = spec.Sways == true,
	})
	return e
end

local function addGlow(character: Model, rig: Types.Rig)
	for _, partName in KiAuraConfig.GlowParts do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			local size = math.max(part.Size.X, part.Size.Y, part.Size.Z) * 0.7
			emitter(part, {
				Name = "KiGlow",
				Role = "Glow",
				Texture = KiAuraConfig.Textures.Glow,
				Size = sequence({ 0.8, 1, 0.9 }, size),
				Rate = 7,
				Lifetime = NumberRange.new(0.3, 0.45),
				Transparency = sequence({ 1, 0.75, 1 }, 1),
				LightEmission = 1,
				Brightness = 1.2,
				ZOffset = 0.4,
				IsLocked = true,
				FillsVolume = true,
				Burst = 2,
			}, rig)
		end
	end
end

local function addFlames(core: Attachment, k: number, rig: Types.Rig)
	local textures = KiAuraConfig.Textures
	emitter(core, {
		Name = "KiCore",
		Role = "Glow",
		Texture = textures.CoreGlow,
		Size = sequence({ 2.6, 3, 2.8 }, k),
		Rate = 4,
		Lifetime = NumberRange.new(0.5),
		Transparency = sequence({ 1, 0.72, 1 }, 1),
		LightEmission = 1,
		Brightness = 1.5,
		ZOffset = -1.5,
		IsLocked = true,
		Burst = 3,
	}, rig)
	emitter(core, {
		Name = "KiFlame",
		Role = "Wisp",
		Texture = textures.Flame,
		Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
		Size = sequence({ 4.5, 5.2, 5.6 }, k),
		Squash = NumberSequence.new(0),
		Speed = NumberRange.new(3 * k, 5 * k),
		Acceleration = Vector3.new(0, 10 * k, 0),
		Rotation = NumberRange.new(-6, 6),
		Rate = 12,
		Lifetime = NumberRange.new(0.25, 0.35),
		Transparency = sequence({ 1, 0.35, 0.5, 1 }, 1),
		LightEmission = 1,
		Brightness = 2.4,
		Burst = 6,
		Lifts = true,
		Sways = true,
	}, rig)
	emitter(core, {
		Name = "KiFlameEdge",
		Role = "Edge",
		Texture = textures.Flame,
		Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
		Size = sequence({ 4.9, 5.7, 6.1 }, k),
		Squash = NumberSequence.new(0),
		Speed = NumberRange.new(3 * k, 5 * k),
		Acceleration = Vector3.new(0, 10 * k, 0),
		Rotation = NumberRange.new(-6, 6),
		Rate = 6,
		Lifetime = NumberRange.new(0.3, 0.4),
		Transparency = sequence({ 1, 0.55, 0.8, 1 }, 1),
		LightEmission = 0.05,
		Brightness = 1.2,
		ZOffset = -0.8,
		Burst = 3,
		Lifts = true,
		Sways = true,
	}, rig)
end

local function addWisps(points: { Attachment }, speeds: { NumberRange }, k: number, rig: Types.Rig)
	local flame = KiAuraConfig.Textures.Flame
	for i, point in points do
		local speed = speeds[i]
		emitter(point, {
			Name = "KiWisp",
			Role = "Wisp",
			Texture = flame,
			Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
			Size = sequence({ 1.3, 1.8, 1.6, 0.3 }, k),
			Squash = sequence({ 0.5, 1, 0.8 }, 1),
			Speed = speed,
			Acceleration = Vector3.new(0, 10 * k, 0),
			Spread = Vector2.new(9, 9),
			Rate = 12,
			Lifetime = NumberRange.new(0.35, 0.5),
			Rotation = NumberRange.new(-10, 10),
			Transparency = sequence({ 0.5, 0.1, 0.35, 1 }, 1),
			LightEmission = 1,
			Brightness = 2.4,
			Burst = 6,
			Lifts = true,
			Sways = true,
		}, rig)
		emitter(point, {
			Name = "KiWispEdge",
			Role = "Edge",
			Texture = flame,
			Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
			Size = sequence({ 1.6, 2.2, 1.9, 0.3 }, k),
			Squash = sequence({ 0.5, 1, 0.8 }, 1),
			Speed = speed,
			Acceleration = Vector3.new(0, 10 * k, 0),
			Spread = Vector2.new(9, 9),
			Rate = 5,
			Lifetime = NumberRange.new(0.38, 0.52),
			Rotation = NumberRange.new(-10, 10),
			Transparency = sequence({ 0.6, 0.35, 0.6, 1 }, 1),
			LightEmission = 0.08,
			Brightness = 1.1,
			ZOffset = -0.5,
			Burst = 2,
			Lifts = true,
			Sways = true,
		}, rig)
	end
end

local function addGround(ground: Attachment, k: number, rig: Types.Rig)
	local textures = KiAuraConfig.Textures
	rig.Shockwave = emitter(ground, {
		Name = "KiShockwave",
		Role = "Ring",
		Texture = textures.Ring,
		IsFlat = true,
		Size = growth(0.8, 6.5, k),
		Rate = 0,
		Lifetime = NumberRange.new(0.75),
		Transparency = sequence({ 0.35, 0.6, 1 }, 1),
		RotSpeed = NumberRange.new(40),
		LightEmission = 1,
		Brightness = 2,
		Burst = 1,
	}, rig)
	emitter(ground, {
		Name = "KiFloorGlow",
		Role = "Ring",
		Texture = textures.Glow,
		IsFlat = true,
		Size = sequence({ 3.6 }, k),
		Rate = 2.5,
		Lifetime = NumberRange.new(0.8),
		Transparency = sequence({ 1, 0.78, 1 }, 1),
		LightEmission = 1,
		Brightness = 1.4,
		Burst = 1,
	}, rig)
end

local function addSparks(root: BasePart, k: number, rig: Types.Rig)
	local textures = KiAuraConfig.Textures
	emitter(root, {
		Name = "KiSparks",
		Role = "Spark",
		Texture = textures.Spark,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Squash = NumberSequence.new(-2.5),
		Size = sequence({ 0.1, 0.06, 0 }, k),
		Speed = NumberRange.new(4 * k, 9 * k),
		Spread = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, 5 * k, 0),
		Drag = 1.5,
		Rate = 14,
		Lifetime = NumberRange.new(0.5, 0.9),
		Transparency = sequence({ 0, 0.2, 1 }, 1),
		LightEmission = 1,
		Brightness = 4,
		FillsVolume = true,
		Burst = 26,
	}, rig)
	emitter(root, {
		Name = "KiCrackle",
		Role = "Spark",
		Texture = textures.Crackle,
		IsFlipbook = true,
		Size = sequence({ 0.7 }, k),
		Rate = 3,
		Lifetime = NumberRange.new(0.2, 0.25),
		Transparency = NumberSequence.new(0),
		LightEmission = 1,
		Brightness = 3,
		FillsVolume = true,
		Burst = 4,
	}, rig)
end

function Layers.Build(character: Model, root: BasePart, humanoid: Humanoid): Types.Rig
	local k = root.Size.Y / 2
	local floor = -(humanoid.HipHeight + root.Size.Y / 2)
	local shoulder = 1.4 * k
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local y = root.CFrame:PointToObjectSpace(head.Position).Y
		shoulder = y - head.Size.Y / 2 - 0.1 * k
	end
	local light = Instance.new("PointLight")
	light.Name = "KiLight"
	light.Range = KiAuraConfig.LightRange * k
	light.Brightness = 0
	light.Shadows = false
	light.Enabled = false
	local rig: Types.Rig = { Emitters = {}, Light = light, Shockwave = nil, Instances = {} }
	light.Parent = attachment(root, "KiLight", Vector3.new(0, 0.5 * k, 0), rig)
	addGlow(character, rig)
	addFlames(attachment(root, "KiCore", Vector3.new(0, 0.4 * k, 0), rig), k, rig)
	local feet = NumberRange.new(13 * k, 17 * k)
	local shoulders = NumberRange.new(8 * k, 11 * k)
	addWisps({
		attachment(root, "KiWispLeftFoot", Vector3.new(-1 * k, floor + 0.3 * k, 0), rig),
		attachment(root, "KiWispRightFoot", Vector3.new(1 * k, floor + 0.3 * k, 0), rig),
		attachment(root, "KiWispLeftShoulder", Vector3.new(-1 * k, shoulder, 0), rig),
		attachment(root, "KiWispRightShoulder", Vector3.new(1 * k, shoulder, 0), rig),
	}, { feet, feet, shoulders, shoulders }, k, rig)
	addGround(attachment(root, "KiGround", Vector3.new(0, floor + 0.05, 0), rig), k, rig)
	addSparks(root, k, rig)
	return rig
end

return Layers
