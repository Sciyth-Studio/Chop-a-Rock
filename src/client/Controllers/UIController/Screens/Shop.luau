--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
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

local function buildPreview(frame: ViewportFrame, tier: ArmConfig.ArmTier)
	local arm = AssetRegistry.get(ShopConfig.Preview.ModelKey)
	if not arm:IsA("Model") then
		arm:Destroy()
		warn(`[Shop] Asset "{ShopConfig.Preview.ModelKey}" is not a Model`)
		return
	end
	local visual = tier.Visual
	for _, descendant in arm:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Material = visual.Material or descendant.Material
			descendant.Color = visual.Color or descendant.Color
		end
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = ShopConfig.Preview.FieldOfView
	camera.Parent = frame
	arm.Parent = frame
	local center, size = arm:GetBoundingBox()
	local distance = size.Magnitude
		/ 2
		/ math.tan(math.rad(camera.FieldOfView / 2))
		* ShopConfig.Preview.CameraPadding
	camera.CFrame =
		CFrame.lookAt(center.Position + ShopConfig.Preview.CameraDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
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
		local fill = row.Fill
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

	local function present(row: Row, text: string, colors: ShopConfig.MeterColors, showPrice: boolean)
		setText(row.Label, text)
		paint(row, colors)
		if row.PriceIcon then
			row.PriceIcon.Visible = showPrice
		end
		local label = row.Label
		if label then
			local layout = if showPrice
				then ShopConfig.PriceLabel.WithIcon
				else ShopConfig.PriceLabel.WithoutIcon
			label.AnchorPoint = layout.AnchorPoint
			label.Position = layout.Position
			label.Size = layout.Size
		end
	end

	local function refresh()
		local ownedTier = readNumber("ArmTier", 1)
		local cash = readNumber("Cash", 0)
		for _, row in rows do
			if row.Glow then
				row.Glow.Visible = row.Index == ownedTier
			end
			if row.Index < ownedTier then
				present(row, "OWNED", ShopConfig.Palette.Orange, false)
			elseif row.Index == ownedTier then
				present(row, "EQUIPPED", ShopConfig.Palette.Orange, false)
			elseif row.Index == ownedTier + 1 then
				local colors = if cash >= row.Price then ShopConfig.Palette.Green else ShopConfig.Palette.Grey
				present(row, NumberFormat.Commas(row.Price), colors, true)
			else
				present(row, "LOCKED", ShopConfig.Palette.Grey, false)
			end
		end
	end

	if list and template then
		for index, tier in ArmConfig.Tiers do
			local row = template:Clone()
			row.Name = `Tier{index}`
			row.LayoutOrder = index
			row.Visible = true
			local nameLabel: TextLabel? = find(row, "TierName", "TextLabel", false)
			local infoLabel: TextLabel? = find(row, "TierInfo", "TextLabel", false)
			local preview: ViewportFrame? = find(row, "Preview", "ViewportFrame", false)
			local button: TextButton? = find(row, "BuyButton", "TextButton", true)
			setText(nameLabel, tier.DisplayName)
			setText(infoLabel, `{tier.TrainingGainMultiplier}x Training Strength`)
			if preview then
				buildPreview(preview, tier)
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

	trove:Add(dataController:Observe({ "ArmTier" }, refresh))
	trove:Add(dataController:Observe({ "Cash" }, refresh))
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
