--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Types = require(script.Parent.Types)

local Effects = {}

local soundLifetimeSeconds = 5
local shown: { [BasePart]: { ModelKey: string, Model: Model } } = {}

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

local function prepare(modelKey: string, spot: Attachment): Model?
	local asset = AssetRegistry.get(modelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[GeodeService] Asset "{modelKey}" is not a Model`)
		return nil
	end
	local model = asset :: Model
	model.Name = "PadGeode"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
	model:PivotTo(spot.WorldCFrame)
	model.Parent = spot.Parent
	return model
end

function Effects.ShowOnPad(pad: Types.Pad, modelKey: string?)
	local current = shown[pad.Part]
	if current and current.ModelKey == modelKey and current.Model.Parent then
		return
	end
	if current then
		current.Model:Destroy()
		shown[pad.Part] = nil
	end
	local model = if modelKey then prepare(modelKey, pad.Spot) else nil
	if model and modelKey then
		shown[pad.Part] = { ModelKey = modelKey, Model = model }
	end
end

function Effects.Open(part: BasePart)
	playSound("SFX_Rock_Crack", part)
	playSound("SFX_Rock_Break", part)
end

function Effects.Reset()
	for _, entry in shown do
		entry.Model:Destroy()
	end
	table.clear(shown)
end

return Effects
