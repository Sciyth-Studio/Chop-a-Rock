--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local ZoneScaleConfig = require(ReplicatedStorage.Config.ZoneScaleConfig)

local ZoneScale = {}

local rockZones: { [string]: string } = {}
for zone, zoneConfig in RockSpawnConfig.Zones do
	for key in zoneConfig.Weights do
		rockZones[key] = zone
	end
end

function ZoneScale.Of(zone: string): number
	local index = table.find(ZoneScaleConfig.Order, zone)
	return if index then ZoneScaleConfig.Growth ^ (index - 1) else 1
end

function ZoneScale.OfRock(key: string): number
	local zone = rockZones[key]
	return if zone then ZoneScale.Of(zone) else 1
end

function ZoneScale.Apply(part: BasePart, scale: number)
	if scale == 1 then
		return
	end
	local origin = part.CFrame
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("BasePart") then
			local offset = origin:ToObjectSpace(descendant.CFrame)
			descendant.Size *= scale
			descendant.CFrame = origin * (offset.Rotation + offset.Position * scale)
		elseif descendant:IsA("Attachment") then
			descendant.Position *= scale
		end
	end
	part.Size *= scale
end

return ZoneScale
