--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Component = require(ReplicatedStorage.Packages.Component)
local LiveSplit = require(ReplicatedStorage.Utils.LiveSplit)
local SliceTestConfig = require(ReplicatedStorage.Config.SliceTestConfig)
local SplitModel = require(ReplicatedStorage.Utils.SplitModel)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Rock = {
	Root: BasePart,
	Parts: { BasePart },
	Collides: { [BasePart]: boolean },
	IsBusy: boolean,
}

type SliceTest = {
	Instance: Instance,
	Trove: any,
	DragStart: Vector2?,
}

local push: SplitModel.Push = {
	OutwardStuds = SliceTestConfig.PushStuds,
	UpStuds = SliceTestConfig.UpStuds,
	TorqueRadPerSec = 0,
}

local function findRocks(self: SliceTest): { [BasePart]: Rock }
	local rocks: { [BasePart]: Rock } = {}
	local folder = self.Instance:FindFirstChild(SliceTestConfig.RocksFolderName)
	if not folder then
		return rocks
	end
	for _, child in folder:GetChildren() do
		if not child:IsA("MeshPart") then
			continue
		end
		local parts: { BasePart } = { child }
		for _, descendant in child:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
		rocks[child] = { Root = child, Parts = parts, Collides = {}, IsBusy = false }
	end
	return rocks
end

local function setHidden(rock: Rock, isHidden: boolean)
	for _, part in rock.Parts do
		if isHidden then
			rock.Collides[part] = part.CanCollide
		end
		part.LocalTransparencyModifier = if isHidden then 1 else 0
		part.CanCollide = if isHidden then false else rock.Collides[part] == true
		part.CanQuery = not isHidden
	end
end

local function fadeOut(model: Model)
	local info = TweenInfo.new(SliceTestConfig.FadeSeconds)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			TweenService:Create(descendant, info, { Transparency = 1 }):Play()
		end
	end
	task.delay(SliceTestConfig.FadeSeconds, function()
		model:Destroy()
	end)
end

local function slice(rock: Rock, point: Vector3, normal: Vector3)
	rock.IsBusy = true
	local started = os.clock()
	local prepared = LiveSplit.Prepare(rock.Root, point, normal)
	LiveSplit.Wait(prepared)
	local model = LiveSplit.Spawn(prepared, push)
	if not model then
		rock.IsBusy = false
		return
	end
	print(`[SliceTest] {rock.Root.Name} sliced in {math.round((os.clock() - started) * 1000)} ms`)
	setHidden(rock, true)
	task.wait(SliceTestConfig.ResetSeconds)
	fadeOut(model)
	task.wait(SliceTestConfig.FadeSeconds)
	setHidden(rock, false)
	rock.IsBusy = false
end

local function onDragEnded(self: SliceTest, rocks: { [BasePart]: Rock }, finish: Vector2)
	local start = self.DragStart
	self.DragStart = nil
	local camera = workspace.CurrentCamera
	if not start or not camera or (finish - start).Magnitude < SliceTestConfig.MinDragPixels then
		return
	end
	local startRay = camera:ScreenPointToRay(start.X, start.Y)
	local finishRay = camera:ScreenPointToRay(finish.X, finish.Y)
	local cross = startRay.Direction:Cross(finishRay.Direction)
	if cross.Magnitude < 1e-6 then
		return
	end
	local include: { Instance } = {}
	for _, rock in rocks do
		if not rock.IsBusy then
			table.insert(include, rock.Root)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = include
	local hits: { [BasePart]: boolean } = {}
	for sample = 0, SliceTestConfig.RaySamples do
		local screenPoint = start:Lerp(finish, sample / SliceTestConfig.RaySamples)
		local ray = camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * SliceTestConfig.RayLengthStuds, params)
		local hit = if result then result.Instance else nil
		if hit and hit:IsA("BasePart") and rocks[hit] then
			hits[hit] = true
		end
	end
	for root in hits do
		task.spawn(slice, rocks[root], startRay.Origin, cross.Unit)
	end
end

return function(_controllers: { [string]: any })
	local SliceTest = Component.new({ Tag = SliceTestConfig.Tag }) :: any

	function SliceTest.Construct(self: SliceTest)
		self.Trove = Trove.new()
	end

	function SliceTest.Start(self: SliceTest)
		local rocks = findRocks(self)
		for root in rocks do
			LiveSplit.Preload(root)
		end
		self.Trove:Connect(UserInputService.InputBegan, function(input: InputObject, isProcessed: boolean)
			if isProcessed then
				return
			end
			local inputType = input.UserInputType
			if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
				self.DragStart = Vector2.new(input.Position.X, input.Position.Y)
			end
		end)
		self.Trove:Connect(UserInputService.InputEnded, function(input: InputObject)
			local inputType = input.UserInputType
			if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
				onDragEnded(self, rocks, Vector2.new(input.Position.X, input.Position.Y))
			end
		end)
	end

	function SliceTest.Stop(self: SliceTest)
		self.Trove:Destroy()
	end

	return SliceTest
end
