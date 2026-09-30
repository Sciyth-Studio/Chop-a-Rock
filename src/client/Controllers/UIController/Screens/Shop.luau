--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local COLOR_AFFORDABLE = Color3.fromRGB(0, 255, 0)
local COLOR_UNAFFORDABLE = Color3.fromRGB(255, 0, 0)
local COLOR_INACTIVE = Color3.fromRGB(150, 150, 150)
local STROKE_AFFORDABLE = Color3.fromRGB(0, 90, 20)
local STROKE_UNAFFORDABLE = Color3.fromRGB(110, 0, 0)
local STROKE_INACTIVE = Color3.fromRGB(60, 60, 60)
local TEXT_STROKE_NAME = "TextStroke"

local Shop = {}

type Row = {
	Index: number,
	Price: number,
	Button: TextButton,
}

local function findFrame(root: Instance, name: string): Frame?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("Frame") then
		return found
	end
	warn(`[Shop] Missing Frame "{name}" in {root:GetFullName()}`)
	return nil
end

local function findList(root: Instance, name: string): GuiObject?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("GuiObject") then
		return found
	end
	warn(`[Shop] Missing GuiObject "{name}" in {root:GetFullName()}`)
	return nil
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name)
	if found and found:IsA("TextLabel") then
		return found
	end
	warn(`[Shop] Missing TextLabel "{name}" in {root:GetFullName()}`)
	return nil
end

local function findButton(root: Instance, name: string): TextButton?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("TextButton") then
		return found
	end
	warn(`[Shop] Missing TextButton "{name}" in {root:GetFullName()}`)
	return nil
end

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local rows: { Row } = {}

	local list = findList(gui, "List")
	local template = findFrame(gui, "RowTemplate")
	local closeButton = findButton(gui, "CloseButton")

	if template then
		template.Visible = false
	end

	local function readNumber(attribute: string, fallback: number): number
		local value = player:GetAttribute(attribute)
		return if type(value) == "number" then value else fallback
	end

	local function paint(button: TextButton, color: Color3, strokeColor: Color3)
		button.BackgroundColor3 = color
		local stroke = button:FindFirstChild(TEXT_STROKE_NAME)
		if stroke and stroke:IsA("UIStroke") then
			stroke.Color = strokeColor
		end
	end

	local function refresh()
		local ownedTier = readNumber("ArmTier", 1)
		local cash = readNumber("Cash", 0)
		for _, row in rows do
			if row.Index <= ownedTier then
				row.Button.Text = "OWNED"
				paint(row.Button, COLOR_INACTIVE, STROKE_INACTIVE)
			elseif row.Index == ownedTier + 1 then
				row.Button.Text = `${NumberFormat.Commas(row.Price)}`
				if cash >= row.Price then
					paint(row.Button, COLOR_AFFORDABLE, STROKE_AFFORDABLE)
				else
					paint(row.Button, COLOR_UNAFFORDABLE, STROKE_UNAFFORDABLE)
				end
			else
				row.Button.Text = "LOCKED"
				paint(row.Button, COLOR_INACTIVE, STROKE_INACTIVE)
			end
		end
	end

	if list and template then
		for index, tier in ArmConfig.Tiers do
			local row = template:Clone()
			row.Name = `Tier{index}`
			row.LayoutOrder = index
			row.Visible = true
			local nameLabel = findLabel(row, "TierName")
			local infoLabel = findLabel(row, "TierInfo")
			local button = findButton(row, "BuyButton")
			if nameLabel then
				nameLabel.Text = tier.DisplayName
			end
			if infoLabel then
				infoLabel.Text = `{tier.TrainingGainMultiplier}x training strength`
			end
			if button then
				trove:Add(button.Activated:Connect(function()
					if index == readNumber("ArmTier", 1) + 1 then
						task.spawn(function()
							if Packets.BuyArm:Fire(index) then
								LocalSound.Play("SFX_Money_Gain")
							end
						end)
					end
				end))
				table.insert(rows, { Index = index, Price = tier.Price, Button = button })
			end
			row.Parent = list
		end
	end

	if closeButton then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close("Shop")
		end))
	end

	trove:Connect(player:GetAttributeChangedSignal("ArmTier"), refresh)
	trove:Connect(player:GetAttributeChangedSignal("Cash"), refresh)
	trove:Add(Packets.ShopOpen.OnClientEvent:Connect(function()
		context.Open("Shop")
	end))
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
