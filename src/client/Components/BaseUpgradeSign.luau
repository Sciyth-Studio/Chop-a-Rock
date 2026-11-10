--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local BaseUpgradeConfig = require(ReplicatedStorage.Config.BaseUpgradeConfig)
local BlockButtonConfig = require(ReplicatedStorage.Config.BlockButtonConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local BaseLevels = require(ReplicatedStorage.Utils.BaseLevels)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type BaseUpgradeSign = {
	Instance: Instance,
	Trove: any,
}

local sign = BaseUpgradeConfig.Sign

local function findPlot(instance: Instance): Instance?
	local ancestor = instance.Parent
	while ancestor and ancestor ~= workspace do
		if CollectionService:HasTag(ancestor, sign.PlotTag) then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[BaseUpgradeSign] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function paint(button: GuiButton?, colors: ShopConfig.MeterColors)
	BlockButton.Paint(if button then button:FindFirstChild("Fill", true) else nil, colors)
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. BlockButtonConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

return function(controllers: { [string]: any })
	local BaseUpgradeSignComponent = Component.new({ Tag = sign.Tag }) :: any

	function BaseUpgradeSignComponent.Start(self: BaseUpgradeSign)
		local model = self.Instance
		local gui = model:FindFirstChildWhichIsA("SurfaceGui", true)
		local plot = findPlot(model)
		if not gui or not plot then
			warn(`[BaseUpgradeSign] Needs a SurfaceGui and a BasePlot ancestor: {model:GetFullName()}`)
			return
		end
		self.Trove = Trove.new()
		local trove = self.Trove
		local dataController = controllers.DataController
		local notifications = controllers.NotificationController

		Typography.Apply(gui)
		if controllers.UIController then
			controllers.UIController:BindFeel(gui)
		end

		local title: TextLabel? = find(gui, sign.TitleName, "TextLabel")
		local levels: TextLabel? = find(gui, sign.LevelsName, "TextLabel")
		local cashButton: GuiButton? = find(gui, sign.CashButtonName, "GuiButton")
		local cashLabel: TextLabel? = if cashButton
			then find(cashButton, sign.CashLabelName, "TextLabel")
			else nil

		local parts: { BasePart } = {}
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end

		local isBusy = false

		local function isOwner(): boolean
			return plot:GetAttribute(sign.OwnerAttribute) == Players.LocalPlayer.UserId
		end

		local function cash(): number
			local value = dataController:Get({ "Cash" })
			return if type(value) == "number" then value else 0
		end

		local function notify(kind: string, message: string)
			if notifications then
				notifications:Notify(kind, message)
			end
		end

		local function refresh()
			local owned = isOwner()
			gui.Enabled = owned
			for _, part in parts do
				part.LocalTransparencyModifier = if owned then 0 else 1
			end
			if not owned then
				return
			end
			local level = BaseLevels.Clamp(dataController:Get({ "BaseLevel" }))
			local nextLevel = BaseLevels.Next(level)
			setText(title, sign.TitleText)
			if cashButton then
				cashButton.Visible = nextLevel ~= nil
			end
			if not nextLevel then
				setText(levels, sign.MaxText)
				return
			end
			setText(levels, string.format(sign.LevelsFormat, level, level + 1))
			setText(cashLabel, `${NumberFormat.Compact(nextLevel.Price, 1e3)}`)
			paint(
				cashButton,
				if cash() >= nextLevel.Price then sign.Palette.Affordable else sign.Palette.Unavailable
			)
		end

		if cashButton then
			trove:Connect(cashButton.Activated, function()
				if isBusy or not isOwner() then
					return
				end
				local level = BaseLevels.Clamp(dataController:Get({ "BaseLevel" }))
				local nextLevel = BaseLevels.Next(level)
				if not nextLevel then
					notify(BaseUpgradeConfig.ErrorKind, BaseUpgradeConfig.Messages.Max)
					return
				end
				local shortfall = nextLevel.Price - cash()
				if shortfall > 0 and controllers.CashPackController then
					controllers.CashPackController:Prompt(shortfall)
					return
				end
				isBusy = true
				local result = Packets.UpgradeBase:Fire()
				isBusy = false
				if result == "Upgraded" then
					LocalSound.Play(BaseUpgradeConfig.UpgradedSound)
					notify(
						BaseUpgradeConfig.UpgradedKind,
						string.format(BaseUpgradeConfig.UpgradedFormat, level + 1)
					)
				elseif type(result) == "string" and BaseUpgradeConfig.Messages[result] then
					notify(BaseUpgradeConfig.ErrorKind, BaseUpgradeConfig.Messages[result])
				else
					notify(BaseUpgradeConfig.ErrorKind, BaseUpgradeConfig.Messages.Failed)
				end
			end)
		end

		trove:Connect(plot:GetAttributeChangedSignal(sign.OwnerAttribute), refresh)
		for _, key in { "BaseLevel", "Cash" } do
			trove:Add(dataController:Observe({ key }, refresh))
		end
		refresh()
	end

	function BaseUpgradeSignComponent.Stop(self: BaseUpgradeSign)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return BaseUpgradeSignComponent
end
