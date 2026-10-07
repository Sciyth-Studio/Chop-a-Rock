--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local CashPopConfig = require(ReplicatedStorage.Config.CashPopConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any

type TroveInstance = typeof(Trove.new())

local CashPopController = {
	Name = "CashPopController",
	_trove = nil :: TroveInstance?,
}

local template: Model? = nil

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
	if template and profile.ShowBurst then
		VFXEmit.play(template, CFrame.new(position))
	end
	spawnCoins(position, profile)
end

function CashPopController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
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
