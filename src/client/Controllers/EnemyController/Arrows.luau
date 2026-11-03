--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local Arrows = {}

local parked = CFrame.new(0, -500, 0)

local function arrowTexture(): string
	local image = AssetRegistry.get(EnemyConfig.ArrowImageKey)
	local texture = if image:IsA("Decal") then image.Texture else ""
	image:Destroy()
	return texture
end

local function makeArrow(texture: string, parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = "FightArrow"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = EnemyConfig.ArrowSize
	part.CFrame = parked
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = texture
	decal.Color3 = EnemyConfig.ArrowColor
	decal.Parent = part
	part.Parent = parent
	return part
end

function Arrows.Show(trove: TroveInstance, character: Model, target: Vector3)
	trove:Clean()
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "FightArrows"
	folder.Parent = workspace
	trove:Add(folder)
	local texture = arrowTexture()
	local parts: { BasePart } = {}
	for _ = 1, EnemyConfig.ArrowCount do
		table.insert(parts, makeArrow(texture, folder))
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, folder }
	local endsAt = os.clock() + EnemyConfig.ArrowSeconds
	local scroll = 0
	local yaw = CFrame.Angles(0, math.rad(EnemyConfig.ArrowYawDegrees), 0)
	trove:Connect(RunService.Heartbeat, function(dt: number)
		local start = root.Position
		local flat = Vector3.new(target.X - start.X, 0, target.Z - start.Z)
		local total = flat.Magnitude
		if not root.Parent or os.clock() >= endsAt or total <= EnemyConfig.ArrowStopStuds then
			trove:Clean()
			return
		end
		local direction = flat.Unit
		local spacing = EnemyConfig.ArrowSpacingStuds
		scroll = (scroll + dt * EnemyConfig.ArrowScrollSpeed) % spacing
		for index, part in parts do
			local distance = (index - 1) * spacing + scroll
			if distance > total - EnemyConfig.ArrowStopStuds then
				part.CFrame = parked
				continue
			end
			local position = start + direction * distance
			local hit =
				workspace:Raycast(position, Vector3.new(0, -EnemyConfig.LaunchGroundRayStuds, 0), params)
			local ground = if hit then hit.Position else position
			local lifted = ground + Vector3.new(0, EnemyConfig.ArrowHeightStuds, 0)
			part.CFrame = CFrame.lookAt(lifted, lifted + direction) * yaw
		end
	end)
end

return Arrows
