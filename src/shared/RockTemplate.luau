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
