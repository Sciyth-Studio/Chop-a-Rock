--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Types = require(script.Parent.Types)

local Effects = {}

local soundLifetimeSeconds = 5
local shownTransparencyAttribute = "ShownTransparency"
local showTokens: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function playSound(key: string, part: BasePart)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	asset.Parent = part
	asset:Play()
	task.delay(soundLifetimeSeconds, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function qualitySoundKey(quality: number): string
	if quality == ChopQuality.Perfect then
		return "SFX_Chop_Perfect"
	elseif quality == ChopQuality.Great then
		return "SFX_Chop_Great"
	elseif quality == ChopQuality.Good then
		return "SFX_Chop_Good"
	elseif quality == ChopQuality.Mid then
		return "SFX_Chop_Mid"
	end
	return "SFX_Chop_Bad"
end

local function setShown(model: Model, isShown: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local shown = descendant:GetAttribute(shownTransparencyAttribute)
			descendant.Transparency = if isShown and type(shown) == "number" then shown else 1
		end
	end
end

function Effects.Prepare(modelKey: string, spot: Attachment): Types.Pit?
	local asset = AssetRegistry.get(modelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[GeodeService] Asset "{modelKey}" is not a Model`)
		return nil
	end
	local model = asset :: Model
	model.Name = "PitGeode"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant:SetAttribute(shownTransparencyAttribute, descendant.Transparency)
		end
	end
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		model:Destroy()
		return nil
	end
	part:SetAttribute(ChopConfig.RelativeOffsetAttribute, true)
	setShown(model, false)
	model:PivotTo(spot.WorldCFrame)
	model.Parent = workspace
	return { ModelKey = modelKey, Model = model, Part = part }
end

function Effects.Show(model: Model)
	showTokens[model] = (showTokens[model] or 0) + 1
	setShown(model, true)
end

function Effects.Hide(model: Model, delaySeconds: number)
	local token = showTokens[model]
	task.delay(delaySeconds, function()
		if model.Parent and showTokens[model] == token then
			setShown(model, false)
		end
	end)
end

function Effects.Crack(part: BasePart)
	playSound("SFX_Rock_Crack", part)
end

function Effects.Hit(part: BasePart, quality: number)
	playSound(qualitySoundKey(quality), part)
	playSound("SFX_Rock_Break", part)
end

function Effects.MasterStart(part: BasePart)
	playSound(MasterChopConfig.SoundKey, part)
end

return Effects
