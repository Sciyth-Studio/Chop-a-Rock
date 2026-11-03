--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetModifier = require(ReplicatedStorage.PetModifier)
local PetSize = require(ReplicatedStorage.PetSize)
local PetsConfig = require(ReplicatedStorage.Config.PetsConfig)
local TextStyleConfig = require(ReplicatedStorage.Config.TextStyleConfig)
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)

export type Stack = {
	Id: string,
	Key: string,
	Modifier: string?,
	Size: string?,
	Rate: number,
	Name: string,
	FullName: string,
	IsPlaced: boolean,
	PetIds: { string },
	Slots: { number },
	GeodeKey: string?,
	Count: number,
}

local PET_ID_ATTRIBUTE = "PetId"

local PetStacks = {}

function PetStacks.Build(pets: { [string]: any }): { Stack }
	local byId: { [string]: Stack } = {}
	local stacks: { Stack } = {}
	for petId, record in pets do
		if type(record) ~= "table" or not PetConfig.Pets[record.Key] then
			continue
		end
		local rate = PetModifier.Rate(record.Key, record.Modifier, record.Income)
		local isPlaced = record.Slot ~= nil
		local id =
			`{if isPlaced then "P" else "B"}|{record.Key}|{record.Modifier or ""}|{record.Size or ""}|{rate}`
		local stack = byId[id]
		if not stack then
			local created: Stack = {
				Id = id,
				Key = record.Key,
				Modifier = record.Modifier,
				Size = record.Size,
				Rate = rate,
				Name = PetModifier.Name(record.Key, record.Modifier),
				FullName = PetSize.Name(record.Key, record.Modifier, record.Size),
				IsPlaced = isPlaced,
				PetIds = {},
				Slots = {},
				Count = 0,
			}
			byId[id] = created
			table.insert(stacks, created)
			stack = created
		end
		table.insert(stack.PetIds, petId)
		stack.Count += 1
		if isPlaced then
			table.insert(stack.Slots, record.Slot)
		end
	end
	for _, stack in stacks do
		table.sort(stack.PetIds, function(a: string, b: string)
			return (tonumber(a) or 0) < (tonumber(b) or 0)
		end)
	end
	table.sort(stacks, function(a: Stack, b: Stack)
		if a.Rate ~= b.Rate then
			return a.Rate > b.Rate
		end
		if a.IsPlaced ~= b.IsPlaced then
			return a.IsPlaced
		end
		return a.Id < b.Id
	end)
	return stacks
end

function PetStacks.BuildGeodes(geodes: { [string]: number }): { Stack }
	local stacks: { Stack } = {}
	for _, key in GeodeOrder.All() do
		local count = geodes[key] or 0
		if count <= 0 then
			continue
		end
		local geode = GeodeConfig.Geodes[key]
		table.insert(stacks, {
			Id = `G|{key}`,
			Key = key,
			Rate = 0,
			Name = geode.ShortName or geode.DisplayName,
			FullName = geode.DisplayName,
			IsPlaced = false,
			PetIds = {},
			Slots = {},
			GeodeKey = key,
			Count = count,
		})
	end
	return stacks
end

function PetStacks.HatchText(geodeKey: string): string
	local seconds = GeodeConfig.Geodes[geodeKey].HatchSeconds
	if seconds <= 0 then
		return ToolbarConfig.HatchNowText
	end
	local amount = if seconds < 60 then `{seconds}s` else `{math.floor(seconds / 60)}m`
	return string.format(ToolbarConfig.HatchTimeFormat, amount)
end

function PetStacks.PetIdOf(tool: Instance): string?
	local id = tool:GetAttribute(PET_ID_ATTRIBUTE)
	return if tool:IsA("Tool") and type(id) == "string" then id else nil
end

function PetStacks.HeldPetId(player: Player): string?
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return if tool then PetStacks.PetIdOf(tool) else nil
end

function PetStacks.Contains(stack: Stack, petId: string?): boolean
	return petId ~= nil and table.find(stack.PetIds, petId) ~= nil
end

local function geodeKeyOf(tool: Instance): string?
	local key = tool:GetAttribute(GeodeConfig.ToolKeyAttribute)
	return if tool:IsA("Tool") and type(key) == "string" then key else nil
end

function PetStacks.IsHeld(player: Player, stack: Stack): boolean
	if not stack.GeodeKey then
		return PetStacks.Contains(stack, PetStacks.HeldPetId(player))
	end
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return tool ~= nil and geodeKeyOf(tool) == stack.GeodeKey
end

function PetStacks.ToolFor(player: Player, stack: Stack): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return nil
	end
	if stack.GeodeKey then
		for _, child in backpack:GetChildren() do
			if geodeKeyOf(child) == stack.GeodeKey then
				return child :: Tool
			end
		end
		return nil
	end
	local tools: { [string]: Tool } = {}
	for _, child in backpack:GetChildren() do
		local id = PetStacks.PetIdOf(child)
		if id then
			tools[id] = child :: Tool
		end
	end
	for _, petId in stack.PetIds do
		if tools[petId] then
			return tools[petId]
		end
	end
	return nil
end

function PetStacks.Toggle(player: Player, stack: Stack)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		return
	end
	if PetStacks.IsHeld(player, stack) then
		humanoid:UnequipTools()
		return
	end
	local tool = PetStacks.ToolFor(player, stack)
	if tool then
		humanoid:EquipTool(tool)
	end
end

local function buildPreview(frame: ViewportFrame, modelKey: string, modifier: string?)
	local model = AssetRegistry.get(modelKey)
	if not model:IsA("Model") then
		model:Destroy()
		return
	end
	PetModifier.Tint(model, modifier)
	local settings = PetsConfig.Preview
	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.FieldOfView
	camera.Parent = frame
	model.Parent = frame
	local center, size = model:GetBoundingBox()
	local distance = size.Magnitude / 2 / math.tan(math.rad(camera.FieldOfView / 2)) * settings.CameraPadding
	camera.CFrame = CFrame.lookAt(center.Position + settings.CameraDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
end

local function label(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

function PetStacks.Paint(frame: GuiObject, stack: Stack?)
	local icon = frame:FindFirstChild("Icon")
	local preview = frame:FindFirstChild("Preview")
	local sizeTag = label(frame, "SizeTag")
	local count = label(frame, "Count")
	local nameLabel = label(frame, "PetName")
	local rateLabel = label(frame, "Rate")
	local nameShadow = label(frame, "PetNameShadow")
	if nameShadow then
		nameShadow.Visible = stack ~= nil
		nameShadow.Text = if stack then stack.Name else ""
	end
	if not stack then
		if icon and icon:IsA("ImageLabel") then
			icon.Visible = false
		end
		if preview and preview:IsA("ViewportFrame") then
			preview.Visible = false
			preview:ClearAllChildren()
		end
		for _, part in { sizeTag, count, nameLabel, rateLabel } do
			if part then
				part.Visible = false
			end
		end
		return
	end
	local geode = if stack.GeodeKey then GeodeConfig.Geodes[stack.GeodeKey] else nil
	local modelKey = if geode then geode.ModelKey else PetConfig.Pets[stack.Key].ModelKey
	local shown = ItemIcons.Apply(frame, if geode then "Geode" else "Pet", stack.Key, function(viewport)
		viewport:ClearAllChildren()
		buildPreview(viewport, modelKey, stack.Modifier)
	end)
	ItemIcons.Tint(shown, PetModifier.ImageTint(stack.Modifier))
	if sizeTag then
		sizeTag.Visible = PetSize.IsShown(stack.Size)
		if sizeTag.Visible then
			sizeTag.Text = PetSize.Get(stack.Size).DisplayName
		end
	end
	if count then
		count.Visible = stack.Count > 1
		count.Text = tostring(stack.Count)
	end
	if nameLabel then
		nameLabel.Visible = true
		nameLabel.Text = stack.Name
		local styleName = nameLabel:GetAttribute(TextStyleConfig.AttributeName)
		if PetModifier.Get(stack.Modifier) then
			PetModifier.PaintLabel(nameLabel, stack.Modifier)
		elseif type(styleName) == "string" then
			Typography.ApplyTextStyle(nameLabel, styleName)
		end
	end
	if rateLabel then
		rateLabel.Visible = true
		rateLabel.Text = if stack.GeodeKey
			then PetStacks.HatchText(stack.GeodeKey)
			else `${NumberFormat.Rate(stack.Rate)}/s`
	end
end

function PetStacks.PaintStroke(frame: GuiObject, isHeld: boolean)
	local stroke = frame:FindFirstChild("OuterStroke")
	if not stroke or not stroke:IsA("UIStroke") then
		return
	end
	local style = if isHeld then ToolbarConfig.HeldStroke else ToolbarConfig.IdleStroke
	stroke.Color = style.Color
	stroke.Thickness = style.Thickness
end

return PetStacks
