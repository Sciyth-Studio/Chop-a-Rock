--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local Shop = {}

type Row = {
	Index: number,
	Price: number,
	Button: TextButton,
	Label: TextLabel?,
	Fill: Instance?,
	PriceIcon: GuiObject?,
	Glow: GuiObject?,
}

local function warnMissing(className: string, name: string, root: Instance)
	warn(`[Shop] Missing {className} "{name}" in {root:GetFullName()}`)
end

local function find(root: Instance, name: string, className: string, recursive: boolean): any
	local found = root:FindFirstChild(name, recursive)
	if found and found:IsA(className) then
		return found
	end
	warnMissing(className, name, root)
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

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local rows: { Row } = {}

	local list: GuiObject? = find(gui, "List", "GuiObject", true)
	local template: Frame? = find(gui, "RowTemplate", "Frame", true)
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton", true)

	if template then
		template.Visible = false
	end

	local function readNumber(key: string, fallback: number): number
		local value = dataController:Get({ key })
		return if type(value) == "number" then value else fallback
	end

	local function paint(row: Row, colors: ShopConfig.MeterColors)
		BlockButton.Paint(row.Fill, colors)
	end

	local function present(row: Row, text: string, colors: ShopConfig.MeterColors, showPrice: boolean)
		setText(row.Label, text)
		paint(row, colors)
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
		local ownedTier = readNumber("AuraTier", 1)
		local cash = readNumber("Cash", 0)
		for _, row in rows do
			if row.Glow then
				row.Glow.Visible = row.Index == ownedTier
			end
			row.Button:SetAttribute("Shimmer", row.Index == ownedTier + 1 and cash >= row.Price)
			if row.Index < ownedTier then
				present(row, "Owned", ShopConfig.Palette.Orange, false)
			elseif row.Index == ownedTier then
				present(row, "Equipped", ShopConfig.Palette.Orange, false)
			elseif row.Index == ownedTier + 1 then
				local colors = if cash >= row.Price then ShopConfig.Palette.Green else ShopConfig.Palette.Grey
				present(row, NumberFormat.Commas(row.Price), colors, true)
			else
				present(row, "Locked", ShopConfig.Palette.Grey, false)
			end
		end
	end

	if list and template then
		for index, tier in AuraConfig.Tiers do
			local color = tier.Color
			if not color then
				continue
			end
			local row = template:Clone()
			row.Name = `Tier{index}`
			row.LayoutOrder = index
			row.Visible = true
			local nameLabel: TextLabel? = find(row, "TierName", "TextLabel", false)
			local infoLabel: TextLabel? = find(row, "TierInfo", "TextLabel", false)
			local icon: ImageLabel? = find(row, "Icon", "ImageLabel", false)
			local button: TextButton? = find(row, "BuyButton", "TextButton", true)
			setText(nameLabel, tier.DisplayName)
			setText(infoLabel, `{tier.TrainingGainMultiplier}x Training, +{tier.WalkSpeedBonus} Speed`)
			if icon then
				icon.ImageColor3 = color
			end
			if button then
				trove:Add(button.Activated:Connect(function()
					local ownedTier = readNumber("AuraTier", 1)
					if index == ownedTier + 1 then
						task.spawn(function()
							local isBought = Packets.BuyAura:Fire(index) == true
							if isBought then
								LocalSound.Play("SFX_Money_Gain")
							end
							context.Feedback(button, isBought)
						end)
					elseif index > ownedTier + 1 then
						context.Feedback(button, false)
					end
				end))
				local priceIcon = button:FindFirstChild("PriceIcon")
				local glow = row:FindFirstChild("ColorGlow")
				table.insert(rows, {
					Index = index,
					Price = tier.Price,
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
			context.Close("Shop")
		end))
	end

	trove:Add(dataController:Observe({ "AuraTier" }, refresh))
	trove:Add(dataController:Observe({ "Cash" }, refresh))
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

return Shop
