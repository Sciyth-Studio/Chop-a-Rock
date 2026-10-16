--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local AuraShopConfig = require(ReplicatedStorage.Config.AuraShopConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local AuraShop = {}

type Row = {
	Aura: AuraConfig.Aura,
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
	warn(`[AuraShop] Missing {className} "{name}" in {root:GetFullName()}`)
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

function AuraShop.new(context: Types.Context, gui: ScreenGui): Types.Screen
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

	local function readNumber(key: string): number
		local value = dataController:Get({ key })
		return if type(value) == "number" then value else 0
	end

	local function isOwned(key: string): boolean
		return dataController:Get({ "Auras", key }) == true
	end

	local function equippedKey(): string
		local value = dataController:Get({ "EquippedAura" })
		return if type(value) == "string" then value else ""
	end

	local function refresh()
		local rebirths = readNumber("Rebirths")
		local cash = readNumber("Cash")
		local equipped = equippedKey()
		for _, row in rows do
			local aura = row.Aura
			if row.Glow then
				row.Glow.Visible = aura.Key == equipped
			end
			row.Button:SetAttribute(
				"Shimmer",
				not isOwned(aura.Key) and rebirths >= aura.RebirthsRequired and cash >= aura.Price
			)
			if aura.Key == equipped then
				present(row, AuraShopConfig.EquippedText, AuraShopConfig.Palette.Equipped, false)
			elseif isOwned(aura.Key) then
				present(row, AuraShopConfig.EquipText, AuraShopConfig.Palette.Owned, false)
			elseif rebirths < aura.RebirthsRequired then
				local text = AuraShopConfig.LockedText:gsub("{Rebirths}", tostring(aura.RebirthsRequired))
				present(row, text, AuraShopConfig.Palette.Locked, false)
			else
				local colors = if cash >= aura.Price
					then AuraShopConfig.Palette.Affordable
					else AuraShopConfig.Palette.Unaffordable
				present(row, NumberFormat.Compact(aura.Price), colors, true)
			end
		end
	end

	local function activate(aura: AuraConfig.Aura, button: TextButton)
		local equipped = equippedKey()
		if aura.Key == equipped then
			task.spawn(function()
				Packets.EquipAura:Fire("")
			end)
		elseif isOwned(aura.Key) then
			task.spawn(function()
				Packets.EquipAura:Fire(aura.Key)
			end)
		elseif readNumber("Rebirths") >= aura.RebirthsRequired and readNumber("Cash") >= aura.Price then
			task.spawn(function()
				local isBought = Packets.BuyAura:Fire(aura.Key) == true
				if isBought then
					LocalSound.Play("SFX_Money_Gain")
				end
				context.Feedback(button, isBought)
			end)
		else
			context.Feedback(button, false)
		end
	end

	if list and template then
		for index, aura in AuraConfig.Auras do
			local row = template:Clone()
			row.Name = aura.Key
			row.LayoutOrder = index
			row.Visible = true
			local nameLabel: TextLabel? = find(row, "TierName", "TextLabel", false)
			local infoLabel: TextLabel? = find(row, "TierInfo", "TextLabel", false)
			local icon: ImageLabel? = find(row, "Icon", "ImageLabel", true)
			local button: TextButton? = find(row, "BuyButton", "TextButton", true)
			setText(nameLabel, aura.DisplayName)
			setText(infoLabel, (AuraShopConfig.InfoText:gsub("{Speed}", tostring(aura.WalkSpeedBonus))))
			if icon then
				icon.Image = aura.Icon
				icon.ImageColor3 = aura.Color
			end
			if button then
				trove:Add(button.Activated:Connect(function()
					activate(aura, button)
				end))
				local priceIcon = button:FindFirstChild("PriceIcon")
				local glow = row:FindFirstChild("ColorGlow")
				table.insert(rows, {
					Aura = aura,
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
			context.Close("AuraShop")
		end))
	end

	trove:Add(dataController:Observe({ "Auras" }, refresh))
	trove:Add(dataController:Observe({ "EquippedAura" }, refresh))
	trove:Add(dataController:Observe({ "Rebirths" }, refresh))
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

return AuraShop
