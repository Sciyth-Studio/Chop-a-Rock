--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local IntroConfig = require(ReplicatedStorage.Config.IntroConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local RockTemplate = require(ReplicatedStorage.RockTemplate)
local Types = require(script.Parent.Types)

local Stage = {}

local FOLDER_NAME = "IntroStage"
local PLAYER_CLIPS = { "Drive", "LookUp", "BoingOut", "Dazed", "Awe" }
local MASTER_CLIPS = { "Idle", "Leap", "Chop", "Point" }
local FALLBACK_EMIT_COUNT = 20

local function prepareRig(model: Model, clips: { string }, parent: Instance): Types.Actor?
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) then
		return nil
	end
	for _, descendant in model:GetDescendants() do
		if
			descendant:IsA("BaseScript")
			or descendant:IsA("Tool")
			or descendant:IsA("Sound")
			or descendant:IsA("ForceField")
			or descendant:IsA("ParticleEmitter")
			or descendant:IsA("BillboardGui")
		then
			descendant:Destroy()
		end
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = descendant == root
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	humanoid.EvaluateStateMachine = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	model.Parent = parent
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		local created = Instance.new("Animator")
		created.Parent = humanoid
		animator = created
	end
	local actor: Types.Actor = {
		Model = model,
		Root = root,
		Head = model:FindFirstChild("Head") :: BasePart?,
		Animator = animator :: Animator,
		Tracks = {},
	}
	for _, clip in clips do
		local animation = AssetRegistry.get(IntroConfig.Animations[clip])
		if not animation:IsA("Animation") or animation.AnimationId == "" then
			warn(`[IntroController] Missing animation "{IntroConfig.Animations[clip]}"`)
			return nil
		end
		local track = actor.Animator:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		actor.Tracks[clip] = track
	end
	return actor
end

local function cloneCharacter(character: Model): Model?
	local wasArchivable = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = wasArchivable
	if copy then
		copy.Name = "IntroPlayer"
	end
	return copy
end

function Stage.Build(character: Model): Types.Stage?
	local setAsset = AssetRegistry.get(IntroConfig.SetKey)
	if not setAsset:IsA("Model") then
		setAsset:Destroy()
		warn(`[IntroController] Asset "{IntroConfig.SetKey}" is not a Model`)
		return nil
	end
	local masterAsset = AssetRegistry.get(IntroConfig.MasterKey)
	if not masterAsset:IsA("Model") then
		masterAsset:Destroy()
		setAsset:Destroy()
		warn(`[IntroController] Asset "{IntroConfig.MasterKey}" is not a Model`)
		return nil
	end
	local set = setAsset :: Model
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	set:PivotTo(IntroConfig.SetOrigin)
	set.Parent = folder

	local function fail(message: string): nil
		warn(`[IntroController] {message}`)
		folder:Destroy()
		masterAsset:Destroy()
		return nil
	end

	local markers: { [string]: CFrame } = {}
	local markerFolder = set:FindFirstChild("Markers")
	if markerFolder then
		for _, marker in markerFolder:GetChildren() do
			if marker:IsA("BasePart") then
				markers[marker.Name] = marker.CFrame
			end
		end
	end
	for _, name in { "CarStart", "CarStop", "Boulder", "MasterStart" } do
		if not markers[name] then
			return fail(`Missing marker "{name}" in {IntroConfig.SetKey}`)
		end
	end

	local car = set:FindFirstChild("Car")
	local body = if car then car:FindFirstChild("Body") else nil
	local seat = if body then body:FindFirstChild("Seat") else nil
	if not (car and car:IsA("Model") and seat and seat:IsA("Attachment")) then
		return fail(`Missing Car.Body.Seat in {IntroConfig.SetKey}`)
	end
	car:PivotTo(markers.CarStart)
	local carParts = {}
	local pivot = car:GetPivot()
	for _, part in car:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(
				carParts,
				{ Part = part, Size = part.Size, Offset = pivot:ToObjectSpace(part.CFrame) }
			)
		end
	end

	local boulder = RockTemplate.Build(IntroConfig.BoulderRockKey)
	if not boulder then
		return fail(`Missing rock "{IntroConfig.BoulderRockKey}"`)
	end
	boulder.Name = "MegaBoulder"
	boulder.Size *= IntroConfig.BoulderScale
	boulder.Color = IntroConfig.BoulderColor
	boulder.Anchored = true
	boulder.CanCollide = false
	local glow = Instance.new("Highlight")
	glow.FillTransparency = 1
	glow.OutlineColor = IntroConfig.BoulderGlowColor
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = boulder
	local rest = markers.Boulder * CFrame.new(0, boulder.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(25), 0)
	boulder.CFrame = rest + Vector3.new(0, IntroConfig.BoulderDropStuds, 0)
	boulder.Parent = folder

	local shadow = Instance.new("Part")
	shadow.Name = "BoulderShadow"
	shadow.Shape = Enum.PartType.Cylinder
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CanQuery = false
	shadow.CanTouch = false
	shadow.CastShadow = false
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Color = IntroConfig.ShadowColor
	shadow.Transparency = 1
	shadow.Size = Vector3.new(0.1, 1, 1)
	shadow.CFrame = markers.Boulder * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
	shadow.Parent = folder

	folder.Parent = workspace
	local playerModel = cloneCharacter(character)
	if not playerModel then
		return fail("Could not copy the character")
	end
	playerModel:PivotTo(seat.WorldCFrame)
	local masterModel = masterAsset :: Model
	masterModel:PivotTo(markers.MasterStart)
	local player = prepareRig(playerModel, PLAYER_CLIPS, folder)
	local master = prepareRig(masterModel, MASTER_CLIPS, folder)
	if not (player and master) then
		playerModel:Destroy()
		return fail("Could not set up the actors")
	end
	master.Root.CFrame = markers.MasterStart

	local stars: { BasePart } = {}
	for index = 1, IntroConfig.StarCount do
		local star = Instance.new("Part")
		star.Name = `Star{index}`
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.new(0.45, 0.45, 0.45)
		star.Material = Enum.Material.Neon
		star.Color = IntroConfig.StarColor
		star.Anchored = true
		star.CanCollide = false
		star.CanQuery = false
		star.CanTouch = false
		star.CastShadow = false
		star.Transparency = 1
		star.Parent = folder
		table.insert(stars, star)
	end

	local stage: Types.Stage = {
		Set = set,
		Markers = markers,
		Car = car,
		CarParts = carParts,
		Seat = seat,
		Boulder = boulder,
		BoulderRest = rest,
		Shadow = shadow,
		Player = player,
		Master = master,
		Stars = stars,
	}
	return stage
end

function Stage.IsLoaded(stage: Types.Stage): boolean
	for _, actor in { stage.Player, stage.Master } do
		for _, track in actor.Tracks do
			if track.Length <= 0 then
				return false
			end
		end
	end
	return true
end

function Stage.Unloaded(stage: Types.Stage): { string }
	local names = {}
	for _, actor in { stage.Player, stage.Master } do
		for name, track in actor.Tracks do
			if track.Length <= 0 then
				table.insert(names, name)
			end
		end
	end
	return names
end

function Stage.SeatPlayer(stage: Types.Stage)
	stage.Player.Root.CFrame = stage.Seat.WorldCFrame
end

function Stage.Play(actor: Types.Actor, clip: string, looped: boolean?): AnimationTrack
	for name, track in actor.Tracks do
		if name ~= clip and track.IsPlaying then
			track:Stop(0)
		end
	end
	local track = actor.Tracks[clip]
	track.Looped = looped == true
	track:Play(0)
	return track
end

function Stage.Emit(key: string, cframe: CFrame, lifetimeSeconds: number)
	local asset = AssetRegistry.get(key)
	local holder = Instance.new("Part")
	holder.Name = key
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = cframe
	if asset:IsA("Attachment") then
		asset.Parent = holder
	elseif asset:IsA("PVInstance") then
		asset:PivotTo(cframe)
		asset.Parent = holder
	else
		asset:Destroy()
		holder:Destroy()
		return
	end
	holder.Parent = workspace:FindFirstChild(FOLDER_NAME) or workspace
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			local count = descendant:GetAttribute("EmitCount")
			local amount = if type(count) == "number" then count else FALLBACK_EMIT_COUNT
			descendant:Emit(math.max(1, math.floor(amount * LowGraphics.EmitScale() + 0.5)))
		end
	end
	task.delay(lifetimeSeconds, function()
		if holder.Parent then
			holder:Destroy()
		end
	end)
end

local function tweenCar(stage: Types.Stage, scale: Vector3, seconds: number, style: Enum.EasingStyle)
	local pivot = stage.Markers.CarStop
	local groundY = stage.Markers.Boulder.Position.Y
	local info = TweenInfo.new(seconds, style, Enum.EasingDirection.Out)
	for _, entry in stage.CarParts do
		local world = pivot * entry.Offset
		local position = world.Position
		local flatOffset = pivot:VectorToObjectSpace(position - pivot.Position)
		local squashed = pivot.Position
			+ pivot:VectorToWorldSpace(Vector3.new(flatOffset.X * scale.X, 0, flatOffset.Z * scale.Z))
		local height = groundY + (position.Y - groundY) * scale.Y
		local target = CFrame.new(squashed.X, height, squashed.Z) * world.Rotation
		TweenService:Create(entry.Part, info, { Size = entry.Size * scale, CFrame = target }):Play()
	end
end

function Stage.Squash(stage: Types.Stage)
	tweenCar(stage, IntroConfig.SquashScale, IntroConfig.SquashSeconds, Enum.EasingStyle.Quad)
end

function Stage.PopBack(stage: Types.Stage)
	tweenCar(stage, Vector3.one, IntroConfig.PopBackSeconds, Enum.EasingStyle.Back)
end

function Stage.UpdateStars(stage: Types.Stage, isShown: boolean, clock: number)
	local head = stage.Player.Head
	for index, star in stage.Stars do
		if not (isShown and head) then
			star.Transparency = 1
			continue
		end
		local angle = clock * IntroConfig.StarSpinSpeed + (index - 1) * (2 * math.pi / #stage.Stars)
		star.Transparency = 0
		star.CFrame = CFrame.new(
			head.Position
				+ Vector3.new(
					math.cos(angle) * IntroConfig.StarRadiusStuds,
					IntroConfig.StarHeightStuds,
					math.sin(angle) * IntroConfig.StarRadiusStuds
				)
		)
	end
end

function Stage.Destroy(stage: Types.Stage)
	for _, actor in { stage.Player, stage.Master } do
		for _, track in actor.Tracks do
			track:Stop(0)
		end
	end
	local folder = stage.Set.Parent
	if folder then
		folder:Destroy()
	end
end

return Stage
