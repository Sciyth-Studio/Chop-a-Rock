--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)

local Paint = {}

local black = Color3.new(0, 0, 0)

local function ramp(names: string, palette: AuraConfig.Palette): ColorSequence?
	local colors: { Color3 } = {}
	for name in string.gmatch(names, "[^,%s]+") do
		local list = palette[name] or palette.Main
		if list then
			for _, color in list do
				table.insert(colors, color)
			end
		end
	end
	if #colors == 0 then
		return nil
	elseif #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local keypoints = {}
	for index, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / (#colors - 1), color))
	end
	return ColorSequence.new(keypoints)
end

local function multiply(sequence: ColorSequence, color: Color3): ColorSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		local value = keypoint.Value
		table.insert(
			keypoints,
			ColorSequenceKeypoint.new(
				keypoint.Time,
				Color3.new(value.R * color.R, value.G * color.G, value.B * color.B)
			)
		)
	end
	return ColorSequence.new(keypoints)
end

local function scaleSize(sequence: NumberSequence, scale: number): NumberSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * scale, keypoint.Envelope * scale)
		)
	end
	return NumberSequence.new(keypoints)
end

local function colorFor(item: Instance, tier: AuraConfig.AuraTier): (ColorSequence?, boolean?)
	local palette = tier.Palette
	local inverse = item:GetAttribute(AuraConfig.InverseAttribute)
	if tier.IsInverted and type(inverse) == "string" and palette then
		if inverse == "Black" then
			return ColorSequence.new(black), true
		end
		return ramp(inverse, palette), false
	end
	local names = item:GetAttribute(AuraConfig.RampAttribute)
	if type(names) == "string" and palette then
		return ramp(names, palette), nil
	end
	return nil, nil
end

local function paintOne(
	item: Instance,
	tier: AuraConfig.AuraTier,
	stage: AuraConfig.AuraStage,
	emitScale: number
)
	local isTinted = item:GetAttribute(AuraConfig.TintAttribute) ~= false
	local fallback = tier.Color or Color3.new(1, 1, 1)
	if item:IsA("ParticleEmitter") then
		item.Rate *= stage.RateScale * emitScale
		item.Size = scaleSize(item.Size, stage.SizeScale)
		if isTinted then
			local sequence, isDark = colorFor(item, tier)
			item.Color = sequence or multiply(item.Color, fallback)
			if isDark == true then
				item.LightEmission = 0
				item.Brightness = 0
			elseif isDark == false then
				item.LightEmission = 1
			end
		end
	elseif item:IsA("Beam") then
		if isTinted then
			local sequence = colorFor(item, tier)
			item.Color = sequence or multiply(item.Color, fallback)
		end
	elseif item:IsA("Trail") then
		if isTinted then
			local sequence = colorFor(item, tier)
			item.Color = sequence or multiply(item.Color, fallback)
		end
	elseif item:IsA("PointLight") then
		local main = if tier.Palette and tier.Palette.Main then tier.Palette.Main[1] else fallback
		if isTinted then
			item.Color = main
		end
		item.Brightness *= stage.LightScale
	end
end

function Paint.StageOf(tier: AuraConfig.AuraTier): AuraConfig.AuraStage
	local index = math.clamp(tier.Stage or 3, 1, #AuraConfig.Stages)
	return AuraConfig.Stages[index]
end

function Paint.Apply(root: Instance, tier: AuraConfig.AuraTier, emitScale: number): boolean
	local stageIndex = tier.Stage or 3
	local stage = Paint.StageOf(tier)
	local items = root:GetDescendants()
	table.insert(items, 1, root)
	for _, item in items do
		local minStage = item:GetAttribute(AuraConfig.MinStageAttribute)
		if type(minStage) == "number" and minStage > stageIndex then
			if item == root then
				root:Destroy()
				return false
			end
			item:Destroy()
		elseif item.Parent or item == root then
			paintOne(item, tier, stage, emitScale)
		end
	end
	return true
end

return Paint
