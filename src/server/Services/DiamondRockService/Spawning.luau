--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
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

function Spawning.PickZone(random: Random, rockService: any): string?
	local counts: { [string]: number } = {}
	local total = 0
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not root or not root:IsA("BasePart") then
			continue
		end
		local zone = rockService:GetZoneAt(root.Position)
		if zone and RockSpawnConfig.Zones[zone] then
			counts[zone] = (counts[zone] or 0) + 1
			total += 1
		end
	end
	if total == 0 then
		return nil
	end
	local roll = random:NextNumber() * total
	for zone, count in counts do
		roll -= count
		if roll <= 0 then
			return zone
		end
	end
	return next(counts)
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

function Spawning.StandDistance(size: Vector3): number
	return ChopConfig.PlayerSnapOffsetFromRock.Magnitude * math.max(1, size.Z / ChopConfig.ReferenceRockSize)
end

function Spawning.Build(part: BasePart, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = DiamondRockConfig.ModelName
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	part.Name = "Rock"
	part.Anchored = true
	part.CanCollide = true
	part.CFrame = part.CFrame.Rotation
		+ position
		+ Vector3.new(0, part.Size.Y / 2 - RockSpawnConfig.SinkStuds, 0)
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
	part:SetAttribute(DiamondRockConfig.ZoneAttribute, diamond.Zone)
	part:SetAttribute(DiamondRockConfig.HealthAttribute, diamond.Health)
	part:SetAttribute(DiamondRockConfig.MaxHealthAttribute, diamond.MaxHealth)
	part:SetAttribute(DiamondRockConfig.StrengthAttribute, diamond.StrengthRequired)
	part:SetAttribute(DiamondRockConfig.SlotsAttribute, DiamondRockConfig.Slots)
	Spawning.PublishEndsAt(diamond)
	CollectionService:AddTag(diamond.Model, DiamondRockConfig.Tag)
	diamond.Model.Parent = workspace
end

return Spawning
