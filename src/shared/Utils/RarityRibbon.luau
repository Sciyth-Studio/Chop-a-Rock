--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)

local RarityRibbon = {}

function RarityRibbon.Colors(rarityKey: string): ColorSequence
	local rarity = RarityConfig.Rarities[rarityKey]
	if not rarity then
		return ColorSequence.new(Color3.new(0.5, 0.5, 0.5))
	end
	if rarity.RainbowLabel then
		return RarityConfig.Rainbow
	end
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarity.Color:Lerp(Color3.new(1, 1, 1), RarityConfig.RibbonLighten)),
		ColorSequenceKeypoint.new(0.5, rarity.Color),
		ColorSequenceKeypoint.new(1, rarity.Color:Lerp(Color3.new(0, 0, 0), RarityConfig.RibbonDarken)),
	})
end

function RarityRibbon.Paint(ribbon: GuiObject, rarityKey: string)
	local rarity = RarityConfig.Rarities[rarityKey]
	ribbon.BackgroundColor3 = Color3.new(1, 1, 1)
	local gradient = ribbon:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = RarityRibbon.Colors(rarityKey)
		gradient.Rotation = if rarity and rarity.RainbowLabel then 0 else 90
	end
	local label = ribbon:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = if rarity then rarity.DisplayName else ""
	end
end

return RarityRibbon
