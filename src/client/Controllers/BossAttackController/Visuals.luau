--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossFxConfig = require(ReplicatedStorage.Config.BossFxConfig)
local BossHazards = require(ReplicatedStorage.BossHazards)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Typography = require(ReplicatedStorage.Utils.Typography)

local Canvas = require(script.Parent.Canvas)

export type Set = {
	Folder: Folder,
	Canvas: Canvas.Canvas?,
	Arrow: PVInstance?,
	Countdown: BillboardGui?,
	Labels: { TextLabel },
	Animate: ((since: number) -> ())?,
	LandOffset: number?,
	HoldSeconds: number,
	Cleanup: (() -> ())?,
}

local Visuals = {}

local spec = BossFxConfig.Floor
local textures = BossFxConfig.Textures
local Styles = BossConfig.BigStyles

local function flatPart(
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	cframe: CFrame,
	color: Color3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function playSound(key: string)
	if key ~= "" then
		LocalSound.Play(key)
	end
end

local function setFill(item: GuiObject, transparency: number)
	if item:IsA("ImageLabel") then
		item.ImageTransparency = transparency
	else
		item.BackgroundTransparency = transparency
	end
end

local function canvasFor(set: Set, center: Vector3, half: number): Canvas.Canvas
	local canvas = Canvas.New(
		set.Folder,
		center,
		math.min(half + BossFxConfig.Canvas.MarginStuds, BossConfig.ArenaJudgeHalfStuds),
		spec.LiftStuds
	)
	set.Canvas = canvas
	return canvas
end

local function reachFrom(center: Vector3, hazard: BossHazards.Hazard): number
	local offset = Vector3.new(hazard.Origin.X - center.X, 0, hazard.Origin.Z - center.Z).Magnitude
	return offset + hazard.Reach + hazard.Size
end

local function buildSlam(set: Set, center: Vector3, radius: number)
	local canvas = canvasFor(set, center, radius)
	Canvas.Disc(
		canvas,
		canvas.Danger,
		center,
		radius,
		spec.RedColor,
		if textures.SlamRing ~= "" then 0 else spec.SlamTransparency,
		textures.SlamRing,
		spec.RedColor,
		spec.RimWidthStuds
	)
end

local function buildTailSweep(set: Set, hazard: BossHazards.Hazard, center: Vector3, boss: Model)
	local look = BossFxConfig.Hazards.TailSweep
	local rules = BossConfig.BigAttack.TailSweep
	local canvas = canvasFor(set, center, reachFrom(center, hazard))
	local origin = hazard.Origin
	local from = hazard.Angle - hazard.Span / 2
	local leniency = math.rad(rules.GapLeniencyDegrees)
	local startAngle = from + leniency
	local endAngle = from + hazard.Span - leniency
	local sweepSeconds = rules.SweepSeconds
	set.HoldSeconds = sweepSeconds
	Canvas.Fan(
		canvas,
		canvas.Danger,
		origin,
		hazard.Angle,
		hazard.Span,
		look.InnerStuds,
		hazard.Reach,
		look.ChordStuds,
		spec.RedColor,
		if textures.Fan ~= "" then 0 else spec.SlamTransparency,
		textures.Fan
	)
	if textures.Fan == "" then
		for _, angle in { from, from + hazard.Span } do
			local item = Canvas.Strip(
				canvas,
				canvas.Danger,
				origin + BossHazards.Direction(angle) * look.InnerStuds,
				origin + BossHazards.Direction(angle) * hazard.Reach,
				look.EdgeWidthStuds,
				look.EdgeColor,
				spec.RimTransparency
			)
			item.ZIndex = 2
		end
	end
	local streaks: { GuiObject } = {}
	for index = 0, look.TrailCount do
		local streak = Canvas.Strip(
			canvas,
			canvas.Overlay,
			origin,
			origin + Vector3.xAxis * hazard.Reach,
			look.TailWidthStuds,
			look.TailColor,
			1,
			textures.Tail
		)
		streak.ZIndex = look.TrailCount + 1 - index
		table.insert(streaks, streak)
	end
	local original = boss:GetPivot()
	local position = original.Position
	local baseTail = BossHazards.AngleOf(-original.LookVector)
	local turned = false
	local function face(tailAngle: number)
		if not boss.Parent then
			return
		end
		turned = true
		local direction = BossHazards.Direction(tailAngle)
		boss:PivotTo(CFrame.lookAt(position, position - direction))
	end
	set.Cleanup = function()
		if turned and boss.Parent then
			boss:PivotTo(original)
		end
	end
	local played = false
	local settled = false
	set.Animate = function(since: number)
		if not played and since >= -look.SoundLeadSeconds then
			played = true
			playSound(look.Sound)
		end
		if since < -look.WindupSeconds then
			return
		end
		if since < 0 then
			local alpha = (since + look.WindupSeconds) / look.WindupSeconds
			local eased = alpha * alpha * (3 - 2 * alpha)
			face(baseTail + BossHazards.AngleGap(startAngle, baseTail) * eased)
			return
		end
		if since <= sweepSeconds then
			local line = startAngle + (endAngle - startAngle) * (since / sweepSeconds)
			face(line)
			for index, streak in streaks do
				local angle = math.max(startAngle, line - math.rad(look.TrailDegrees) * (index - 1))
				Canvas.PlaceStrip(
					canvas,
					streak,
					origin,
					origin + BossHazards.Direction(angle) * hazard.Reach,
					look.TailWidthStuds
				)
				setFill(streak, look.TailTransparency + (1 - look.TailTransparency) * (index - 1) / #streaks)
			end
			return
		end
		for _, streak in streaks do
			setFill(streak, 1)
		end
		local back = (since - sweepSeconds) / look.ReturnSeconds
		if back < 1 then
			local eased = back * back * (3 - 2 * back)
			face(endAngle + BossHazards.AngleGap(baseTail, endAngle) * eased)
		elseif not settled then
			settled = true
			if turned and boss.Parent then
				boss:PivotTo(original)
			end
		end
	end
end

type Shard = { Item: PVInstance, Base: CFrame, StartsAt: number, Started: boolean, Settled: boolean }

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function playCrack(random: Random, gain: number)
	local look = BossFxConfig.Hazards.IceSpikes
	local asset = AssetRegistry.get(look.CrackKeys[random:NextInteger(1, #look.CrackKeys)])
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	asset.Volume *= gain
	asset.PlaybackSpeed = random:NextNumber(look.CrackPitchMin, look.CrackPitchMax)
	LocalSound.PlayInstance(asset)
	task.delay(look.CrackLifetimeSeconds, function()
		asset:Destroy()
	end)
end

local function spikeTemplates(keys: { string }): { Model }
	local templates: { Model } = {}
	for _, key in keys do
		local template = AssetRegistry.get(key)
		if not template:IsA("Model") then
			template:Destroy()
			continue
		end
		for _, descendant in template:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
				descendant.CastShadow = false
			end
		end
		table.insert(templates, template)
	end
	return templates
end

local function spikePositions(hazard: BossHazards.Hazard, center: Vector3, random: Random): { Vector3 }
	local look = BossFxConfig.Hazards.IceSpikes
	local half = hazard.Reach
	local spacing = if LowGraphics.IsOn() then look.LowShardSpacingStuds else look.ShardSpacingStuds
	local clear = hazard.Size + look.ShardPocketMarginStuds
	local positions: { Vector3 } = {}
	local x = -half + spacing / 2
	while x < half do
		local z = -half + spacing / 2
		while z < half do
			local jitter = look.ShardJitterStuds
			local position = center
				+ Vector3.new(
					math.clamp(x + random:NextNumber(-jitter, jitter), -half, half),
					0,
					math.clamp(z + random:NextNumber(-jitter, jitter), -half, half)
				)
			local isClear = flatDistance(position, hazard.Origin) >= look.InnerStuds
			for _, point in hazard.Points do
				if flatDistance(position, point) < clear then
					isClear = false
				end
			end
			if isClear then
				table.insert(positions, position)
			end
			z += spacing
		end
		x += spacing
	end
	return positions
end

local function buildIceSpikes(set: Set, hazard: BossHazards.Hazard, center: Vector3)
	local look = BossFxConfig.Hazards.IceSpikes
	local spread = BossConfig.BigAttack.IceSpikes.SpreadSeconds
	local half = hazard.Reach
	local floorTop = center.Y + spec.LiftStuds
	local canvas = canvasFor(set, center, half)
	Canvas.Square(canvas, canvas.Danger, spec.RedColor, spec.RedTransparency)
	local sheet = Canvas.Square(canvas, canvas.Overlay, look.ShardColor, 1, textures.IceSheet)
	sheet.ZIndex = 1
	local pockets: { { Item: GuiObject, Transparency: number } } = {}
	local pocketFill = if textures.Pocket ~= "" then 0 else look.PocketTransparency
	local sheetFill = if textures.IceSheet ~= "" then 0 else look.SheetTransparency
	for _, point in hazard.Points do
		local pocket = Canvas.Disc(
			canvas,
			canvas.Overlay,
			point,
			hazard.Size,
			look.PocketColor,
			pocketFill,
			textures.Pocket,
			look.RimColor,
			look.RimWidthStuds
		)
		pocket.ZIndex = 2
		table.insert(pockets, { Item = pocket, Transparency = pocketFill })
	end
	local random = Random.new()
	local templates = spikeTemplates(look.ModelKeys)
	local positions = spikePositions(hazard, center, random)
	local farthest = 1
	for _, position in positions do
		farthest = math.max(farthest, flatDistance(position, hazard.Origin))
	end
	local tilt = math.rad(look.ShardTiltDegrees)
	local shards: { Shard } = {}
	for _, position in positions do
		local turn = CFrame.Angles(
			random:NextNumber(-tilt, tilt),
			random:NextNumber(0, math.pi * 2),
			random:NextNumber(-tilt, tilt)
		)
		local item: PVInstance
		local base: CFrame
		if #templates > 0 then
			local template = templates[random:NextInteger(1, #templates)]
			local copy = template:Clone()
			copy:ScaleTo(template:GetScale() * random:NextNumber(look.ShardScaleMin, look.ShardScaleMax))
			base = CFrame.new(position.X, floorTop - look.ModelEmbedStuds, position.Z) * turn
			item = copy
		else
			base = CFrame.new(position.X, floorTop + look.ShardSize.Y / 2 - look.ShardEmbedStuds, position.Z)
				* turn
			local part = flatPart("Shard", Enum.PartType.Block, look.ShardSize, base, look.ShardColor)
			part.Material = look.ShardMaterial
			part.Transparency = look.ShardTransparency
			item = part
		end
		item:PivotTo(base - Vector3.yAxis * look.SinkStuds)
		item.Parent = set.Folder
		table.insert(shards, {
			Item = item,
			Base = base,
			StartsAt = flatDistance(position, hazard.Origin) / farthest * spread,
			Started = false,
			Settled = false,
		})
	end
	for _, template in templates do
		template:Destroy()
	end
	local played = false
	local sunk = false
	local nextCrack = 0
	set.Animate = function(since: number)
		local offset = set.LandOffset
		if offset == nil then
			if since < look.MarkerWaitSeconds then
				return
			end
			offset = look.MarkerWaitSeconds
			set.LandOffset = offset
		end
		local elapsed = since - (offset :: number)
		if elapsed < 0 or sunk then
			return
		end
		if not played then
			played = true
			playSound(look.Sound)
		end
		local sink = math.clamp((elapsed - look.SinkAfterSeconds) / look.SinkSeconds, 0, 1)
		local grow = math.clamp(elapsed / spread, 0, 1)
		setFill(sheet, sheetFill + (1 - sheetFill) * math.max(1 - grow, sink))
		for _, pocket in pockets do
			setFill(pocket.Item, pocket.Transparency + (1 - pocket.Transparency) * sink)
			local stroke = pocket.Item:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = sink
			end
		end
		local isWaveRising = false
		for _, shard in shards do
			local rise = math.clamp((elapsed - shard.StartsAt) / look.RiseSeconds, 0, 1)
			if rise <= 0 or (shard.Settled and sink <= 0) then
				continue
			end
			if not shard.Started then
				shard.Started = true
				isWaveRising = true
			end
			local eased = 1 - (1 - rise) ^ 3
			shard.Item:PivotTo(shard.Base - Vector3.yAxis * (look.SinkStuds * ((1 - eased) + sink)))
			shard.Settled = rise >= 1
		end
		if isWaveRising and elapsed >= nextCrack then
			nextCrack = elapsed
				+ look.CrackGapSeconds
				+ random:NextNumber(-look.CrackGapJitterSeconds, look.CrackGapJitterSeconds)
			playCrack(random, 1 - (1 - look.CrackFarVolume) * grow)
		end
		sunk = sink >= 1
	end
end

type Boulder = {
	Rock: PVInstance,
	Parts: { BasePart },
	Rest: number,
	Turn: CFrame,
	Shadow: GuiObject,
	Point: Vector3,
	LandsAt: number,
	Spin: Vector3,
}

local function boulderModel(look: any, diameter: number): (PVInstance, { BasePart })
	local asset = AssetRegistry.get(look.ModelKey)
	local item: PVInstance? = nil
	if asset:IsA("BasePart") then
		local longest = math.max(asset.Size.X, asset.Size.Y, asset.Size.Z)
		asset.Size *= diameter / math.max(longest, 1e-3)
		item = asset
		asset.PivotOffset = CFrame.new()
	elseif asset:IsA("Model") then
		local size = asset:GetExtentsSize()
		asset:ScaleTo(asset:GetScale() * diameter / math.max(size.X, size.Y, size.Z, 1e-3))
		asset.PrimaryPart = nil
		asset.WorldPivot = asset:GetBoundingBox()
		item = asset
	else
		asset:Destroy()
	end
	if not item then
		local ball =
			flatPart("Boulder", Enum.PartType.Ball, Vector3.one * diameter, CFrame.new(), look.BoulderColor)
		ball.Material = look.FallbackMaterial
		item = ball
	end
	local rock = item :: PVInstance
	for _, tag in CollectionService:GetTags(rock) do
		CollectionService:RemoveTag(rock, tag)
	end
	for name in rock:GetAttributes() do
		rock:SetAttribute(name, nil)
	end
	local parts: { BasePart } = {}
	local all: { Instance } = rock:GetDescendants()
	table.insert(all, rock)
	for _, instance in all do
		if instance:IsA("BasePart") then
			instance.Anchored = true
			instance.CanCollide = false
			instance.CanQuery = false
			instance.CanTouch = false
			instance.CastShadow = true
			instance.Color = look.BoulderColor
			instance.Transparency = 1
			table.insert(parts, instance)
		elseif
			instance ~= rock
			and not instance:IsA("DataModelMesh")
			and not instance:IsA("SurfaceAppearance")
		then
			instance:Destroy()
		end
	end
	rock.Name = "Boulder"
	return rock, parts
end

local function restHeight(rock: PVInstance, turn: CFrame): number
	if rock:IsA("BasePart") then
		return rock.Size.Y / 2
	elseif rock:IsA("Model") then
		rock:PivotTo(turn)
		local box, size = rock:GetBoundingBox()
		return -(box.Y - size.Y / 2)
	end
	return 0
end

local function setParts(parts: { BasePart }, transparency: number)
	for _, part in parts do
		part.Transparency = transparency
	end
end

local function buildBoulderRain(set: Set, hazard: BossHazards.Hazard, center: Vector3)
	local look = BossFxConfig.Hazards.BoulderRain
	local canvas = canvasFor(set, center, reachFrom(center, hazard))
	local random = Random.new()
	local radius = hazard.Size
	local diameter = radius * look.BoulderDiameterScale
	local boulders: { Boulder } = {}
	for index, point in hazard.Points do
		Canvas.Disc(
			canvas,
			canvas.Danger,
			point,
			radius,
			spec.RedColor,
			if textures.Spot ~= "" then 0 else look.RimTransparency,
			textures.Spot,
			spec.RedColor,
			spec.RimWidthStuds
		)
		local shadow = Canvas.Disc(
			canvas,
			canvas.Danger,
			point,
			radius * look.ShadowStartScale,
			look.ShadowColor,
			look.ShadowTransparency,
			textures.Shadow
		)
		shadow.ZIndex = 2
		local rock, parts = boulderModel(look, diameter)
		rock.Name = "Boulder" .. index
		local turn = CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		local rest = restHeight(rock, turn)
		rock:PivotTo(CFrame.new(0, -500, 0))
		rock.Parent = set.Folder
		table.insert(boulders, {
			Rock = rock,
			Parts = parts,
			Rest = rest,
			Turn = turn,
			Shadow = shadow,
			Point = point,
			LandsAt = -random:NextNumber(0, look.StaggerSeconds),
			Spin = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1)),
		})
	end
	local warnSeconds = BossConfig.BigAttack.WarnSeconds
	local played = false
	set.Animate = function(since: number)
		local grow = math.clamp(1 + since / warnSeconds, 0, 1)
		local scale = look.ShadowStartScale + (0.95 - look.ShadowStartScale) * grow
		if not played and since >= 0 then
			played = true
			playSound(look.Sound)
		end
		for _, boulder in boulders do
			if since < 0 then
				Canvas.SetRadius(canvas, boulder.Shadow, radius * scale)
			end
			local fall = (since - (boulder.LandsAt - look.FallSeconds)) / look.FallSeconds
			if fall < 0 then
				continue
			end
			local sink = math.clamp((since - boulder.LandsAt - look.HoldSeconds) / look.SinkSeconds, 0, 1)
			local height = if fall < 1
				then look.FallHeightStuds * (1 - fall * fall)
				else -(boulder.Rest * 2) * sink
			local tumble = math.max(1 - fall, 0) * look.SpinSpeed
			local axis = if boulder.Spin.Magnitude > 1e-3 then boulder.Spin.Unit else Vector3.yAxis
			boulder.Rock:PivotTo(
				CFrame.new(boulder.Point + Vector3.yAxis * (spec.LiftStuds + boulder.Rest + height))
					* CFrame.fromAxisAngle(axis, tumble)
					* boulder.Turn
			)
			setParts(boulder.Parts, sink)
		end
	end
end

local function countdown(folder: Folder, boss: Model): (BillboardGui?, { TextLabel })
	local template = AssetRegistry.get("BossCountdown")
	if not template:IsA("BillboardGui") then
		template:Destroy()
		return nil, {}
	end
	local root = boss.PrimaryPart
	if not root then
		template:Destroy()
		return nil, {}
	end
	local boxCFrame, boxSize = boss:GetBoundingBox()
	local top = boxCFrame.Y + boxSize.Y / 2
	template.Adornee = root
	template.StudsOffsetWorldSpace =
		Vector3.new(0, top - root.Position.Y + BossFxConfig.Countdown.HeightAboveBossStuds, 0)
	template.StudsOffset = Vector3.zero
	template.Enabled = true
	Typography.Apply(template)
	local labels: { TextLabel } = {}
	for _, child in template:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	template.Parent = folder
	return template, labels
end

function Visuals.Build(
	boss: Model,
	kind: number,
	center: Vector3,
	slamRadius: number,
	hazard: BossHazards.Hazard?
): Set
	local folder = Instance.new("Folder")
	folder.Name = "BossAttackFx"
	local set: Set = {
		Folder = folder,
		Canvas = nil,
		Arrow = nil,
		Countdown = nil,
		Labels = {},
		Animate = nil,
		LandOffset = nil,
		HoldSeconds = 0,
		Cleanup = nil,
	}
	if kind == BossConfig.Attacks.Big and hazard then
		if hazard.Style == Styles.IceSpikes then
			buildIceSpikes(set, hazard, center)
		elseif hazard.Style == Styles.BoulderRain then
			buildBoulderRain(set, hazard, center)
		else
			buildTailSweep(set, hazard, center, boss)
		end
		local look = BossFxConfig.Canvas
		set.Arrow = Canvas.Marker(folder, look.ArrowSizeStuds, look.ArrowColor, textures.Arrow)
	else
		buildSlam(set, center, slamRadius)
	end
	set.Countdown, set.Labels = countdown(folder, boss)
	folder:SetAttribute("Kind", kind)
	folder.Parent = workspace
	return set
end

function Visuals.SetCountdown(set: Set, text: string, style: string?)
	for _, label in set.Labels do
		label.Text = text
		if style and label:GetAttribute("TextStyle") ~= nil then
			Typography.ApplyTextStyle(label, style)
		end
	end
end

function Visuals.Pulse(set: Set, amount: number)
	local canvas = set.Canvas
	if canvas then
		canvas.Danger.GroupTransparency = math.clamp(amount * spec.PulseTransparency, 0, 1)
	end
end

function Visuals.Fade(set: Set, alpha: number)
	local canvas = set.Canvas
	if canvas then
		canvas.Danger.GroupTransparency = math.max(canvas.Danger.GroupTransparency, alpha)
	end
	if set.Arrow then
		set.Arrow:Destroy()
		set.Arrow = nil
	end
end

return Visuals
