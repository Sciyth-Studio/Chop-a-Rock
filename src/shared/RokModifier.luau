--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RokMotionConfig = require(ReplicatedStorage.Config.RokMotionConfig)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

local RokModifier = {}

function RokModifier.Get(modifier: string?): WeatherConfig.Modifier?
	return if modifier then WeatherConfig.Modifiers[modifier] else nil
end

function RokModifier.Multiplier(modifier: string?): number
	local config = RokModifier.Get(modifier)
	return if config then config.Multiplier else 1
end

function RokModifier.Rate(petKey: string, modifier: string?): number
	local pet = PetConfig.Pets[petKey]
	return if pet then pet.MoneyPerSecond * RokModifier.Multiplier(modifier) else 0
end

function RokModifier.Name(petKey: string, modifier: string?): string
	local pet = PetConfig.Pets[petKey]
	local name = if pet then pet.DisplayName else petKey
	local config = RokModifier.Get(modifier)
	return if config then `{config.DisplayName} {name}` else name
end

function RokModifier.PaintLabel(label: TextLabel, modifier: string?)
	local config = RokModifier.Get(modifier)
	if not config then
		return
	end
	label.TextColor3 = Color3.new(1, 1, 1)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Enabled = true
		gradient.Rotation = 90
		gradient.Color = ColorSequence.new(config.LabelTop, config.LabelBottom)
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = config.LabelBottom:Lerp(Color3.new(0, 0, 0), WeatherConfig.LabelDarkAlpha)
	end
end

local function isEye(name: string): boolean
	for _, suffix in RokMotionConfig.EyePartSuffixes do
		if string.sub(name, -#suffix) == suffix then
			return true
		end
	end
	return false
end

function RokModifier.Tint(root: Instance, modifier: string?)
	local config = RokModifier.Get(modifier)
	local tint = if config then config.Tint else nil
	if not config or not tint then
		return
	end
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and not isEye(part.Name) then
			part.Color = part.Color:Lerp(tint, config.TintAlpha)
		end
	end
end

function RokModifier.IsBetter(candidate: string, current: string?): boolean
	local config = RokModifier.Get(candidate)
	return config ~= nil and config.Multiplier > RokModifier.Multiplier(current)
end

return RokModifier
