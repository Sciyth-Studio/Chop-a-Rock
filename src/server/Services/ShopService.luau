--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SHOP_TAG = "ShopKiosk"

local trove = Trove.new()

local ShopService = {
	Name = "ShopService",
}

local function resolveKioskPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart
		end
		local fallback = instance:FindFirstChild("ShopKiosk")
		if fallback and fallback:IsA("BasePart") then
			return fallback
		end
	end
	return nil
end

local function setupKiosk(instance: Instance)
	local part = resolveKioskPart(instance)
	if not part then
		warn(`[ShopService] ShopKiosk tag on unsupported instance: {instance:GetFullName()}`)
		return
	end
	if part:FindFirstChild("ShopPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Arm Shop"
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	trove:Add(prompt.Triggered:Connect(function(player: Player)
		if player:GetAttribute("DataLoaded") ~= true then
			return
		end
		Packets.ShopOpen:FireClient(player)
	end))
end

function ShopService.Init(_self: any, _services: { [string]: any }) end

function ShopService.Start(_self: any)
	for _, tagged in CollectionService:GetTagged(SHOP_TAG) do
		setupKiosk(tagged)
	end
	trove:Add(CollectionService:GetInstanceAddedSignal(SHOP_TAG):Connect(setupKiosk))
end

function ShopService.Destroy(_self: any)
	trove:Clean()
end

return ShopService
