--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local VipBaseService = { Name = "VipBaseService" }

local settings = MonetizationConfig.Vip.Base
local ORIGINAL_ATTRIBUTE = "OriginalColor"

local services: { [string]: any } = {}
local trove = Trove.new()

local function setGold(plot: Model, isGold: boolean)
	for _, part in plot:GetDescendants() do
		local color = settings.PartColors[part.Name]
		if not color or not part:IsA("BasePart") then
			continue
		end
		local original = part:GetAttribute(ORIGINAL_ATTRIBUTE)
		if typeof(original) ~= "Color3" then
			original = part.Color
			part:SetAttribute(ORIGINAL_ATTRIBUTE, original)
		end
		part.Color = if isGold then color else original :: Color3
	end
	for _, child in plot:GetChildren() do
		if child.Name == settings.CarpetName then
			child:Destroy()
		end
	end
	if not isGold then
		return
	end
	for _, carpet in settings.Carpets do
		local part = Instance.new("Part")
		part.Name = settings.CarpetName
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.Fabric
		part.Color = settings.CarpetColor
		part.Size = carpet.Size
		part.CFrame = plot:GetPivot() * CFrame.new(carpet.Offset)
		part.Parent = plot
	end
end

local function refresh(player: Player)
	local plot = services.BaseService:GetPlot(player)
	if plot then
		setGold(plot, services.PassService:Owns(player, MonetizationConfig.Vip.PassKey))
	end
end

function VipBaseService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function VipBaseService.Start(_self: any)
	trove:Add(services.BaseService.PlotClaimed:Connect(function(player: Player)
		refresh(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(_player: Player, plot: Model)
		setGold(plot, false)
	end))
	trove:Add(services.PassService.PassChanged:Connect(function(player: Player, key: string)
		if key == MonetizationConfig.Vip.PassKey then
			refresh(player)
		end
	end))
	for _, player in Players:GetPlayers() do
		refresh(player)
	end
end

function VipBaseService.Destroy(_self: any)
	trove:Destroy()
end

return VipBaseService
