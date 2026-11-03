--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local CannonShop = {}

type Row = {
	Cannon: CannonConfig.Cannon,
	Button: TextButton,
	Label: TextLabel?,
	Fill: Instance?,
	PriceIcon: GuiObject?,
	Check: GuiObject?,
	Stroke: UIStroke?,
}

local function find(root: Instance, name: string, className: string, recursive: boolean): any
	local found = root:FindFirstChild(name, recursive)
	if found and found:IsA(className) then
		return found
	end
	warn(`[CannonShop] Missing {className} "{name}" in {root:GetFullName()}`)
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

function CannonShop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local rows: { Row } = {}
	local isBusy = false

	local list: GuiObject? = find(gui, "List", "GuiObject", true)
	local template: Frame? = find(gui, "RowTemplate", "Frame", true)
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton", true)
	local cashLabel: TextLabel? = find(gui, "CashLabel", "TextLabel", true)

	if template then
		template.Visible = false
	end

	if cashLabel then
		cashLabel.Visible = false
	end

	local function isOwned(key: string): boolean
		return dataController:Get({ "Cannons", key }) == true
	end

	local function equipped(): string
		local value = dataController:Get({ "EquippedCannon" })
		return if type(value) == "string" then value else ""
	end

	local function present(row: Row, text: string, colors: ShopConfig.MeterColors)
		setText(row.Label, text)
		BlockButton.Paint(row.Fill, colors)
		if row.PriceIcon then
			row.PriceIcon.Visible = false
		end
		local label = row.Label
		if label then
			BlockButton.PlaceLabel(label, ShopConfig.PriceLabel.WithoutIcon)
		end
	end

	local function refresh()
		local equippedKey = equipped()
		for _, row in rows do
			local cannon = row.Cannon
			local owned = isOwned(cannon.Key)
			if row.Check then
				row.Check.Visible = owned
			end
			if row.Stroke then
				row.Stroke.Color = if cannon.Key == equippedKey
					then CannonConfig.Shop.EquippedOutline
					else CannonConfig.Shop.Outline
			end
			if owned and cannon.Key == equippedKey then
				present(row, "Equipped", CannonConfig.Shop.EquippedButton)
			elseif owned then
				present(row, "Equip", CannonConfig.Shop.EquipButton)
			else
				present(
					row,
					`{NumberFormat.Compact(cannon.StrengthRequired)} Strength`,
					ShopConfig.Palette.Grey
				)
			end
		end
	end

	local function request(button: TextButton, cannon: CannonConfig.Cannon)
		if isBusy or cannon.Key == equipped() then
			return
		end
		if not isOwned(cannon.Key) then
			context.Feedback(button, false)
			return
		end
		isBusy = true
		task.spawn(function()
			local isDone = Packets.EquipCannon:Fire(cannon.Key) == true
			isBusy = false
			context.Feedback(button, isDone)
		end)
	end

	if list and template then
		for index, cannon in CannonConfig.Cannons do
			local row = template:Clone()
			row.Name = `Cannon{cannon.Key}`
			row.LayoutOrder = index
			row.Visible = true
			row.BackgroundColor3 = cannon.Color
			local preview: GuiObject? = find(row, "Preview", "GuiObject", false)
			local icon: ImageLabel? = if preview then find(preview, "Icon", "ImageLabel", false) else nil
			local button: TextButton? = find(row, "BuyButton", "TextButton", true)
			setText(find(row, "TierName", "TextLabel", false), cannon.DisplayName)
			setText(find(row, "TierInfo", "TextLabel", false), `Tier {index}`)
			setText(find(row, "ZoneNumber", "TextLabel", true), `Zone {cannon.ZoneNumber}`)
			setText(find(row, "ZoneName", "TextLabel", true), cannon.ZoneName)
			if icon then
				icon.ImageColor3 = cannon.Color
			end
			if button then
				trove:Add(button.Activated:Connect(function()
					request(button, cannon)
				end))
				local priceIcon = button:FindFirstChild("PriceIcon")
				local check = row:FindFirstChild("Check", true)
				table.insert(rows, {
					Cannon = cannon,
					Button = button,
					Label = find(button, "Label", "TextLabel", false),
					Fill = button:FindFirstChild("Fill", true),
					PriceIcon = if priceIcon and priceIcon:IsA("GuiObject") then priceIcon else nil,
					Check = if check and check:IsA("GuiObject") then check else nil,
					Stroke = row:FindFirstChildOfClass("UIStroke"),
				})
			end
			row.Parent = list
		end
	end

	if closeButton then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close(CannonConfig.ScreenName)
		end))
	end

	for _, key in { "Cannons", "EquippedCannon" } do
		trove:Add(dataController:Observe({ key }, refresh))
	end
	refresh()

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			refresh()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return CannonShop
