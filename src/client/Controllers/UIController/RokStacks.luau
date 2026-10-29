--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RokModifier = require(ReplicatedStorage.RokModifier)
local RokSize = require(ReplicatedStorage.RokSize)
local RoksConfig = require(ReplicatedStorage.Config.RoksConfig)
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
}

local PET_ID_ATTRIBUTE = "PetId"

local RokStacks = {}

function RokStacks.Build(pets: { [string]: any }): { Stack }
	local byId: { [string]: Stack } = {}
	local stacks: { Stack } = {}
	for petId, record in pets do
		if type(record) ~= "table" or not PetConfig.Pets[record.Key] then
			continue
		end
		local rate = RokModifier.Rate(record.Key, record.Modifier, record.Income)
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
				Name = RokModifier.Name(record.Key, record.Modifier),
				FullName = RokSize.Name(record.Key, record.Modifier, record.Size),
				IsPlaced = isPlaced,
				PetIds = {},
				Slots = {},
			}
			byId[id] = created
			table.insert(stacks, created)
			stack = created
		end
		table.insert(stack.PetIds, petId)
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

function RokStacks.PetIdOf(tool: Instance): string?
	local id = tool:GetAttribute(PET_ID_ATTRIBUTE)
	return if tool:IsA("Tool") and type(id) == "string" then id else nil
end

function RokStacks.HeldPetId(player: Player): string?
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return if tool then RokStacks.PetIdOf(tool) else nil
end

function RokStacks.Contains(stack: Stack, petId: string?): boolean
	return petId ~= nil and table.find(stack.PetIds, petId) ~= nil
end

function RokStacks.ToolFor(player: Player, stack: Stack): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return nil
	end
	local tools: { [string]: Tool } = {}
	for _, child in backpack:GetChildren() do
		local id = RokStacks.PetIdOf(child)
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

function RokStacks.Toggle(player: Player, stack: Stack)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		return
	end
	if RokStacks.Contains(stack, RokStacks.HeldPetId(player)) then
		humanoid:UnequipTools()
		return
	end
	local tool = RokStacks.ToolFor(player, stack)
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
	RokModifier.Tint(model, modifier)
	local settings = RoksConfig.Preview
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

function RokStacks.Paint(frame: GuiObject, stack: Stack?)
	local icon = frame:FindFirstChild("Icon")
	local preview = frame:FindFirstChild("Preview")
	local sizeTag = label(frame, "SizeTag")
	local count = label(frame, "Count")
	local nameLabel = label(frame, "RokName")
	local rateLabel = label(frame, "Rate")
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
	local pet = PetConfig.Pets[stack.Key]
	local shown = ItemIcons.Apply(frame, "Pet", stack.Key, function(viewport)
		viewport:ClearAllChildren()
		buildPreview(viewport, pet.ModelKey, stack.Modifier)
	end)
	ItemIcons.Tint(shown, RokModifier.ImageTint(stack.Modifier))
	if sizeTag then
		sizeTag.Visible = RokSize.IsShown(stack.Size)
		if sizeTag.Visible then
			sizeTag.Text = RokSize.Get(stack.Size).DisplayName
		end
	end
	if count then
		count.Visible = #stack.PetIds > 1
		count.Text = tostring(#stack.PetIds)
	end
	if nameLabel then
		nameLabel.Visible = true
		nameLabel.Text = stack.Name
		local styleName = nameLabel:GetAttribute(TextStyleConfig.AttributeName)
		if RokModifier.Get(stack.Modifier) then
			RokModifier.PaintLabel(nameLabel, stack.Modifier)
		elseif type(styleName) == "string" then
			Typography.ApplyTextStyle(nameLabel, styleName)
		end
	end
	if rateLabel then
		rateLabel.Visible = true
		rateLabel.Text = `${NumberFormat.Rate(stack.Rate)}/s`
	end
end

function RokStacks.PaintStroke(frame: GuiObject, isHeld: boolean, isPlaced: boolean)
	local stroke = frame:FindFirstChild("OuterStroke")
	if not stroke or not stroke:IsA("UIStroke") then
		return
	end
	local style = if isHeld
		then ToolbarConfig.HeldStroke
		elseif isPlaced then ToolbarConfig.PlacedStroke
		else ToolbarConfig.IdleStroke
	stroke.Color = style.Color
	stroke.Thickness = style.Thickness
end

return RokStacks
