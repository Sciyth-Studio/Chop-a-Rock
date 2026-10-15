--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RokModifier = require(ReplicatedStorage.RokModifier)
local RoksConfig = require(ReplicatedStorage.Config.RoksConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local Roks = {}

local function find(root: Instance, name: string, className: string, recursive: boolean): any
	local found = root:FindFirstChild(name, recursive)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Roks] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

local function paint(fill: Instance?, colors: ShopConfig.MeterColors)
	if not fill then
		return
	end
	local gradient = fill:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors.Edge),
			ColorSequenceKeypoint.new(0.5, colors.Center),
			ColorSequenceKeypoint.new(1, colors.Edge),
		})
	end
	local studs = fill:FindFirstChild("StudTexture")
	if studs and studs:IsA("ImageLabel") then
		studs.ImageColor3 = colors.Studs
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

function Roks.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local rowTrove = trove:Extend()

	local title: TextLabel? = find(gui, "Title", "TextLabel", true)
	local list: GuiObject? = find(gui, "List", "GuiObject", true)
	local template: Frame? = find(gui, "RowTemplate", "Frame", true)
	local emptyLabel: TextLabel? = find(gui, "EmptyLabel", "TextLabel", true)
	local slotButton: TextButton? = find(gui, "SlotButton", "TextButton", true)
	local slotLabel: TextLabel? = if slotButton then find(slotButton, "Label", "TextLabel", true) else nil
	local slotFill = if slotButton then slotButton:FindFirstChild("Fill", true) else nil
	local equipBestButton: TextButton? = find(gui, "EquipBestButton", "TextButton", true)
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton", true)

	if template then
		template.Visible = false
	end

	local isBusy = false
	local function request(packet: any, ...: any)
		if isBusy then
			return
		end
		isBusy = true
		local arguments = table.pack(...)
		task.spawn(function()
			local ok = packet:Fire(table.unpack(arguments, 1, arguments.n))
			isBusy = false
			if ok == true and packet == Packets.BuyPedestalSlot then
				LocalSound.Play("SFX_Money_Gain")
			end
		end)
	end

	local function refreshSlotButton()
		local slotCount = dataController:Get({ "PedestalSlots" })
		local cash = dataController:Get({ "Cash" })
		local price: number? = nil
		if type(slotCount) == "number" then
			local _, nextPrice = PedestalSlots.Next(slotCount)
			price = nextPrice
		end
		if slotButton then
			slotButton.Visible = price ~= nil
		end
		if price then
			setText(slotLabel, `+1 Slot ${NumberFormat.Compact(price)}`)
			local canAfford = type(cash) == "number" and cash >= price
			paint(
				slotFill,
				if canAfford then RoksConfig.Palette.Affordable else RoksConfig.Palette.Unavailable
			)
		end
	end

	local function refresh()
		local pets = dataController:Get({ "Pets" })
		local slotCount = dataController:Get({ "PedestalSlots" })
		if type(pets) ~= "table" or type(slotCount) ~= "number" then
			return
		end
		local placed = PedestalSlots.Placed(pets)
		local unlocked = PedestalSlots.Unlocked(slotCount)
		local placedCount = 0
		for _, slot in unlocked do
			if placed[slot] then
				placedCount += 1
			end
		end
		setText(title, `{placedCount}/{#unlocked} Placed`)

		refreshSlotButton()

		rowTrove:Clean()
		if emptyLabel then
			emptyLabel.Visible = placedCount == 0
		end
		if not list or not template then
			return
		end
		for order, slot in PedestalConfig.UnlockOrder do
			local petId = placed[slot]
			local pet = if petId then PetConfig.Pets[pets[petId].Key] else nil
			if not pet then
				continue
			end
			local row = template:Clone()
			row.Name = `Slot{slot}`
			row.LayoutOrder = order
			row.Visible = true
			local record = pets[petId :: string]
			local modifier = RokModifier.Get(record.Modifier)
			local nameLabel: TextLabel? = find(row, "RokName", "TextLabel", true)
			setText(
				nameLabel,
				`{RokModifier.Name(record.Key, record.Modifier)} (${NumberFormat.Rate(
					RokModifier.Rate(record.Key, record.Modifier)
				)}/s)`
			)
			if nameLabel and modifier then
				nameLabel.TextColor3 = modifier.Color
			end
			local preview: ViewportFrame? = find(row, "Preview", "ViewportFrame", true)
			if preview then
				buildPreview(preview, pet.ModelKey, record.Modifier)
			end
			local unequip: TextButton? = find(row, "UnequipButton", "TextButton", true)
			if unequip then
				rowTrove:Connect(unequip.Activated, function()
					request(Packets.UnequipPet, slot)
				end)
			end
			row.Parent = list
			rowTrove:Add(row)
		end
	end

	if slotButton then
		trove:Connect(slotButton.Activated, function()
			request(Packets.BuyPedestalSlot)
		end)
	end
	if equipBestButton then
		trove:Connect(equipBestButton.Activated, function()
			request(Packets.EquipBestPets)
		end)
	end
	if closeButton then
		trove:Connect(closeButton.Activated, function()
			context.Close("Roks")
		end)
	end

	local isOpen = false
	trove:Add(dataController:Observe({ "Cash" }, function()
		if isOpen then
			refreshSlotButton()
		end
	end))
	for _, path in { { "Pets" }, { "PedestalSlots" } } do
		trove:Add(dataController:Observe(path, function()
			if isOpen then
				refresh()
			end
		end))
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			refresh()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Roks
