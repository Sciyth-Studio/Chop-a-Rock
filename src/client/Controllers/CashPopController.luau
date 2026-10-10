--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local CashPopConfig = require(ReplicatedStorage.Config.CashPopConfig)
local HotStreakConfig = require(ReplicatedStorage.Config.HotStreakConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any

type TroveInstance = typeof(Trove.new())

local CashPopController = {
	Name = "CashPopController",
	_trove = nil :: TroveInstance?,
}

local template: Model? = nil
local textTemplate: BillboardGui? = nil

local function randomIn(range: NumberRange): number
	return range.Min + math.random() * (range.Max - range.Min)
end

local function fadeOut(coin: BasePart)
	if not coin.Parent then
		return
	end
	local tween = TweenService:Create(
		coin,
		TweenInfo.new(CashPopConfig.CoinFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }
	)
	tween.Completed:Once(function()
		coin:Destroy()
	end)
	tween:Play()
end

local function spawnCoins(position: Vector3, profile: CashPopConfig.CashPopProfile)
	for _ = 1, profile.CoinCount do
		local angle = math.random() * 2 * math.pi
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local coin = Instance.new("Part")
		coin.Name = "CashCoin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = CashPopConfig.CoinSize * profile.CoinScale
		coin.Color = CashPopConfig.CoinColor
		coin.Material = CashPopConfig.CoinMaterial
		coin.CanCollide = true
		coin.CanQuery = false
		coin.CanTouch = false
		coin.CastShadow = false
		coin.CollisionGroup = CashPopConfig.CollisionGroup
		coin.CFrame = CFrame.new(position + outward * 0.5) * CFrame.Angles(0, angle, 0)
		coin.Parent = workspace
		coin.AssemblyLinearVelocity = outward * randomIn(profile.CoinOutSpeed)
			+ Vector3.yAxis * randomIn(profile.CoinUpSpeed)
		coin.AssemblyAngularVelocity = Vector3.new(0, CashPopConfig.CoinSpinRadPerSec, 0)
		task.delay(CashPopConfig.CoinLifetimeSeconds + math.random() * 0.2, fadeOut, coin)
	end
end

local function feetPosition(): Vector3?
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not humanoid or not rootPart then
		return nil
	end
	return rootPart.Position - Vector3.new(0, rootPart.Size.Y / 2 + humanoid.HipHeight, 0)
end

function CashPopController.Play(_self: any, position: Vector3, profile: CashPopConfig.CashPopProfile)
	if template and profile.ShowBurst and not LowGraphics.IsOn() then
		VFXEmit.play(template, CFrame.new(position))
	end
	spawnCoins(position, profile)
end

local function fadeLabel(label: TextLabel, seconds: number)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
end

function CashPopController.PlayText(_self: any, position: Vector3, payout: number, multiplier: number)
	local source = textTemplate
	local definition: HotStreakConfig.Tier? = nil
	for _, tier in HotStreakConfig.Tiers do
		if tier.Multiplier == multiplier then
			definition = tier
		end
	end
	if not source or not definition then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "CashPopTextAnchor"
	anchor.Size = Vector3.one * 0.2
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(position)
	local billboard = source:Clone()
	Typography.Apply(billboard)
	local text = `+${NumberFormat.Compact(payout)} x{multiplier}`
	local label = billboard:FindFirstChild("Label")
	local shadow = billboard:FindFirstChild("LabelShadow")
	if not (label and label:IsA("TextLabel") and shadow and shadow:IsA("TextLabel")) then
		warn(`[CashPopController] {CashPopConfig.TextKey} needs TextLabels "Label" and "LabelShadow"`)
		billboard:Destroy()
		anchor:Destroy()
		return
	end
	label.Text = text
	shadow.Text = text
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, definition.Main),
			ColorSequenceKeypoint.new(0.5, definition.Light),
			ColorSequenceKeypoint.new(1, definition.Main),
		})
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = definition.Dark
	end
	billboard.Adornee = anchor
	billboard.Parent = anchor
	anchor.Parent = workspace
	TweenService:Create(
		anchor,
		TweenInfo.new(HotStreakConfig.CashPopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(position + Vector3.new(0, HotStreakConfig.CashPopRiseStuds, 0)) }
	):Play()
	task.delay(HotStreakConfig.CashPopSeconds - HotStreakConfig.CashPopFadeSeconds, function()
		fadeLabel(label, HotStreakConfig.CashPopFadeSeconds)
		fadeLabel(shadow, HotStreakConfig.CashPopFadeSeconds)
	end)
	task.delay(HotStreakConfig.CashPopSeconds, function()
		anchor:Destroy()
	end)
end

function CashPopController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
	local textAsset = AssetRegistry.get(CashPopConfig.TextKey)
	if textAsset:IsA("BillboardGui") then
		textTemplate = textAsset
	else
		textAsset:Destroy()
	end
	local asset = AssetRegistry.get(CashPopConfig.EffectKey)
	if asset:IsA("Model") then
		template = asset
	else
		asset:Destroy()
	end
end

function CashPopController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.PadCollected.OnClientEvent:Connect(function()
		local feet = feetPosition()
		if feet then
			self:Play(feet, CashPopConfig.Pad)
		end
	end))
end

function CashPopController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return CashPopController
