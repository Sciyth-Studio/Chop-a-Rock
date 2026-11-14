--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BaseLevels = require(ReplicatedStorage.Utils.BaseLevels)
local EggDropConfig = require(ReplicatedStorage.Config.EggDropConfig)
local EggLuck = require(ReplicatedStorage.Utils.EggLuck)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Packets = require(ReplicatedStorage.Packets)
local PromptStat = require(ReplicatedStorage.Utils.PromptStat)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ZoneGeodeConfig = require(ReplicatedStorage.Config.ZoneGeodeConfig)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)
local Silhouette = require(script.Silhouette)

type TroveInstance = typeof(Trove.new())
type ClientGeode = {
	Id: number,
	Model: Model,
	Prompt: ProximityPrompt,
	Trove: any,
	IsUp: boolean,
}

local geodes: { [number]: ClientGeode } = {}
local folder: Folder? = nil
local chopController: any = nil
local enemyController: any = nil
local dataController: any = nil

local ZoneGeodeController = {
	Name = "ZoneGeodeController",
	_trove = nil :: TroveInstance?,
}

local function refreshPrompt(geode: ClientGeode)
	geode.Prompt.Enabled = geode.IsUp
		and not chopController:IsMinigameActive()
		and Tutorial.CanTakeGeode(Tutorial.StepOf(dataController:Get({ "Tutorial" })))
end

local function refreshAll()
	for _, geode in geodes do
		refreshPrompt(geode)
	end
	local current = folder
	if current then
		local isFighting = chopController:IsMinigameActive() and enemyController:GetFight() ~= nil
		current.Parent = if isFighting then nil else workspace
	end
end

local function lookKey(zone: string, look: number): string?
	local zoneConfig = ZoneGeodeConfig.Zones[zone]
	return if zoneConfig then zoneConfig.Looks[look] else nil
end

local function buildModel(zone: string, look: number): Model?
	local key = lookKey(zone, look)
	local geode = if key then GeodeConfig.Geodes[key] else nil
	if not geode then
		return nil
	end
	local asset = AssetRegistry.get(geode.ModelKey)
	if not asset:IsA("Model") or not asset.PrimaryPart then
		asset:Destroy()
		return nil
	end
	asset:ScaleTo(asset:GetScale() * ZoneScale.Of(zone))
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	return asset
end

local function groundPivot(model: Model, position: Vector3, yaw: number): CFrame
	model:PivotTo(CFrame.Angles(0, yaw, 0) * model:GetPivot().Rotation + position)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local lift = position.Y - (boxCFrame.Position.Y - boxSize.Y / 2) - ZoneGeodeConfig.SinkStuds
	return model:GetPivot() + Vector3.new(0, lift, 0)
end

local function playTick(pitch: number)
	local asset = AssetRegistry.get(EggDropConfig.TickSoundKey)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	asset.PlaybackSpeed = pitch
	SoundService:PlayLocalSound(asset)
	task.delay(2, function()
		asset:Destroy()
	end)
end

local function luckText(hundredths: number): string
	return string.format("x%.2f", hundredths / 100)
end

local function addOutline(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "EggOutline"
	highlight.FillTransparency = 1
	highlight.OutlineColor = EggDropConfig.OutlineColor
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
end

local function reground(model: Model, position: Vector3)
	local box, size = model:GetBoundingBox()
	local bottom = box.Position.Y - size.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, position.Y - ZoneGeodeConfig.SinkStuds - bottom, 0))
end

local function makeLabel(trove: any, at: Vector3, height: number): (BillboardGui?, (string) -> (), BasePart?)
	local asset = AssetRegistry.get(EggDropConfig.LabelTemplateKey)
	if not asset:IsA("BillboardGui") then
		asset:Destroy()
		return nil, function(_text: string) end, nil
	end
	local adornee = Instance.new("Part")
	adornee.Name = "EggLabelAnchor"
	adornee.Size = Vector3.one * 0.2
	adornee.Transparency = 1
	adornee.Anchored = true
	adornee.CanCollide = false
	adornee.CanQuery = false
	adornee.CanTouch = false
	adornee.CastShadow = false
	adornee.Position = at + Vector3.new(0, height + EggDropConfig.LabelHeightStuds, 0)
	adornee.Parent = folder
	trove:Add(adornee)
	local billboard: BillboardGui = asset
	Typography.Apply(billboard)
	billboard.Adornee = adornee
	local luckLabel = billboard:FindFirstChild("Luck", true)
	local clover = billboard:FindFirstChild("Clover", true)
	if clover and clover:IsA("ImageLabel") then
		clover.Image = EggDropConfig.LuckIcon
	end
	billboard.Parent = adornee
	trove:Add(billboard)
	return billboard,
		function(text: string)
			if luckLabel and luckLabel:IsA("TextLabel") then
				luckLabel.Text = text
			end
		end,
		adornee
end

local function resize(model: Model, scale: number, position: Vector3, anchor: BasePart?)
	model:ScaleTo(scale)
	reground(model, position)
	if anchor then
		local _, size = model:GetBoundingBox()
		anchor.Position = position + Vector3.new(0, size.Y + EggDropConfig.LabelHeightStuds, 0)
	end
end

local function animate(
	geode: ClientGeode,
	zone: string,
	look: number,
	others: { Model },
	saves: { Silhouette.Saved },
	finalSave: Silhouette.Saved,
	origin: Vector3,
	target: CFrame,
	luck: number,
	setText: (string) -> (),
	position: Vector3,
	anchor: BasePart?
)
	local trove = geode.Trove
	local model = geode.Model
	local launchStart = os.clock()
	local fromCFrame = target.Rotation + origin
	local swaps = EggDropConfig.ShuffleLookSwaps
	local shown = 0
	local lastValue = -1
	local lastTick = 0
	local phase = "Launch"
	local baseScale = model:GetScale()
	local otherScales = {}
	for index, other in others do
		otherScales[index] = other:GetScale()
	end
	local connection: any
	connection = trove:Connect(RunService.Heartbeat, function()
		local now = os.clock()
		if phase == "Launch" then
			local alpha = math.clamp((now - launchStart) / EggDropConfig.LaunchSeconds, 0, 1)
			local arc = 4 * alpha * (1 - alpha) * EggDropConfig.LaunchHeightStuds * ZoneScale.Of(zone)
			local cframe = fromCFrame:Lerp(target, alpha) + Vector3.new(0, arc, 0)
			model:PivotTo(cframe * CFrame.Angles(0, alpha * math.pi * 4, 0))
			for _, other in others do
				other:PivotTo(model:GetPivot())
			end
			if alpha >= 1 then
				phase = "Shuffle"
				launchStart = now
				model:PivotTo(target)
				for _, other in others do
					other:PivotTo(target)
				end
			end
			return
		end
		local progress = math.clamp((now - launchStart) / EggDropConfig.ShuffleSeconds, 0, 1)
		local eased = 1 - (1 - progress) ^ 3
		local value = math.floor(
			EggDropConfig.LuckMinHundredths + (luck - EggDropConfig.LuckMinHundredths) * eased + 0.5
		)
		if value ~= lastValue then
			lastValue = value
			setText(luckText(value))
			local grow = EggLuck.Scale(value)
			resize(model, baseScale * grow, position, anchor)
			for index, other in others do
				resize(other, otherScales[index] * grow, position, nil)
			end
			if now - lastTick >= EggDropConfig.TickMinGapSeconds then
				lastTick = now
				playTick(
					EggDropConfig.TickPitchStart
						+ (EggDropConfig.TickPitchEnd - EggDropConfig.TickPitchStart) * eased
				)
			end
		end
		local swapIndex = math.floor(eased * swaps)
		if #others > 0 and swapIndex ~= shown and progress < 1 then
			shown = swapIndex
			local showFinal = swapIndex % 2 == 0
			model.Parent = if showFinal then folder else nil
			for _, other in others do
				other.Parent = if showFinal then nil else folder
			end
		end
		if progress >= 1 then
			trove:Remove(connection)
			for _, other in others do
				other:Destroy()
			end
			model.Parent = folder
			Silhouette.Restore(finalSave)
			table.clear(saves)
			resize(model, baseScale * EggLuck.Scale(luck), position, anchor)
			LocalSound.Play(EggDropConfig.LandSoundKey)
			setText(luckText(luck))
			geode.IsUp = true
			refreshPrompt(geode)
		end
	end)
end

local function spawn(
	id: number,
	zone: string,
	look: number,
	position: Vector3,
	yaw: number,
	origin: Vector3,
	luck: number,
	isFresh: boolean
)
	local parent = folder
	if geodes[id] or not parent then
		return
	end
	local model = buildModel(zone, look)
	local part = if model then model.PrimaryPart else nil
	if not model or not part then
		return
	end
	local target = groundPivot(model, position, yaw)
	local _, boxSize = model:GetBoundingBox()

	local geodeTrove = Trove.new()
	geodeTrove:Add(model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = EggDropConfig.PromptText
	local key = lookKey(zone, look)
	local geodeInfo = GeodeConfig.Geodes[key or zone]
	local hatchMultiplier = if dataController
		then BaseLevels.HatchMultiplier(dataController:Get({ "BaseLevel" }))
		else 1
	prompt.ObjectText = PromptStat.Egg(geodeInfo.DisplayName, geodeInfo.HatchSeconds * hatchMultiplier)
	prompt.HoldDuration = ZoneGeodeConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = EggDropConfig.PromptRangeStuds + math.max(boxSize.X, boxSize.Z) / 2
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = part

	local geode: ClientGeode = { Id = id, Model = model, Prompt = prompt, Trove = geodeTrove, IsUp = false }
	geodes[id] = geode
	geodeTrove:Connect(prompt.Triggered, function()
		Packets.ZoneGeodeTake:Fire(id)
	end)
	local label, setText, anchor = makeLabel(geodeTrove, position, boxSize.Y)
	addOutline(model)

	if not isFresh then
		model:PivotTo(target)
		model:ScaleTo(model:GetScale() * EggLuck.Scale(luck))
		reground(model, position)
		model.Parent = parent
		if anchor then
			local _, size = model:GetBoundingBox()
			anchor.Position = position + Vector3.new(0, size.Y + EggDropConfig.LabelHeightStuds, 0)
		end
		setText(luckText(luck))
		geode.IsUp = true
		refreshPrompt(geode)
		return
	end

	local saves: { Silhouette.Saved } = {}
	local finalSave = Silhouette.Apply(model)
	table.insert(saves, finalSave)
	local others: { Model } = {}
	local zoneConfig = ZoneGeodeConfig.Zones[zone]
	if zoneConfig then
		for index in zoneConfig.Looks do
			if index ~= look then
				local other = buildModel(zone, index)
				if other then
					other:PivotTo(target)
					addOutline(other)
					table.insert(saves, Silhouette.Apply(other))
					table.insert(others, other)
					geodeTrove:Add(other)
				end
			end
		end
	end
	model:PivotTo(target.Rotation + origin)
	model.Parent = parent
	setText(luckText(EggDropConfig.LuckMinHundredths))
	if label then
		label.Enabled = false
		task.delay(EggDropConfig.LaunchSeconds, function()
			label.Enabled = true
		end)
	end
	animate(geode, zone, look, others, saves, finalSave, origin, target, luck, setText, position, anchor)
end

local function remove(id: number, isShattered: boolean)
	local geode = geodes[id]
	if not geode then
		return
	end
	geodes[id] = nil
	geode.IsUp = false
	refreshPrompt(geode)
	if isShattered then
		LocalSound.Play(EggDropConfig.ShatterSoundKey)
		geode.Trove:Destroy()
		return
	end
	local model = geode.Model
	local started = os.clock()
	local from = model:GetPivot()
	local _, boxSize = model:GetBoundingBox()
	local to = from - Vector3.new(0, boxSize.Y, 0)
	local connection: any
	connection = geode.Trove:Connect(RunService.Heartbeat, function()
		local progress = math.clamp((os.clock() - started) / ZoneGeodeConfig.SinkSeconds, 0, 1)
		model:PivotTo(from:Lerp(to, progress))
		if progress >= 1 then
			geode.Trove:Remove(connection)
			geode.Trove:Destroy()
		end
	end)
end

function ZoneGeodeController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	chopController = controllers.ChopController
	enemyController = controllers.EnemyController
	dataController = controllers.DataController
end

function ZoneGeodeController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local created = Instance.new("Folder")
	created.Name = ZoneGeodeConfig.FolderName
	created.Parent = workspace
	folder = created
	trove:Add(created)
	trove:Add(function()
		for _, geode in geodes do
			geode.Trove:Destroy()
		end
		table.clear(geodes)
	end)
	trove:Add(Packets.ZoneGeodeSpawned.OnClientEvent:Connect(spawn))
	trove:Add(Packets.ZoneGeodeRemoved.OnClientEvent:Connect(remove))
	trove:Add(chopController.ActiveChanged:Connect(refreshAll))
	trove:Add(dataController:Observe({ "Tutorial", "Step" }, refreshAll))
end

function ZoneGeodeController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
	folder = nil
end

return ZoneGeodeController
