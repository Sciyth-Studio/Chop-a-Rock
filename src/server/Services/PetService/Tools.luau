--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)

local PET_ID_ATTRIBUTE = "PetId"

local Tools = {}

local function build(id: string, pet: PetConfig.Pet): Tool?
	local asset = AssetRegistry.get(pet.ModelKey)
	if not asset:IsA("Model") or not asset.PrimaryPart then
		warn(`[PetService] {pet.ModelKey} needs to be a Model with a PrimaryPart to become a tool`)
		asset:Destroy()
		return nil
	end
	local model = asset :: Model
	model:ScaleTo(PetConfig.ToolScale)
	local handle = model.PrimaryPart :: BasePart
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
	tool.Name = pet.DisplayName
	tool.ToolTip = `${NumberFormat.Commas(pet.MoneyPerSecond)}/s`
	tool.CanBeDropped = false
	tool.Grip = PetConfig.ToolGrip
	tool:SetAttribute(PET_ID_ATTRIBUTE, id)
	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()
	return tool
end

local function owned(player: Player): { [string]: { Tool } }
	local found: { [string]: { Tool } } = {}
	local containers: { Instance? } = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in containers do
		if not container then
			continue
		end
		for _, child in container:GetChildren() do
			local id = child:GetAttribute(PET_ID_ATTRIBUTE)
			if child:IsA("Tool") and type(id) == "string" then
				found[id] = found[id] or {}
				table.insert(found[id], child)
			end
		end
	end
	return found
end

function Tools.PetIdOf(tool: Instance): string?
	local id = tool:GetAttribute(PET_ID_ATTRIBUTE)
	return if tool:IsA("Tool") and type(id) == "string" then id else nil
end

function Tools.Held(player: Player): string?
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return if tool then Tools.PetIdOf(tool) else nil
end

function Tools.Sync(player: Player, pets: { [string]: any })
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local existing = owned(player)
	for id, tools in existing do
		local pet = pets[id]
		local keep = pet ~= nil and pet.Slot == nil and PetConfig.Pets[pet.Key] ~= nil
		for index, tool in tools do
			if not keep or index > 1 then
				tool:Destroy()
			end
		end
	end
	local missing: { string } = {}
	for id, pet in pets do
		if pet.Slot == nil and PetConfig.Pets[pet.Key] and not existing[id] then
			table.insert(missing, id)
		end
	end
	table.sort(missing, function(a: string, b: string)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	for _, id in missing do
		local tool = build(id, PetConfig.Pets[pets[id].Key])
		if tool then
			tool.Parent = backpack
		end
	end
end

function Tools.PutAway(player: Player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid:UnequipTools()
	end
end

return Tools
