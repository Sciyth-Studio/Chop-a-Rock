--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local TrainingSignConfig = require(ReplicatedStorage.Config.TrainingSignConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local UpgradeAlertConfig = require(ReplicatedStorage.Config.UpgradeAlertConfig)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Alert = {
	Gui: BillboardGui,
	Image: ImageLabel,
	Anchor: BasePart,
	Phase: number,
}

local UpgradeAlertController = { Name = "UpgradeAlertController" }

local trove = Trove.new()
local registry: { [string]: any } = {}
local alerts: { [string]: Alert } = {}
local notified: { [string]: boolean } = {}
local knownCannons: { [string]: boolean }? = nil
local isCannonPending = false
local folder: Folder? = nil
local clock = 0

local function number(key: string): number
	local value = registry.DataController:Get({ key })
	return if type(value) == "number" then value else 0
end

local function topOf(instance: Instance): Vector3?
	if instance:IsA("Model") then
		local cframe, size = instance:GetBoundingBox()
		return cframe.Position + Vector3.new(0, size.Y / 2, 0)
	elseif instance:IsA("BasePart") then
		return instance.Position + Vector3.new(0, instance.Size.Y / 2, 0)
	end
	return nil
end

local function ownSign(): Instance?
	for _, sign in CollectionService:GetTagged(TrainingSignConfig.Tag) do
		local ancestor = sign.Parent
		while ancestor and ancestor ~= workspace do
			if CollectionService:HasTag(ancestor, TrainingSignConfig.PlotTag) then
				if ancestor:GetAttribute(TrainingSignConfig.OwnerAttribute) == Players.LocalPlayer.UserId then
					return sign
				end
				break
			end
			ancestor = ancestor.Parent
		end
	end
	return nil
end

local function makeAlert(id: string): Alert
	local anchor = Instance.new("Part")
	anchor.Name = id
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Parent = folder

	local gui = Instance.new("BillboardGui")
	gui.Name = `UpgradeAlert{id}`
	gui.Adornee = anchor
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = UpgradeAlertConfig.MaxDistance
	gui.Size = UDim2.fromScale(UpgradeAlertConfig.SizeStuds, UpgradeAlertConfig.SizeStuds)

	local image = Instance.new("ImageLabel")
	image.Name = "Icon"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = UpgradeAlertConfig.Image
	image.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	return { Gui = gui, Image = image, Anchor = anchor, Phase = math.random() * math.pi * 2 }
end

local function setAlert(id: string, target: Instance?)
	local position = if target then topOf(target) else nil
	local alert = alerts[id]
	if not position then
		if alert then
			alert.Gui:Destroy()
			alert.Anchor:Destroy()
			alerts[id] = nil
		end
		return
	end
	if not alert then
		alert = makeAlert(id)
		alerts[id] = alert
	end
	local goal = CFrame.new(position + Vector3.new(0, UpgradeAlertConfig.HeightStuds, 0))
	if alert.Anchor.CFrame ~= goal then
		alert.Anchor.CFrame = goal
	end
end

local function notifyOnce(key: string, message: string)
	if notified[key] then
		return
	end
	notified[key] = true
	local notifications = registry.NotificationController
	if notifications then
		notifications:Notify(UpgradeAlertConfig.NotifyKind, message)
	end
end

local function auraTarget(): Instance?
	local tier = number("AuraTier")
	local nextTier = AuraConfig.Tiers[tier + 1]
	if not nextTier or number("Cash") < nextTier.Price then
		return nil
	end
	notifyOnce(`Aura{tier + 1}`, string.format(UpgradeAlertConfig.AuraText, nextTier.DisplayName))
	return workspace:FindFirstChild(UpgradeAlertConfig.AuraShopName)
end

local function trainingTarget(): Instance?
	local tier = TrainingStands.ClampTier(registry.DataController:Get({ "TrainingTier" }))
	local nextStand = TrainingStands.Next(tier)
	if not nextStand or number("Cash") < nextStand.Price then
		return nil
	end
	notifyOnce(`Training{tier + 1}`, string.format(UpgradeAlertConfig.TrainingText, nextStand.DisplayName))
	return ownSign()
end

local function cannonTarget(): Instance?
	local owned = registry.DataController:Get({ "Cannons" })
	local current: { [string]: boolean } = {}
	if type(owned) == "table" then
		for key in owned do
			current[key] = true
		end
	end
	if knownCannons then
		for key in current do
			if not knownCannons[key] then
				isCannonPending = true
			end
		end
	end
	knownCannons = current
	local ui = registry.UIController
	if isCannonPending and ui and ui:IsOpen(UpgradeAlertConfig.CannonScreen) then
		isCannonPending = false
	end
	return if isCannonPending then workspace:FindFirstChild(UpgradeAlertConfig.CannonShopName) else nil
end

local function check()
	local data = registry.DataController
	if not data:IsLoaded() then
		return
	end
	local cannon = cannonTarget()
	if Tutorial.IsActive(Tutorial.StepOf(data:Get({ "Tutorial" }))) then
		setAlert("Aura", nil)
		setAlert("Training", nil)
		setAlert("Cannon", nil)
		return
	end
	setAlert("Aura", auraTarget())
	setAlert("Training", trainingTarget())
	setAlert("Cannon", cannon)
end

local function animate(dt: number)
	clock += dt
	for _, alert in alerts do
		local t = clock + alert.Phase
		alert.Image.Rotation = math.sin(t * UpgradeAlertConfig.WiggleSpeed) * UpgradeAlertConfig.WiggleDegrees
		alert.Gui.StudsOffsetWorldSpace =
			Vector3.new(0, math.sin(t * UpgradeAlertConfig.BobSpeed) * UpgradeAlertConfig.BobStuds, 0)
	end
end

function UpgradeAlertController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
end

function UpgradeAlertController.Start(_self: any)
	local created = Instance.new("Folder")
	created.Name = "UpgradeAlerts"
	created.Parent = workspace
	folder = created
	trove:Add(created)

	local elapsed = 0
	trove:Connect(RunService.RenderStepped, function(dt: number)
		animate(dt)
		elapsed += dt
		if elapsed >= UpgradeAlertConfig.CheckSeconds then
			elapsed = 0
			check()
		end
	end)
end

function UpgradeAlertController.Destroy(_self: any)
	for id in alerts do
		setAlert(id, nil)
	end
	trove:Clean()
end

return UpgradeAlertController
