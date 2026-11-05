--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ZoneGeodeConfig = require(ReplicatedStorage.Config.ZoneGeodeConfig)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)

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
end

local function buildModel(zone: string, look: number): Model?
	local zoneConfig = ZoneGeodeConfig.Zones[zone]
	local geodeKey = if zoneConfig then zoneConfig.Looks[look] else nil
	local geode = if geodeKey then GeodeConfig.Geodes[geodeKey] else nil
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

local function glide(trove: any, model: Model, from: CFrame, to: CFrame, seconds: number, onDone: () -> ())
	local started = os.clock()
	model:PivotTo(from)
	local connection: any
	connection = trove:Connect(RunService.Heartbeat, function()
		local progress = math.clamp((os.clock() - started) / seconds, 0, 1)
		model:PivotTo(from:Lerp(to, progress))
		if progress >= 1 then
			trove:Remove(connection)
			onDone()
		end
	end)
end

local function spawn(id: number, zone: string, look: number, position: Vector3, yaw: number)
	local parent = folder
	if geodes[id] or not parent then
		return
	end
	local model = buildModel(zone, look)
	local part = if model then model.PrimaryPart else nil
	if not model or not part then
		return
	end
	model:PivotTo(CFrame.Angles(0, yaw, 0) * model:GetPivot().Rotation + position)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local lift = position.Y - (boxCFrame.Position.Y - boxSize.Y / 2) - ZoneGeodeConfig.SinkStuds
	local target = model:GetPivot() + Vector3.new(0, lift, 0)
	local below = target - Vector3.new(0, boxSize.Y, 0)

	local geodeTrove = Trove.new()
	geodeTrove:Add(model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = ZoneGeodeConfig.PromptText
	prompt.ObjectText = GeodeConfig.Geodes[zone].DisplayName
	prompt.HoldDuration = ZoneGeodeConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = ZoneGeodeConfig.PromptRangeStuds + math.max(boxSize.X, boxSize.Z) / 2
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = part

	local geode: ClientGeode = { Id = id, Model = model, Prompt = prompt, Trove = geodeTrove, IsUp = false }
	geodes[id] = geode
	geodeTrove:Connect(prompt.Triggered, function()
		Packets.ZoneGeodeTake:Fire(id)
	end)
	model:PivotTo(below)
	model.Parent = parent
	glide(geodeTrove, model, below, target, ZoneGeodeConfig.RiseSeconds, function()
		geode.IsUp = true
		refreshPrompt(geode)
	end)
end

local function remove(id: number)
	local geode = geodes[id]
	if not geode then
		return
	end
	geodes[id] = nil
	geode.IsUp = false
	refreshPrompt(geode)
	local pivot = geode.Model:GetPivot()
	local _, boxSize = geode.Model:GetBoundingBox()
	glide(
		geode.Trove,
		geode.Model,
		pivot,
		pivot - Vector3.new(0, boxSize.Y, 0),
		ZoneGeodeConfig.SinkSeconds,
		function()
			geode.Trove:Destroy()
		end
	)
end

function ZoneGeodeController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	chopController = controllers.ChopController
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
	Packets.ZoneGeodeReady:Fire()
end

function ZoneGeodeController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
	folder = nil
end

return ZoneGeodeController
