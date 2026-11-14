--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)

return function(position: Vector3): string
	for _, area in CollectionService:GetTagged(RockSpawnConfig.AreaTag) do
		if not area:IsA("BasePart") or not area:IsDescendantOf(workspace) then
			continue
		end
		local relative = area.CFrame:PointToObjectSpace(position)
		if math.abs(relative.Z) <= area.Size.Z / 2 then
			local zone = area:GetAttribute(RockSpawnConfig.ZoneAttribute)
			if type(zone) == "string" then
				return zone
			end
		end
	end
	return ""
end
