--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local BlockButtonConfig = require(ReplicatedStorage.Config.BlockButtonConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local TrainingSignConfig = require(ReplicatedStorage.Config.TrainingSignConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local RobuxButton = require(ReplicatedStorage.Utils.RobuxButton)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TrainingUpgradeSign = {
	Instance: Instance,
	Trove: any,
}

local function findPlot(instance: Instance): Instance?
	local ancestor = instance.Parent
	while ancestor and ancestor ~= workspace do
		if CollectionService:HasTag(ancestor, TrainingSignConfig.PlotTag) then
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
	warn(`[TrainingUpgradeSign] Missing {className} "{name}" in {root:GetFullName()}`)
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
	local TrainingUpgradeSign = Component.new({ Tag = TrainingSignConfig.Tag }) :: any

	function TrainingUpgradeSign.Start(self: TrainingUpgradeSign)
		local sign = self.Instance
		local gui = sign:FindFirstChildWhichIsA("SurfaceGui", true)
		local plot = findPlot(sign)
		if not gui or not plot then
			warn(`[TrainingUpgradeSign] Needs a SurfaceGui and a BasePlot ancestor: {sign:GetFullName()}`)
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

		local title: TextLabel? = find(gui, TrainingSignConfig.TitleName, "TextLabel")
		local levels: TextLabel? = find(gui, TrainingSignConfig.LevelsName, "TextLabel")
		local cashButton: GuiButton? = find(gui, TrainingSignConfig.CashButtonName, "GuiButton")
		local robuxInstance = if cashButton then cashButton:FindFirstChild("RobuxButton") else nil
		local robuxButton: GuiButton? = if robuxInstance and robuxInstance:IsA("GuiButton")
			then robuxInstance
			else nil
		local cashLabel: TextLabel? = if cashButton
			then find(cashButton, TrainingSignConfig.CashLabelName, "TextLabel")
			else nil
		local cashIcon = if cashButton
			then cashButton:FindFirstChild(TrainingSignConfig.CashIconName, true)
			else nil
		local rebirthIcon = if cashButton
			then cashButton:FindFirstChild(TrainingSignConfig.RebirthIconName, true)
			else nil

		local parts: { BasePart } = {}
		for _, descendant in sign:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
		if sign:IsA("BasePart") then
			table.insert(parts, sign)
		end

		local isBusy = false

		local function isOwner(): boolean
			return plot:GetAttribute(TrainingSignConfig.OwnerAttribute) == Players.LocalPlayer.UserId
		end

		local function readNumber(key: string, fallback: number): number
			local value = dataController:Get({ key })
			return if type(value) == "number" then value else fallback
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
			local tier = TrainingStands.ClampTier(dataController:Get({ "TrainingTier" }))
			local current = TrainingStands.Get(tier)
			local nextStand = TrainingStands.Next(tier)
			setText(title, TrainingSignConfig.TitleText)
			if not nextStand then
				setText(levels, TrainingSignConfig.MaxText)
				RobuxButton.Show(robuxButton, nil)
				if cashButton then
					cashButton.Visible = false
				end
				return
			end
			setText(
				levels,
				string.format(TrainingSignConfig.LevelsFormat, current.DisplayName, nextStand.DisplayName)
			)
			if cashButton then
				cashButton.Visible = true
			end
			local isLocked = readNumber("Rebirths", 0) < nextStand.Rebirths
			local canAfford = readNumber("Cash", 0) >= nextStand.Price
			local shortfall = nextStand.Price - readNumber("Cash", 0)
			local pack = if not isLocked
					and shortfall > 0
					and controllers.PurchaseController
				then controllers.PurchaseController:CoveringPack(shortfall)
				else nil
			RobuxButton.Show(robuxButton, if pack and pack.ProductId then pack.RobuxPrice else nil)
			if isLocked then
				setText(cashLabel, string.format(TrainingSignConfig.LockedFormat, nextStand.Rebirths))
				paint(cashButton, TrainingSignConfig.Palette.Unavailable)
			else
				setText(cashLabel, `${NumberFormat.Compact(nextStand.Price, 1e3)}`)
				paint(
					cashButton,
					if canAfford
						then TrainingSignConfig.Palette.Affordable
						else TrainingSignConfig.Palette.Unavailable
				)
			end
			if cashIcon and cashIcon:IsA("GuiObject") then
				cashIcon.Visible = not isLocked
			end
			if rebirthIcon and rebirthIcon:IsA("GuiObject") then
				rebirthIcon.Visible = isLocked
			end
		end

		local function lockedMessage(): string?
			local nextStand = TrainingStands.Next(dataController:Get({ "TrainingTier" }))
			if not nextStand then
				return TrainingSignConfig.Messages.Max
			end
			if readNumber("Rebirths", 0) < nextStand.Rebirths then
				return string.format(
					TrainingSignConfig.Messages.Locked,
					nextStand.Rebirths,
					nextStand.DisplayName
				)
			end
			return nil
		end

		if robuxButton then
			trove:Connect(robuxButton.Activated, function()
				local nextStand = TrainingStands.Next(dataController:Get({ "TrainingTier" }))
				local shortfall = if nextStand then nextStand.Price - readNumber("Cash", 0) else 0
				if shortfall > 0 and isOwner() and not lockedMessage() and controllers.PurchaseController then
					controllers.PurchaseController:PromptCash(shortfall)
				end
			end)
		end

		if cashButton then
			trove:Connect(cashButton.Activated, function()
				if isBusy or not isOwner() then
					return
				end
				local blocked = lockedMessage()
				if blocked then
					notify(TrainingSignConfig.ErrorKind, blocked)
					return
				end
				local nextStand = TrainingStands.Next(dataController:Get({ "TrainingTier" }))
				local shortfall = if nextStand then nextStand.Price - readNumber("Cash", 0) else 0
				if shortfall > 0 and controllers.CashPackController then
					controllers.CashPackController:Prompt(shortfall)
					return
				end
				isBusy = true
				local result = Packets.UpgradeTraining:Fire()
				isBusy = false
				if result == "Upgraded" and nextStand then
					LocalSound.Play(TrainingSignConfig.UpgradedSound)
					notify(
						TrainingSignConfig.UpgradedKind,
						string.format(TrainingSignConfig.UpgradedFormat, nextStand.DisplayName)
					)
				elseif type(result) == "string" and TrainingSignConfig.Messages[result] then
					notify(
						TrainingSignConfig.ErrorKind,
						lockedMessage() or TrainingSignConfig.Messages[result]
					)
				else
					notify(TrainingSignConfig.ErrorKind, TrainingSignConfig.Messages.Failed)
				end
			end)
		end

		trove:Connect(plot:GetAttributeChangedSignal(TrainingSignConfig.OwnerAttribute), refresh)
		for _, key in { "TrainingTier", "Rebirths", "Cash" } do
			trove:Add(dataController:Observe({ key }, refresh))
		end
		refresh()
	end

	function TrainingUpgradeSign.Stop(self: TrainingUpgradeSign)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return TrainingUpgradeSign
end
