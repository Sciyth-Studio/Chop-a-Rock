--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local RockTemplate = require(ReplicatedStorage.RockTemplate)
local Types = require(script.Parent.Types)

local SpawnPoints = {}

local function findGround(origin: Vector3, depth: number, excluded: { Instance }): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	local hits: { RaycastResult } = {}
	for _ = 1, RockSpawnConfig.MaxGroundLayers do
		local result = workspace:Raycast(origin, Vector3.new(0, -depth, 0), params)
		if not result then
			break
		end
		table.insert(hits, result)
		params:AddToFilter(result.Instance)
	end
	table.sort(hits, function(a: RaycastResult, b: RaycastResult)
		return a.Position.Y < b.Position.Y
	end)
	local ground = hits[1]
	for index = 2, #hits do
		if hits[index].Position.Y - ground.Position.Y > RockSpawnConfig.GroundStepStuds then
			break
		end
		ground = hits[index]
	end
	return ground
end

local function isClear(cframe: CFrame, size: Vector3, excluded: { Instance }): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	params.MaxParts = 1
	return #workspace:GetPartBoundsInBox(cframe, size, params) == 0
end

function SpawnPoints.StandOffset(shape: Types.Shape): Vector3
	local offset = ChopConfig.PlayerSnapOffsetFromRock
		* math.max(1, shape.Size.Z / ChopConfig.ReferenceRockSize)
	return if shape.IsRelative then shape.Rotation:VectorToWorldSpace(offset) else offset
end

local function fits(shape: Types.Shape, ground: RaycastResult, areas: { Instance }): boolean
	local lift = RockSpawnConfig.ClearanceLiftStuds
	local excluded = table.clone(areas)
	table.insert(excluded, ground.Instance)
	local rockCFrame = shape.Rotation + ground.Position + Vector3.new(0, shape.Size.Y / 2 + lift, 0)
	if not isClear(rockCFrame, shape.Size, excluded) then
		return false
	end

	local step = RockSpawnConfig.StandMaxStepStuds
	local standColumn = ground.Position + SpawnPoints.StandOffset(shape)
	local standGround = findGround(standColumn + Vector3.new(0, step + lift, 0), step * 2 + lift, areas)
	if not standGround or math.abs(standGround.Position.Y - ground.Position.Y) > step then
		return false
	end
	table.insert(excluded, standGround.Instance)
	local standSize = RockSpawnConfig.StandClearanceSize
	return isClear(
		CFrame.new(standGround.Position + Vector3.new(0, standSize.Y / 2 + lift, 0)),
		standSize,
		excluded
	)
end

function SpawnPoints.Shape(key: string): Types.Shape?
	local template = RockTemplate.Build(key)
	if not template then
		return nil
	end
	local size = template.Size
	local shape: Types.Shape = {
		Key = key,
		Size = size,
		Rotation = template.CFrame.Rotation,
		IsRelative = template:GetAttribute(ChopConfig.RelativeOffsetAttribute) == true,
		Radius = math.max(size.X, size.Z) / 2,
	}
	template:Destroy()
	return shape
end

function SpawnPoints.Sample(shapes: { [string]: Types.Shape }): { [string]: { Types.Spot } }
	local areas: { BasePart } = {}
	for _, tagged in CollectionService:GetTagged(RockSpawnConfig.AreaTag) do
		if tagged:IsA("BasePart") and tagged:IsDescendantOf(workspace) then
			table.insert(areas, tagged)
		end
	end
	local excluded: { Instance } = table.clone(areas) :: { any }

	local ordered: { Types.Shape } = {}
	for _, shape in shapes do
		table.insert(ordered, shape)
	end
	table.sort(ordered, function(a: Types.Shape, b: Types.Shape)
		return a.Radius > b.Radius
	end)

	local minNormalY = math.cos(math.rad(RockSpawnConfig.MaxSlopeDegrees))
	local spacing = RockSpawnConfig.SampleSpacingStuds
	local result: { [string]: { Types.Spot } } = {}
	for _, area in areas do
		local zone = area:GetAttribute(RockSpawnConfig.ZoneAttribute)
		if type(zone) ~= "string" then
			warn(`[RockService] {area:GetFullName()} has no {RockSpawnConfig.ZoneAttribute} attribute`)
			continue
		end
		local list = result[zone] or {}
		result[zone] = list
		local size = area.Size
		local columnsX = math.max(1, math.floor(size.X / spacing))
		local columnsZ = math.max(1, math.floor(size.Z / spacing))
		for column = 0, columnsX - 1 do
			for row = 0, columnsZ - 1 do
				local top = area.CFrame:PointToWorldSpace(
					Vector3.new(
						-size.X / 2 + (column + 0.5) * size.X / columnsX,
						size.Y / 2,
						-size.Z / 2 + (row + 0.5) * size.Z / columnsZ
					)
				)
				local ground = findGround(top, size.Y, excluded)
				if not ground or ground.Normal.Y < minNormalY then
					continue
				end
				local spot: Types.Spot = { Position = ground.Position, Fits = {}, Largest = nil }
				for _, shape in ordered do
					if fits(shape, ground, excluded) then
						spot.Fits[shape.Key] = true
						spot.Largest = spot.Largest or shape.Key
					end
				end
				if spot.Largest then
					table.insert(list, spot)
				end
			end
		end
	end

	for _, area in areas do
		area.Transparency = 1
	end
	return result
end

return SpawnPoints
