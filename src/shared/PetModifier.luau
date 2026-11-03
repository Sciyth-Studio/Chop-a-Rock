--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetMotionConfig = require(ReplicatedStorage.Config.PetMotionConfig)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

local PetModifier = {}

function PetModifier.Get(modifier: string?): WeatherConfig.Modifier?
	return if modifier then WeatherConfig.Modifiers[modifier] else nil
end

function PetModifier.Multiplier(modifier: string?): number
	local config = PetModifier.Get(modifier)
	return if config then config.Multiplier else 1
end

function PetModifier.Rate(petKey: string, modifier: string?, income: number?): number
	local pet = PetConfig.Pets[petKey]
	local base = if income then income elseif pet then pet.MoneyPerSecond else 0
	return base * PetModifier.Multiplier(modifier)
end

function PetModifier.Name(petKey: string, modifier: string?): string
	local pet = PetConfig.Pets[petKey]
	local name = if pet then pet.DisplayName else petKey
	local config = PetModifier.Get(modifier)
	return if config then `{config.DisplayName} {name}` else name
end

function PetModifier.PaintLabel(label: TextLabel, modifier: string?)
	local config = PetModifier.Get(modifier)
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
	for _, suffix in PetMotionConfig.EyePartSuffixes do
		if string.sub(name, -#suffix) == suffix then
			return true
		end
	end
	return false
end

function PetModifier.Tint(root: Instance, modifier: string?)
	local config = PetModifier.Get(modifier)
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

function PetModifier.ImageTint(modifier: string?): Color3
	local config = PetModifier.Get(modifier)
	local tint = if config then config.Tint else nil
	if not config or not tint then
		return Color3.new(1, 1, 1)
	end
	return Color3.new(1, 1, 1):Lerp(tint, config.TintAlpha)
end

function PetModifier.IsBetter(candidate: string, current: string?): boolean
	local config = PetModifier.Get(candidate)
	return config ~= nil and config.Multiplier > PetModifier.Multiplier(current)
end

return PetModifier
