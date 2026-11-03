--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local Types = require(script.Parent.Types)

local Spawning = {}

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function Spawning.EligibleZones(peakStrengths: { number }): { string }
	local zones: { string } = {}
	for zone, geode in GeodeConfig.Geodes do
		if not RockSpawnConfig.Zones[zone] then
			continue
		end
		for _, peak in peakStrengths do
			if peak >= geode.StrengthRequired then
				table.insert(zones, zone)
				break
			end
		end
	end
	table.sort(zones, function(a: string, b: string): boolean
		return GeodeConfig.Geodes[a].Order < GeodeConfig.Geodes[b].Order
	end)
	return zones
end

function Spawning.Label(zones: { string }): string
	local distinct: { [string]: boolean } = {}
	local count = 0
	for _, zone in zones do
		if not distinct[zone] then
			distinct[zone] = true
			count += 1
		end
	end
	return if count == 1 then zones[1] else string.format(GeodeFallConfig.ManyZonesText, count)
end

function Spawning.Count(playerCount: number): number
	return math.clamp(playerCount, 1, GeodeFallConfig.MaxCount)
end

function Spawning.KeepOutPoints(): { Vector3 }
	local points: { Vector3 } = {}
	local folder = workspace:FindFirstChild(TeleportConfig.PointsFolderName)
	if folder then
		for _, marker in folder:GetDescendants() do
			if marker:IsA("BasePart") then
				table.insert(points, marker.Position)
			end
		end
	end
	return points
end

function Spawning.SpotFilter(keepOut: { Vector3 }, taken: { Vector3 }): (Vector3) -> boolean
	return function(position: Vector3): boolean
		for _, point in keepOut do
			if flatDistance(position, point) < GeodeFallConfig.KeepOutStuds then
				return false
			end
		end
		for _, point in taken do
			if flatDistance(position, point) < GeodeFallConfig.MinGapStuds then
				return false
			end
		end
		return true
	end
end

function Spawning.Template(geodeKey: string): (Model?, BasePart?)
	local geode = GeodeConfig.Geodes[geodeKey]
	local asset = if geode then AssetRegistry.get(geode.ModelKey) else nil
	if not asset then
		return nil, nil
	end
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[GeodeFallService] Asset for {geodeKey} is not a Model`)
		return nil, nil
	end
	local model = asset :: Model
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		model:Destroy()
		return nil, nil
	end
	model.PrimaryPart = part
	return model, part
end

function Spawning.StandDistance(size: Vector3): number
	return ChopConfig.PlayerSnapOffsetFromRock.Magnitude * math.max(1, size.Z / ChopConfig.ReferenceRockSize)
end

function Spawning.Place(model: Model, part: BasePart, position: Vector3, random: Random)
	model.Name = GeodeFallConfig.ModelName
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = descendant == part
			descendant.CanTouch = false
		end
	end
	local yaw = CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
	model:PivotTo(yaw + position)
	local bottom = part.Position.Y - part.Size.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, position.Y - bottom - RockSpawnConfig.SinkStuds, 0))
end

function Spawning.Publish(geode: Types.Geode, endsAt: number)
	local part = geode.Part
	part:SetAttribute(GeodeFallConfig.IdAttribute, geode.Id)
	part:SetAttribute(GeodeFallConfig.ZoneAttribute, geode.Zone)
	part:SetAttribute(GeodeFallConfig.LandsAtAttribute, Spawning.ServerTime(geode.LandsAt))
	part:SetAttribute(GeodeFallConfig.EndsAtAttribute, Spawning.ServerTime(endsAt))
	CollectionService:AddTag(geode.Model, GeodeFallConfig.Tag)
	geode.Model.Parent = workspace
end

function Spawning.ServerTime(clock: number): number
	return workspace:GetServerTimeNow() + (clock - os.clock())
end

function Spawning.Hide(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanQuery = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
end

return Spawning
