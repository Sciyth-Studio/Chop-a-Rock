--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
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
	Glow: GuiObject?,
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

	if template then
		template.Visible = false
	end

	local function readNumber(key: string): number
		local value = dataController:Get({ key })
		return if type(value) == "number" then value else 0
	end

	local function isOwned(key: string): boolean
		return dataController:Get({ "Cannons", key }) == true
	end

	local function equipped(): string
		local value = dataController:Get({ "EquippedCannon" })
		return if type(value) == "string" then value else ""
	end

	local function present(row: Row, text: string, colors: ShopConfig.MeterColors, showPrice: boolean)
		setText(row.Label, text)
		BlockButton.Paint(row.Fill, colors)
		if row.PriceIcon then
			row.PriceIcon.Visible = showPrice
		end
		local label = row.Label
		if label then
			BlockButton.PlaceLabel(
				label,
				if showPrice then ShopConfig.PriceLabel.WithIcon else ShopConfig.PriceLabel.WithoutIcon
			)
		end
	end

	local function refresh()
		local cash = readNumber("Cash")
		local strength = readNumber("Strength")
		local equippedKey = equipped()
		for _, row in rows do
			local cannon = row.Cannon
			local isEquipped = cannon.Key == equippedKey
			local canBuy = not isOwned(cannon.Key)
				and strength >= cannon.StrengthRequired
				and cash >= cannon.Price
			if row.Glow then
				row.Glow.Visible = isEquipped
			end
			row.Button:SetAttribute("Shimmer", canBuy)
			if isEquipped then
				present(row, "Unequip", ShopConfig.Palette.Orange, false)
			elseif isOwned(cannon.Key) then
				present(row, "Equip", ShopConfig.Palette.Orange, false)
			elseif strength < cannon.StrengthRequired then
				present(
					row,
					`{NumberFormat.Compact(cannon.StrengthRequired)} Strength`,
					ShopConfig.Palette.Grey,
					false
				)
			else
				local colors = if canBuy then ShopConfig.Palette.Green else ShopConfig.Palette.Grey
				present(row, NumberFormat.Compact(cannon.Price), colors, true)
			end
		end
	end

	local function request(button: TextButton, cannon: CannonConfig.Cannon)
		if isBusy then
			return
		end
		local packet, argument
		if equipped() == cannon.Key then
			packet, argument = Packets.EquipCannon, ""
		elseif isOwned(cannon.Key) then
			packet, argument = Packets.EquipCannon, cannon.Key
		elseif readNumber("Strength") >= cannon.StrengthRequired and readNumber("Cash") >= cannon.Price then
			packet, argument = Packets.BuyCannon, cannon.Key
		else
			context.Feedback(button, false)
			return
		end
		isBusy = true
		task.spawn(function()
			local isDone = packet:Fire(argument) == true
			isBusy = false
			if isDone and packet == Packets.BuyCannon then
				LocalSound.Play("SFX_Money_Gain")
			end
			context.Feedback(button, isDone)
		end)
	end

	if list and template then
		for index, cannon in CannonConfig.Cannons do
			local row = template:Clone()
			row.Name = `Cannon{cannon.Key}`
			row.LayoutOrder = index
			row.Visible = true
			local icon: ImageLabel? = find(row, "Icon", "ImageLabel", false)
			local button: TextButton? = find(row, "BuyButton", "TextButton", true)
			setText(find(row, "TierName", "TextLabel", false), cannon.DisplayName)
			setText(find(row, "TierInfo", "TextLabel", false), `Fires you to the {cannon.ZoneName}`)
			if icon then
				icon.ImageColor3 = cannon.Color
			end
			if button then
				trove:Add(button.Activated:Connect(function()
					request(button, cannon)
				end))
				local priceIcon = button:FindFirstChild("PriceIcon")
				local glow = row:FindFirstChild("ColorGlow")
				table.insert(rows, {
					Cannon = cannon,
					Button = button,
					Label = find(button, "Label", "TextLabel", false),
					Fill = button:FindFirstChild("Fill", true),
					PriceIcon = if priceIcon and priceIcon:IsA("GuiObject") then priceIcon else nil,
					Glow = if glow and glow:IsA("GuiObject") then glow else nil,
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

	for _, key in { "Cannons", "EquippedCannon", "Cash", "Strength" } do
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
