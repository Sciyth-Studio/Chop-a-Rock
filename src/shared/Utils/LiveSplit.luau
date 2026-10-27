--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeshSlicer = require(ReplicatedStorage.Utils.MeshSlicer)
local SplitModel = require(ReplicatedStorage.Utils.SplitModel)

export type Prepared = {
	Part: BasePart,
	Normal: Vector3,
	Model: Model?,
	Roots: { BasePart },
	IsDone: boolean,
	IsDiscarded: boolean,
	Done: { thread },
}

type Half = {
	Root: BasePart?,
	Props: { BasePart },
}

local cache: { [string]: MeshSlicer.Mesh | false } = {}
local loading: { [string]: { thread } } = {}

local LiveSplit = {}

local function load(meshId: string): MeshSlicer.Mesh?
	local cached = cache[meshId]
	if cached == nil then
		local waiting = loading[meshId]
		if waiting then
			table.insert(waiting, coroutine.running())
			coroutine.yield()
		else
			loading[meshId] = {}
			cache[meshId] = MeshSlicer.Read(meshId) or false
			local threads = loading[meshId]
			loading[meshId] = nil
			for _, thread in threads do
				task.spawn(thread)
			end
		end
		cached = cache[meshId]
	end
	return if cached then cached :: MeshSlicer.Mesh else nil
end

local function partsOf(part: BasePart): { BasePart }
	local parts = { part }
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function cut(part: BasePart, point: Vector3, normal: Vector3): (BasePart?, BasePart?)
	if not part:IsA("MeshPart") then
		return nil, nil
	end
	local mesh = load(part.MeshId)
	if not mesh then
		return nil, nil
	end
	local scaled = MeshSlicer.Scale(mesh, part.Size / part.MeshSize)
	local above, below = MeshSlicer.Split(
		scaled,
		part.CFrame:PointToObjectSpace(point),
		part.CFrame:VectorToObjectSpace(normal)
	)
	if not above or not below then
		return nil, nil
	end
	return MeshSlicer.Build(above, part), MeshSlicer.Build(below, part)
end

local function addProp(half: Half, prop: BasePart)
	prop.Anchored = false
	prop.CanCollide = false
	prop.CanQuery = false
	prop.Massless = true
	table.insert(half.Props, prop)
end

local function cutPart(
	part: BasePart,
	root: BasePart,
	point: Vector3,
	normal: Vector3,
	above: Half,
	below: Half
)
	local abovePiece, belowPiece = cut(part, point, normal)
	if part == root then
		above.Root = abovePiece
		below.Root = belowPiece
		return
	end
	if abovePiece and belowPiece then
		addProp(above, abovePiece)
		addProp(below, belowPiece)
		return
	end
	if abovePiece then
		abovePiece:Destroy()
	end
	if belowPiece then
		belowPiece:Destroy()
	end
	local copy = part:Clone()
	copy:ClearAllChildren()
	copy.LocalTransparencyModifier = 0
	addProp(if (part.Position - point):Dot(normal) > 0 then above else below, copy)
end

local function assemble(half: Half, model: Model): BasePart?
	local root = half.Root
	if not root then
		return nil
	end
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = false
	root.Parent = model
	for _, prop in half.Props do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = prop
		weld.Parent = prop
		prop.Parent = root
	end
	return root
end

local function discardHalf(half: Half)
	if half.Root then
		half.Root:Destroy()
	end
	for _, prop in half.Props do
		prop:Destroy()
	end
end

local function finish(prepared: Prepared)
	prepared.IsDone = true
	local threads = prepared.Done
	prepared.Done = {}
	for _, thread in threads do
		task.spawn(thread)
	end
end

local function build(prepared: Prepared, point: Vector3)
	local part = prepared.Part
	local above: Half = { Props = {} }
	local below: Half = { Props = {} }
	local parts = partsOf(part)
	local pending = #parts
	local thread = coroutine.running()
	for _, piece in parts do
		task.spawn(function()
			cutPart(piece, part, point, prepared.Normal, above, below)
			pending -= 1
			if pending == 0 and coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end)
	end
	if pending > 0 then
		coroutine.yield()
	end
	if prepared.IsDiscarded or not above.Root or not below.Root then
		discardHalf(above)
		discardHalf(below)
		finish(prepared)
		return
	end
	local model = Instance.new("Model")
	model.Name = `{part.Name}_LiveSplit`
	model.WorldPivot = part.CFrame
	for _, half in { above, below } do
		local root = assemble(half, model)
		if root then
			table.insert(prepared.Roots, root)
		end
	end
	prepared.Model = model
	finish(prepared)
end

function LiveSplit.Preload(part: BasePart)
	for _, piece in partsOf(part) do
		if piece:IsA("MeshPart") and cache[piece.MeshId] == nil and not loading[piece.MeshId] then
			task.spawn(load, piece.MeshId)
		end
	end
end

function LiveSplit.Prepare(part: BasePart, point: Vector3, normal: Vector3): Prepared
	local prepared: Prepared = {
		Part = part,
		Normal = normal.Unit,
		Model = nil,
		Roots = {},
		IsDone = false,
		IsDiscarded = false,
		Done = {},
	}
	task.spawn(build, prepared, point)
	return prepared
end

function LiveSplit.Wait(prepared: Prepared)
	if not prepared.IsDone then
		table.insert(prepared.Done, coroutine.running())
		coroutine.yield()
	end
end

function LiveSplit.Spawn(prepared: Prepared, push: SplitModel.Push): Model?
	local model = prepared.Model
	if not model or prepared.IsDiscarded then
		return nil
	end
	prepared.Model = nil
	prepared.IsDiscarded = true
	model:PivotTo(prepared.Part.CFrame)
	model.Parent = workspace
	local up = Vector3.yAxis
	for index, root in prepared.Roots do
		local direction = if index == 1 then prepared.Normal else -prepared.Normal
		root.Anchored = false
		root.AssemblyLinearVelocity = direction * push.OutwardStuds + up * push.UpStuds
		root.AssemblyAngularVelocity = up:Cross(direction) * push.TorqueRadPerSec
	end
	return model
end

function LiveSplit.Discard(prepared: Prepared)
	prepared.IsDiscarded = true
	local model = prepared.Model
	prepared.Model = nil
	if model then
		model:Destroy()
	end
end

return LiveSplit
