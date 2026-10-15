--!strict

local RunService = game:GetService("RunService")
if not RunService:IsEdit() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local showcaseName = "RockShowcase"
local bodyProperties = { "Color", "Material", "MaterialVariant" }
local propertiesByClass: { [string]: { string } } = {
	BasePart = { "Color", "Material", "MaterialVariant", "Transparency", "Reflectance" },
	MeshPart = { "TextureID" },
	Highlight = { "Enabled", "FillColor", "FillTransparency", "OutlineColor", "OutlineTransparency" },
	Decal = { "Color3", "Transparency", "Texture" },
	SurfaceAppearance = { "Color" },
}

local connections: { RBXScriptConnection } = {}
local watchers: { RBXScriptConnection } = {}
local pending = false

local function propertiesOf(instance: Instance): { string }
	local list = {}
	for className, properties in propertiesByClass do
		if instance:IsA(className) then
			for _, property in properties do
				table.insert(list, property)
			end
		end
	end
	return list
end

local function copy(from: Instance, to: Instance, properties: { string })
	for _, property in properties do
		pcall(function()
			local value = (from :: any)[property]
			if (to :: any)[property] ~= value then
				(to :: any)[property] = value
			end
		end)
	end
end

local function mirror(from: Instance, to: Instance, properties: { string })
	if #properties == 0 then
		return
	end
	copy(from, to, properties)
	local wanted = {}
	for _, property in properties do
		wanted[property] = true
	end
	table.insert(
		connections,
		from.Changed:Connect(function(property: string)
			if wanted[property] and to.Parent then
				copy(from, to, { property })
			end
		end)
	)
end

local function pathFrom(root: Instance, descendant: Instance): { string }
	local path = {}
	local current: Instance? = descendant
	while current and current ~= root do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	return path
end

local function follow(root: Instance, path: { string }): Instance?
	local current: Instance? = root
	for _, name in path do
		current = if current then current:FindFirstChild(name) else nil
	end
	return current
end

local function pair(source: Instance, target: Instance, skip: { [Instance]: true }?)
	if not (skip and skip[target]) then
		mirror(source, target, propertiesOf(target))
	end
	for _, descendant in target:GetDescendants() do
		if skip and skip[descendant] then
			continue
		end
		local match = follow(source, pathFrom(target, descendant))
		if match and match.ClassName == descendant.ClassName then
			mirror(match, descendant, propertiesOf(descendant))
		end
	end
end

local function unbind()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function bind()
	unbind()
	local showcase = workspace:FindFirstChild(showcaseName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not showcase or not assets then
		return
	end
	for _, copyRoot in showcase:GetDescendants() do
		local sourceName = copyRoot:GetAttribute("ShowcaseSource")
		if type(sourceName) ~= "string" then
			continue
		end
		local source = assets:FindFirstChild(sourceName, true)
		if not source then
			continue
		end
		local rockName = copyRoot:GetAttribute("ShowcaseRock")
		local rock = if type(rockName) == "string" then assets:FindFirstChild(rockName, true) else nil
		if rock and rock:IsA("BasePart") then
			local bodies: { [Instance]: true } = {}
			for _, piece in copyRoot:GetChildren() do
				if piece:IsA("BasePart") then
					bodies[piece] = true
					mirror(rock, piece, bodyProperties)
				end
			end
			pair(source, copyRoot, bodies)
		else
			pair(source, copyRoot)
		end
	end
end

local function schedule()
	if pending then
		return
	end
	pending = true
	task.delay(0.5, function()
		pending = false
		bind()
	end)
end

local function watch(instance: Instance)
	table.insert(watchers, instance.DescendantAdded:Connect(schedule))
	table.insert(watchers, instance.DescendantRemoving:Connect(schedule))
end

table.insert(watchers, workspace.ChildAdded:Connect(function(child: Instance)
	if child.Name == showcaseName then
		schedule()
	end
end))
table.insert(watchers, ReplicatedStorage.ChildAdded:Connect(function(child: Instance)
	if child.Name == "Assets" then
		watch(child)
		schedule()
	end
end))
local assets = ReplicatedStorage:FindFirstChild("Assets")
if assets then
	watch(assets)
end

plugin.Unloading:Connect(function()
	unbind()
	for _, connection in watchers do
		connection:Disconnect()
	end
	table.clear(watchers)
end)

bind()
