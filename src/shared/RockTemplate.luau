--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)

local RockTemplate = {}

function RockTemplate.Build(key: string): BasePart?
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local config = rocks[key]
	if not config then
		return nil
	end
	local asset = AssetRegistry.get(config.TemplateKey)
	if asset:IsA("BasePart") and asset:GetAttribute("RockKey") == key then
		for _, descendant in asset:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = false
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
				descendant.Massless = true
				local weld = Instance.new("Weld")
				weld.Part0 = asset
				weld.Part1 = descendant
				weld.C0 = asset.CFrame:ToObjectSpace(descendant.CFrame)
				weld.Parent = descendant
			end
		end
		return asset
	end
	asset:Destroy()
	local part = Instance.new("Part")
	part.Name = `Rock_{key}`
	part.Size = config.PlaceholderSize
	part.Color = config.PlaceholderColor
	part.Material = Enum.Material.Slate
	part:SetAttribute("RockKey", key)
	return part
end

return RockTemplate
