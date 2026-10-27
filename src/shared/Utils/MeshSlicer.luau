--!strict

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LiveSplitConfig = require(ReplicatedStorage.Config.LiveSplitConfig)

export type Corner = {
	Position: Vector3,
	Uv: Vector2,
}

export type Mesh = {
	Triangles: { { Corner } },
	Winding: number,
	UvPerStud: number,
}

local keyPrecision = 1e4
local planeEpsilon = 1e-4
local minimumArea = 1e-6

local activeBuilders = 0

local MeshSlicer = {}

local function pointKey(point: Vector3): string
	return string.format(
		"%d,%d,%d",
		math.round(point.X * keyPrecision),
		math.round(point.Y * keyPrecision),
		math.round(point.Z * keyPrecision)
	)
end

local function lerpCorner(a: Corner, b: Corner, alpha: number): Corner
	return { Position = a.Position:Lerp(b.Position, alpha), Uv = a.Uv:Lerp(b.Uv, alpha) }
end

local function fan(polygon: { Corner }, into: { { Corner } })
	for index = 2, #polygon - 1 do
		table.insert(into, { polygon[1], polygon[index], polygon[index + 1] })
	end
end

local function buildLoops(segments: { { Vector3 } }): { { Vector3 } }
	local byStart: { [string]: number } = {}
	for index, segment in segments do
		byStart[pointKey(segment[1])] = index
	end
	local used: { [number]: boolean } = {}
	local loops: { { Vector3 } } = {}
	for index in segments do
		if used[index] then
			continue
		end
		local loop: { Vector3 } = {}
		local current: number? = index
		while current and not used[current] do
			used[current] = true
			local segment = segments[current]
			table.insert(loop, segment[1])
			current = byStart[pointKey(segment[2])]
		end
		if #loop >= 3 then
			table.insert(loops, loop)
		end
	end
	return loops
end

local function addCaps(mesh: Mesh, segments: { { Vector3 } }, outward: Vector3, into: { { Corner } })
	local tangent = if math.abs(outward.Y) < 0.9
		then outward:Cross(Vector3.yAxis).Unit
		else outward:Cross(Vector3.xAxis).Unit
	local bitangent = outward:Cross(tangent)
	local function corner(position: Vector3): Corner
		return {
			Position = position,
			Uv = Vector2.new(position:Dot(tangent), position:Dot(bitangent)) * mesh.UvPerStud,
		}
	end
	for _, loop in buildLoops(segments) do
		local center = Vector3.zero
		for _, point in loop do
			center += point
		end
		center /= #loop
		for index, point in loop do
			local nextPoint = loop[index % #loop + 1]
			local facing = (point - center):Cross(nextPoint - center) * mesh.Winding
			if facing.Magnitude < minimumArea then
				continue
			end
			if facing:Dot(outward) >= 0 then
				table.insert(into, { corner(center), corner(point), corner(nextPoint) })
			else
				table.insert(into, { corner(center), corner(nextPoint), corner(point) })
			end
		end
	end
end

local function uvPerStud(triangles: { { Corner } }): number
	local uvLength = 0
	local studLength = 0
	for _, corners in triangles do
		studLength += (corners[2].Position - corners[1].Position).Magnitude
		uvLength += (corners[2].Uv - corners[1].Uv).Magnitude
	end
	return if studLength > 0 then uvLength / studLength else 0
end

function MeshSlicer.Read(meshId: string): Mesh?
	local ok, result = pcall(function()
		return AssetService:CreateEditableMeshAsync(Content.fromUri(meshId), { FixedSize = true })
	end)
	if not ok or not result then
		warn(`[MeshSlicer] could not read {meshId}: {result}`)
		return nil
	end
	local editable = result :: EditableMesh
	local triangles: { { Corner } } = {}
	local winding = 0
	for _, face in editable:GetFaces() do
		local vertices = editable:GetFaceVertices(face)
		if #vertices ~= 3 then
			continue
		end
		local uvs = editable:GetFaceUVs(face)
		local corners: { Corner } = {}
		for index, vertex in vertices do
			local uvId = uvs[index]
			table.insert(corners, {
				Position = editable:GetPosition(vertex),
				Uv = (if uvId then editable:GetUV(uvId) else nil) or Vector2.zero,
			})
		end
		table.insert(triangles, corners)
		local normals = editable:GetFaceNormals(face)
		local normal = if normals[1] then editable:GetNormal(normals[1]) else nil
		if normal then
			local cross = (corners[2].Position - corners[1].Position):Cross(
				corners[3].Position - corners[1].Position
			)
			winding += cross:Dot(normal)
		end
	end
	editable:Destroy()
	return {
		Triangles = triangles,
		Winding = if winding < 0 then -1 else 1,
		UvPerStud = uvPerStud(triangles),
	}
end

function MeshSlicer.Scale(mesh: Mesh, scale: Vector3): Mesh
	local triangles: { { Corner } } = {}
	for _, triangle in mesh.Triangles do
		local corners: { Corner } = {}
		for index, corner in triangle do
			corners[index] = { Position = corner.Position * scale, Uv = corner.Uv }
		end
		table.insert(triangles, corners)
	end
	return { Triangles = triangles, Winding = mesh.Winding, UvPerStud = uvPerStud(triangles) }
end

function MeshSlicer.Split(mesh: Mesh, point: Vector3, normal: Vector3): (Mesh?, Mesh?)
	local above: { { Corner } } = {}
	local below: { { Corner } } = {}
	local segments: { { Vector3 } } = {}
	for _, triangle in mesh.Triangles do
		local distances: { number } = {}
		local hasAbove = false
		local hasBelow = false
		for index, corner in triangle do
			local distance = (corner.Position - point):Dot(normal)
			if math.abs(distance) < planeEpsilon then
				distance = planeEpsilon
			end
			distances[index] = distance
			hasAbove = hasAbove or distance > 0
			hasBelow = hasBelow or distance < 0
		end
		if not hasBelow then
			table.insert(above, triangle)
			continue
		end
		if not hasAbove then
			table.insert(below, triangle)
			continue
		end
		local abovePolygon: { Corner } = {}
		local belowPolygon: { Corner } = {}
		local exitPoint: Vector3? = nil
		local enterPoint: Vector3? = nil
		for index = 1, 3 do
			local nextIndex = index % 3 + 1
			local a = triangle[index]
			local distanceA = distances[index]
			local distanceB = distances[nextIndex]
			table.insert(if distanceA > 0 then abovePolygon else belowPolygon, a)
			if (distanceA > 0) ~= (distanceB > 0) then
				local crossing = lerpCorner(a, triangle[nextIndex], distanceA / (distanceA - distanceB))
				table.insert(abovePolygon, crossing)
				table.insert(belowPolygon, crossing)
				if distanceA > 0 then
					exitPoint = crossing.Position
				else
					enterPoint = crossing.Position
				end
			end
		end
		fan(abovePolygon, above)
		fan(belowPolygon, below)
		if exitPoint and enterPoint then
			table.insert(segments, { exitPoint, enterPoint })
		end
	end
	if #above == 0 or #below == 0 then
		return nil, nil
	end
	local aboveMesh: Mesh = { Triangles = above, Winding = mesh.Winding, UvPerStud = mesh.UvPerStud }
	local belowMesh: Mesh = { Triangles = below, Winding = mesh.Winding, UvPerStud = mesh.UvPerStud }
	addCaps(aboveMesh, segments, -normal, above)
	addCaps(belowMesh, segments, normal, below)
	return aboveMesh, belowMesh
end

function MeshSlicer.Build(mesh: Mesh, template: MeshPart): MeshPart?
	local low = Vector3.one * math.huge
	local high = -Vector3.one * math.huge
	for _, triangle in mesh.Triangles do
		for _, corner in triangle do
			low = low:Min(corner.Position)
			high = high:Max(corner.Position)
		end
	end
	local center = (low + high) / 2
	while activeBuilders >= LiveSplitConfig.MaxConcurrentBuilds do
		task.wait()
	end
	activeBuilders += 1
	local builder = AssetService:CreateEditableMesh({ FixedSize = false })
	if not builder then
		activeBuilders -= 1
		warn(`[MeshSlicer] no EditableMesh budget for a piece of {template:GetFullName()}`)
		return nil
	end
	for _, triangle in mesh.Triangles do
		local a, b, c = triangle[1], triangle[2], triangle[3]
		if (b.Position - a.Position):Cross(c.Position - a.Position).Magnitude < minimumArea then
			continue
		end
		local vertices = {}
		local uvs = {}
		for index, corner in triangle do
			vertices[index] = builder:AddVertex(corner.Position - center)
			uvs[index] = builder:AddUV(corner.Uv)
		end
		local face = builder:AddTriangle(vertices[1], vertices[2], vertices[3])
		builder:SetFaceUVs(face, uvs)
	end
	local copied, copy = pcall(function()
		return AssetService:CreateEditableMeshAsync(Content.fromObject(builder), { FixedSize = true })
	end)
	builder:Destroy()
	activeBuilders -= 1
	if not copied or not copy then
		warn(`[MeshSlicer] could not copy a piece of {template:GetFullName()}: {copy}`)
		return nil
	end
	local editable = copy :: EditableMesh
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(
			Content.fromObject(editable),
			{ CollisionFidelity = Enum.CollisionFidelity.Hull }
		)
	end)
	if not ok or not result then
		warn(`[MeshSlicer] could not build a piece of {template:GetFullName()}: {result}`)
		editable:Destroy()
		return nil
	end
	local part = result :: MeshPart
	part.Name = template.Name
	part.Color = template.Color
	part.Material = template.Material
	part.MaterialVariant = template.MaterialVariant
	part.Transparency = template.Transparency
	part.Reflectance = template.Reflectance
	part.CastShadow = template.CastShadow
	part.CFrame = template.CFrame * CFrame.new(center)
	part.Destroying:Once(function()
		editable:Destroy()
	end)
	return part
end

return MeshSlicer
