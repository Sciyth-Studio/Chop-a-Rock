--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Types = require(script.Parent.Types)

local Spawning = {}

function Spawning.ZoneStats(zone: string): Types.ZoneStats?
	local zoneConfig = RockSpawnConfig.Zones[zone]
	if not zoneConfig then
		return nil
	end
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local first = math.huge
	local topStrength = -math.huge
	local topPayout = 0
	for key, weight in zoneConfig.Weights do
		local config = configs[key]
		if weight <= 0 or not config then
			continue
		end
		first = math.min(first, config.StrengthRequired)
		if config.StrengthRequired > topStrength then
			topStrength = config.StrengthRequired
			topPayout = config.BasePayout
		end
	end
	if first == math.huge then
		return nil
	end
	return { FirstRequirement = first, TopStrength = topStrength, TopPayout = topPayout }
end

function Spawning.BestZone(peakStrength: number): string?
	local best: string? = nil
	local bestOrder = math.huge
	local reached: string? = nil
	local reachedOrder = -math.huge
	for zone, geode in GeodeConfig.Geodes do
		if not RockSpawnConfig.Zones[zone] then
			continue
		end
		if geode.Order < bestOrder then
			best = zone
			bestOrder = geode.Order
		end
		if peakStrength >= geode.StrengthRequired and geode.Order > reachedOrder then
			reached = zone
			reachedOrder = geode.Order
		end
	end
	return reached or best
end

function Spawning.Spot(): Vector3?
	local arena = workspace:FindFirstChild(DiamondRockConfig.ArenaName)
	local spot = if arena then arena:FindFirstChild(DiamondRockConfig.SpotName, true) else nil
	if spot and spot:IsA("BasePart") then
		return spot.Position - Vector3.new(0, spot.Size.Y / 2, 0)
	end
	return nil
end

function Spawning.Template(): BasePart
	local asset = AssetRegistry.get(DiamondRockConfig.TemplateKey)
	if asset:IsA("BasePart") then
		return asset
	end
	asset:Destroy()
	local part = Instance.new("Part")
	part.Size = Vector3.new(18, 14, 18)
	part.Color = DiamondRockConfig.BeaconColor
	part.Material = Enum.Material.Glass
	return part
end

function Spawning.Build(part: BasePart, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = DiamondRockConfig.ModelName
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	part.Name = "Rock"
	part.Anchored = true
	part.CanCollide = true
	local target = part.CFrame.Rotation
		+ position
		+ Vector3.new(0, part.Size.Y / 2 - RockSpawnConfig.SinkStuds, 0)
	local delta = target * part.CFrame:Inverse()
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CFrame = delta * descendant.CFrame
		end
	end
	part.CFrame = target
	part.Parent = model
	model.PrimaryPart = part
	return model
end

function Spawning.PublishEndsAt(diamond: Types.Diamond)
	diamond.Part:SetAttribute(
		DiamondRockConfig.EndsAtAttribute,
		workspace:GetServerTimeNow() + (diamond.EndsAt - os.clock())
	)
end

function Spawning.Publish(diamond: Types.Diamond)
	local part = diamond.Part
	part:SetAttribute(DiamondRockConfig.ZoneAttribute, DiamondRockConfig.ZoneName)
	part:SetAttribute(DiamondRockConfig.HealthAttribute, diamond.Health)
	part:SetAttribute(DiamondRockConfig.MaxHealthAttribute, diamond.MaxHealth)
	part:SetAttribute(DiamondRockConfig.SlotsAttribute, DiamondRockConfig.Slots)
	Spawning.PublishEndsAt(diamond)
	CollectionService:AddTag(diamond.Model, DiamondRockConfig.Tag)
	diamond.Model.Parent = workspace
end

return Spawning
