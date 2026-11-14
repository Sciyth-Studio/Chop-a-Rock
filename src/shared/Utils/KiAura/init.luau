--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local KiAuraConfig = require(ReplicatedStorage.Config.KiAuraConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Layers = require(script.Layers)
local Palette = require(script.Palette)
local Types = require(script.Types)

export type Aura = Types.Aura

local KiAura = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function scaled(source: NumberSequence, scale: number): NumberSequence
	local keys = {}
	for i, key in source.Keypoints do
		keys[i] = NumberSequenceKeypoint.new(key.Time, key.Value * scale, key.Envelope * scale)
	end
	return NumberSequence.new(keys)
end

function KiAura.Attach(character: Model, emitScale: number?): Aura?
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return nil
	end
	local rootPart: BasePart = root
	local trove = Trove.new()
	local rig = Layers.Build(character, rootPart, humanoid)
	for _, instance in rig.Instances do
		trove:Add(instance)
	end
	if rootPart:GetAttribute(KiAuraConfig.ColorAttribute) == nil then
		rootPart:SetAttribute(KiAuraConfig.ColorAttribute, KiAuraConfig.DefaultColor)
	end
	if rootPart:GetAttribute(KiAuraConfig.IntensityAttribute) == nil then
		rootPart:SetAttribute(KiAuraConfig.IntensityAttribute, KiAuraConfig.DefaultIntensity)
	end

	local isEnabled = false
	local visibility = 0
	local popAge = math.huge
	local pulseClock = 0
	local clock = 0
	local intensity = 1

	local function readIntensity()
		local value = rootPart:GetAttribute(KiAuraConfig.IntensityAttribute)
		intensity = if type(value) == "number" then math.clamp(value, 0, 1) else KiAuraConfig.DefaultIntensity
	end

	local function popAmount(): number
		if popAge >= KiAuraConfig.PopTime then
			return 0
		end
		local t = popAge / KiAuraConfig.PopTime
		return (1 - t) * (1 - t)
	end

	local function applyScale()
		local rateScale = lerp(KiAuraConfig.MinRateScale, 1, intensity) * (emitScale or 1)
		local sizeScale = lerp(KiAuraConfig.MinSizeScale, 1, intensity)
			* (1 + (KiAuraConfig.PopScale - 1) * popAmount())
		local heightScale = lerp(KiAuraConfig.MinHeightScale, 1, intensity)
		for _, entry in rig.Emitters do
			local e = entry.Emitter
			e.Rate = entry.Rate * rateScale
			e.Size = scaled(entry.Size, sizeScale)
			if entry.Lifts then
				e.Speed = NumberRange.new(entry.Speed.Min * heightScale, entry.Speed.Max * heightScale)
			end
		end
	end

	local function recolor()
		local main = rootPart:GetAttribute(KiAuraConfig.ColorAttribute)
		local accent = rootPart:GetAttribute(KiAuraConfig.AccentAttribute)
		Palette.Apply(
			rig,
			if typeof(main) == "Color3" then main else KiAuraConfig.DefaultColor,
			if typeof(accent) == "Color3" then accent else nil
		)
	end

	local function setEmitting(isOn: boolean)
		for _, entry in rig.Emitters do
			entry.Emitter.Enabled = isOn and entry.Rate > 0
		end
	end

	local function burst()
		for _, entry in rig.Emitters do
			entry.Emitter:Emit(math.ceil(entry.Burst * (emitScale or 1)))
		end
	end

	local function refreshEnabled()
		local isOn = rootPart:GetAttribute(KiAuraConfig.EnabledAttribute) == true
		if isOn == isEnabled then
			return
		end
		isEnabled = isOn
		if isOn then
			popAge = 0
			pulseClock = 0
			applyScale()
			setEmitting(true)
			burst()
			rig.Light.Enabled = true
		else
			popAge = math.huge
			setEmitting(false)
		end
	end

	local function step(dt: number)
		if not isEnabled and visibility <= 0 then
			return
		end
		clock += dt
		local wasPopping = popAge < KiAuraConfig.PopTime
		popAge += dt
		if wasPopping then
			applyScale()
		end
		local target = if isEnabled then 1 else 0
		visibility =
			math.clamp(visibility + math.sign(target - visibility) * dt / KiAuraConfig.FadeTime, 0, 1)
		local pop = popAmount()
		local flicker = 1 - KiAuraConfig.FlickerAmount * (0.5 + math.noise(clock * 9, 0.37))
		local lightScale = lerp(KiAuraConfig.MinLightScale, 1, intensity)
		rig.Light.Brightness = KiAuraConfig.LightBrightness
			* lightScale
			* visibility
			* flicker
			* (1 + (KiAuraConfig.PopLight - 1) * pop)
		local sway = KiAuraConfig.SwayAmount
		for i, entry in rig.Emitters do
			if entry.Sways then
				entry.Emitter.Acceleration = entry.Acceleration
					+ Vector3.new(
						math.noise(clock * 3, i * 0.31) * sway,
						0,
						math.noise(clock * 2.5, i * 0.31 + 7) * sway
					)
			end
		end
		if visibility <= 0 then
			rig.Light.Enabled = false
		end
		if isEnabled and rig.Shockwave then
			pulseClock += dt
			if pulseClock >= lerp(KiAuraConfig.PulsePeriodSlow, KiAuraConfig.PulsePeriodFast, intensity) then
				pulseClock = 0
				rig.Shockwave:Emit(1)
			end
		end
	end

	readIntensity()
	recolor()
	applyScale()
	trove:Connect(rootPart:GetAttributeChangedSignal(KiAuraConfig.ColorAttribute), recolor)
	trove:Connect(rootPart:GetAttributeChangedSignal(KiAuraConfig.AccentAttribute), recolor)
	trove:Connect(rootPart:GetAttributeChangedSignal(KiAuraConfig.IntensityAttribute), function()
		readIntensity()
		applyScale()
	end)
	trove:Connect(rootPart:GetAttributeChangedSignal(KiAuraConfig.EnabledAttribute), refreshEnabled)
	trove:Connect(if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat, step)

	local aura = {} :: Aura
	aura.Character = character
	aura.Root = rootPart
	function aura.SetEnabled(_self: Aura, isOn: boolean)
		rootPart:SetAttribute(KiAuraConfig.EnabledAttribute, isOn)
	end
	local isDestroyed = false
	local function destroy()
		if isDestroyed then
			return
		end
		isDestroyed = true
		trove:Destroy()
	end
	function aura.Destroy(_self: Aura)
		destroy()
	end
	trove:Connect(character.Destroying, destroy)
	refreshEnabled()
	return aura
end

return KiAura
