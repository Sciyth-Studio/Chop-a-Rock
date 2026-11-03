--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)

local Tools = {}

local function build(geodeKey: string): Tool?
	local geode = GeodeConfig.Geodes[geodeKey]
	local asset = AssetRegistry.get(geode.ModelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[GeodeService] {geode.ModelKey} needs to be a Model to become a tool`)
		return nil
	end
	local model = asset :: Model
	local handle = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not handle then
		model:Destroy()
		return nil
	end
	model:ScaleTo(model:GetScale() * GeodeConfig.ToolScale)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			if part ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = handle
			end
		end
	end
	handle.Name = "Handle"
	local tool = Instance.new("Tool")
	tool.Name = geode.DisplayName
	tool.CanBeDropped = false
	tool.Grip = GeodeConfig.ToolGrip
	tool:SetAttribute(GeodeConfig.ToolKeyAttribute, geodeKey)
	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()
	return tool
end

function Tools.Held(player: Player): string?
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	local key = if tool then tool:GetAttribute(GeodeConfig.ToolKeyAttribute) else nil
	return if type(key) == "string" then key else nil
end

function Tools.Sync(player: Player, geodes: { [string]: number })
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local kept: { [string]: boolean } = {}
	local containers: { Instance? } = { player.Character, backpack }
	for _, container in containers do
		if not container then
			continue
		end
		for _, child in container:GetChildren() do
			local key = child:GetAttribute(GeodeConfig.ToolKeyAttribute)
			if not child:IsA("Tool") or type(key) ~= "string" then
				continue
			end
			if kept[key] or (geodes[key] or 0) <= 0 then
				child:Destroy()
			else
				kept[key] = true
			end
		end
	end
	for key, count in geodes do
		if count > 0 and not kept[key] and GeodeConfig.Geodes[key] then
			local tool = build(key)
			if tool then
				tool.Parent = backpack
			end
		end
	end
end

return Tools
