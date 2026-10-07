--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)

local SpotDots = {}

local folderName = "SpawnSpots"
local fallbackColor = Color3.fromRGB(255, 255, 255)

function SpotDots.Clear()
	local existing = workspace:FindFirstChild(folderName)
	if existing then
		existing:Destroy()
	end
end

function SpotDots.Show(positions: { Vector3 }, keys: { string })
	SpotDots.Clear()
	if #positions == 0 then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = folderName
	local size = RockSpawnConfig.SpotDotSize
	for index, position in positions do
		local dot = Instance.new("Part")
		dot.Name = keys[index] or "Spot"
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.new(size, size, size)
		dot.Position = position + Vector3.new(0, size / 2, 0)
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanQuery = false
		dot.CanTouch = false
		dot.CastShadow = false
		dot.Material = Enum.Material.Neon
		dot.Color = RockSpawnConfig.SpotColors[keys[index]] or fallbackColor
		dot.Parent = folder
	end
	folder.Parent = workspace
end

return SpotDots
