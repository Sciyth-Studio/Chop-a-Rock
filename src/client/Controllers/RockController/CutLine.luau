--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopApproach = require(ReplicatedStorage.Utils.ChopApproach)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopEffectConfig = require(ReplicatedStorage.Config.ChopEffectConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)

type BeamInfo = {
	Beam: Beam,
	Width: number,
	Shape: string,
	Alpha: number,
	Start: number,
	Finish: number,
	IsFlyer: boolean,
}

export type Line = {
	Model: Model,
	Exit: Attachment,
	Hand: Attachment,
	Finale: Attachment,
	FlyTail: Attachment,
	FlyHead: Attachment,
	Beams: { BeamInfo },
	Sparks: { ParticleEmitter },
	HandBursts: { ParticleEmitter },
	FinaleBursts: { ParticleEmitter },
	Linger: number,
	From: Vector3,
	To: Vector3,
	Direction: Vector3,
	Basis: CFrame,
	Width: number,
	Draw: number,
	Hold: number,
	Fade: number,
	HoldDim: number,
	Retract: number,
	FlySeconds: number,
	FlyDistance: number,
	FlyLength: number,
	FlyLift: number,
	SparkStep: number,
	HasFinale: boolean,
}

local CutLine = {}

local template: Model? = nil
local isMissing = false

local function getTemplate(): Model?
	if template or isMissing then
		return template
	end
	local asset = AssetRegistry.get(ChopEffectConfig.CutLineKey)
	if asset:IsA("Model") then
		template = asset
		return asset
	end
	asset:Destroy()
	isMissing = true
	return nil
end

local function number(instance: Instance, name: string, fallback: number): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else fallback
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

local function attachment(root: Instance, name: string): Attachment
	local found = root:FindFirstChild(name)
	if found and found:IsA("Attachment") then
		return found
	end
	local created = Instance.new("Attachment")
	created.Name = name
	created.Parent = root
	return created
end

local function reveal(shown: number, first: number, last: number): NumberSequence
	if last - first < 1e-3 then
		return NumberSequence.new(1)
	end
	local edge = ChopEffectConfig.CutRevealEdge
	local times: { number } = {}
	local values: { number } = {}
	local function add(time: number, value: number)
		local previous = times[#times]
		if previous and time <= previous then
			time = previous + 1e-4
		end
		if time > 1 then
			return
		end
		table.insert(times, time)
		table.insert(values, value)
	end
	if first > 0 then
		add(0, 1)
		add(first, 1)
		add(math.min(first + edge, last), shown)
	else
		add(0, shown)
	end
	if last < 1 then
		add(math.max(last - edge, times[#times]), shown)
		add(last, 1)
		add(1, 1)
	else
		add(1, shown)
	end
	if times[#times] < 1 then
		add(1, values[#values])
	end
	local keypoints = {}
	for index, time in times do
		table.insert(keypoints, NumberSequenceKeypoint.new(time, values[index]))
	end
	return NumberSequence.new(keypoints)
end

local function emitAll(emitters: { ParticleEmitter })
	for _, emitter in emitters do
		emitter:Emit(number(emitter, "EmitCount", 1))
	end
end

function CutLine.Spawn(
	part: BasePart,
	quality: number,
	isFull: boolean,
	aura: Color3,
	start: Vector3?,
	toward: Vector3?,
	power: number?
): Line?
	local source = getTemplate()
	if not source then
		return nil
	end
	local model = source:Clone()
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return nil
	end
	local strength = power or 1
	local stage = math.floor(strength)
	local isPerfect = quality >= ChopQuality.Perfect
	local size = part.Size
	local facing = toward or ChopApproach.Rotation(part).LookVector
	local flat = Vector3.new(facing.X, 0, facing.Z)
	local direction = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zAxis
	local depth = math.max(size.X, size.Z)
	local ground = Vector3.new(
		part.Position.X,
		part.Position.Y - size.Y / 2 + ChopEffectConfig.CutGroundLift,
		part.Position.Z
	)
	local from = if start
		then ground + direction * (start - ground):Dot(direction)
		else ground + direction * depth / 2 * ChopEffectConfig.NickEdgeFraction
	local to: Vector3
	if isFull then
		local overshoot = if isPerfect
			then ChopEffectConfig.CutPerfectOvershoot
			else ChopEffectConfig.CutOvershoot
		to = ground - direction * depth / 2 * overshoot
	else
		to = from - direction * depth * ChopEffectConfig.NickLengthFraction
	end
	local scale = math.max(ChopEffectConfig.MinScale, size.X / ChopConfig.ReferenceRockSize)
	local width = scale
		* (if isPerfect then number(model, "PerfectWidthScale", 1) else 1)
		* (if isFull then 1 else ChopEffectConfig.NickWidthScale)
		* (1 + (strength - 1) * ChopEffectConfig.CutWidthPerPower)

	for _, descendant in model:GetDescendants() do
		local minStage = descendant:GetAttribute(ChopEffectConfig.CutStageAttribute)
		local minQuality = descendant:GetAttribute(ChopEffectConfig.MinQualityAttribute)
		local only = descendant:GetAttribute(ChopEffectConfig.CutOnlyAttribute)
		if
			(type(minStage) == "number" and stage < minStage)
			or (type(minQuality) == "number" and quality < minQuality)
			or (only == "Full" and not isFull)
			or (only == "Nick" and isFull)
		then
			descendant:Destroy()
		end
	end

	local beams: { BeamInfo } = {}
	local sparks: { ParticleEmitter } = {}
	local handBursts: { ParticleEmitter } = {}
	local finaleBursts: { ParticleEmitter } = {}
	local linger = 0
	for _, descendant in model:GetDescendants() do
		local tint = descendant:GetAttribute(ChopEffectConfig.TintAttribute)
		local color = if tint == "Aura" then aura elseif tint == "Rock" then part.Color else nil
		if descendant:IsA("Beam") then
			if color then
				descendant.Color = ColorSequence.new(color)
			end
			descendant.TextureSpeed = 0
			local first = descendant.Attachment0
			local second = descendant.Attachment1
			local shape = if second and second.Name == "Mid"
				then "Upper"
				elseif first and first.Name == "Mid" then "Lower"
				else "Whole"
			table.insert(beams, {
				Beam = descendant,
				Width = number(descendant, "Width", 1),
				Shape = shape,
				Alpha = number(descendant, "Alpha", 0),
				Start = if shape == "Lower" then 0.5 else 0,
				Finish = if shape == "Upper" then 0.5 else 1,
				IsFlyer = first ~= nil and first.Name == "FlyTail",
			})
		elseif descendant:IsA("ParticleEmitter") then
			if color then
				descendant.Color = ColorSequence.new(color)
			end
			linger = math.max(linger, descendant.Lifetime.Max + number(descendant, "EmitDelay", 0))
			descendant.Size = scaleSequence(descendant.Size, scale)
			descendant.Speed = NumberRange.new(descendant.Speed.Min * scale, descendant.Speed.Max * scale)
			descendant.Acceleration *= scale
			local carrier = if descendant.Parent then descendant.Parent.Name else ""
			if carrier == "Hand" then
				table.insert(handBursts, descendant)
			elseif carrier == "Finale" then
				table.insert(finaleBursts, descendant)
			else
				table.insert(sparks, descendant)
			end
		end
	end

	local basis = CFrame.fromMatrix(Vector3.zero, -direction, direction:Cross(Vector3.yAxis))
	model:PivotTo(CFrame.new(from))
	attachment(root, "Top").WorldCFrame = basis + from
	attachment(root, "Mid").WorldCFrame = basis + from:Lerp(to, 0.5)
	attachment(root, "Bottom").WorldCFrame = basis + to
	local drop = Vector3.new(0, ChopEffectConfig.CutCrackDrop, 0)
	attachment(root, "CrackTop").WorldCFrame = basis + (from - drop)
	attachment(root, "CrackBottom").WorldCFrame = basis + (to - drop)
	local hand = attachment(root, "Hand")
	hand.WorldPosition = from
	local finale = attachment(root, "Finale")
	finale.WorldPosition = to
	model.Parent = workspace
	local length = (to - from).Magnitude
	local line: Line = {
		Model = model,
		Exit = attachment(root, "Exit"),
		Hand = hand,
		Finale = finale,
		FlyTail = attachment(root, "FlyTail"),
		FlyHead = attachment(root, "FlyHead"),
		Beams = beams,
		Sparks = sparks,
		HandBursts = handBursts,
		FinaleBursts = finaleBursts,
		Linger = linger,
		From = from,
		To = to,
		Direction = -direction,
		Basis = basis,
		Width = width,
		Draw = number(model, "DrawSeconds", 0.06),
		Hold = if isFull
			then ChopEffectConfig.CutHoldSeconds + (strength - 1) * ChopEffectConfig.CutHoldPerPower
			else number(model, "HoldSeconds", 0.05),
		Fade = if isFull then ChopEffectConfig.CutFadeSeconds else number(model, "FadeSeconds", 0.16),
		HoldDim = if isFull then ChopEffectConfig.CutHoldDim else 0,
		Retract = if isFull then 0 else ChopEffectConfig.CutRetractFraction,
		FlySeconds = number(model, "FlySeconds", 0.3),
		FlyDistance = length * number(model, "FlyDistanceScale", 1.5),
		FlyLength = length * number(model, "FlyLengthScale", 0.35),
		FlyLift = number(model, "FlyLift", 1.5) * scale,
		SparkStep = 0,
		HasFinale = false,
	}
	emitAll(handBursts)
	CutLine.Pose(line, 0)
	return line
end

function CutLine.Pose(line: Line, t: number)
	local drawn = math.clamp(t / line.Draw, 0, 1)
	local eased = 1 - (1 - drawn) * (1 - drawn)
	local held = math.clamp((t - line.Draw) / math.max(line.Hold, 1e-3), 0, 1)
	local faded = math.clamp((t - line.Draw - line.Hold) / line.Fade, 0, 1)
	local tail = faded * faded * line.Retract
	local loss = line.HoldDim * held + (1 - line.HoldDim) * faded * faded
	local thickness = line.Width * (1 - faded)
	local flown = math.clamp((t - line.Draw) / line.FlySeconds, 0, 1)
	local head = line.To
		+ line.Direction * line.FlyDistance * (1 - (1 - flown) ^ 2)
		+ Vector3.new(0, line.FlyLift, 0)
	line.FlyHead.WorldCFrame = line.Basis + head
	line.FlyTail.WorldCFrame = line.Basis + (head - line.Direction * line.FlyLength * (1 - flown * 0.5))
	for _, info in line.Beams do
		if info.IsFlyer then
			local width = info.Width * line.Width * (1 - flown * 0.6)
			info.Beam.Width0 = 0
			info.Beam.Width1 = width
			info.Beam.Transparency =
				NumberSequence.new(if drawn < 1 then 1 else info.Alpha + (1 - info.Alpha) * flown * flown)
			continue
		end
		local width = info.Width * thickness
		info.Beam.Width0 = if info.Shape == "Upper" then 0 else width
		info.Beam.Width1 = if info.Shape == "Lower" then 0 else width
		local span = info.Finish - info.Start
		info.Beam.Transparency = reveal(
			info.Alpha + (1 - info.Alpha) * loss,
			math.clamp((tail - info.Start) / span, 0, 1),
			math.clamp((eased - info.Start) / span, 0, 1)
		)
	end
	local steps = ChopEffectConfig.CutSparkSteps
	while line.SparkStep < steps and eased >= (line.SparkStep + 1) / steps do
		line.SparkStep += 1
		local isLast = line.SparkStep == steps
		line.Exit.WorldPosition = line.From:Lerp(line.To, line.SparkStep / steps)
		for _, emitter in line.Sparks do
			local count = number(emitter, "EmitCount", 8)
			emitter:Emit(
				if isLast then count else math.max(1, math.floor(count * ChopEffectConfig.CutSparkTrailShare))
			)
		end
	end
	if not line.HasFinale and drawn >= 1 then
		line.HasFinale = true
		emitAll(line.FinaleBursts)
	end
end

function CutLine.Duration(line: Line): number
	return math.max(line.Draw + line.Hold + line.Fade, line.Draw + line.FlySeconds)
end

function CutLine.Play(
	part: BasePart,
	quality: number,
	isFull: boolean,
	aura: Color3,
	start: Vector3?,
	power: number?
): number
	local line = CutLine.Spawn(part, quality, isFull, aura, start, nil, power)
	if not line then
		return 0
	end
	local started = os.clock()
	local finish = CutLine.Duration(line)
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function()
		local t = os.clock() - started
		CutLine.Pose(line, math.min(t, finish))
		if t >= finish and connection then
			connection:Disconnect()
			task.delay(line.Linger, function()
				line.Model:Destroy()
			end)
		end
	end)
	return line.Draw
end

return CutLine
