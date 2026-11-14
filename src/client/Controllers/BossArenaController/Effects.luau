--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)

local Themes = BossConfig.ArenaThemes

local Effects = {}

local rumbleName = "BossArenaRumble"
local random = Random.new()
local grind: Sound? = nil

local function stopGrind(fadeSeconds: number)
	local sound = grind
	grind = nil
	if not sound then
		return
	end
	local fade = TweenService:Create(sound, TweenInfo.new(fadeSeconds), { Volume = 0 })
	fade.Completed:Once(function()
		sound:Destroy()
	end)
	fade:Play()
end

local function playGrind(seconds: number, centre: Vector3)
	stopGrind(Themes.GrindFadeSeconds)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local focus = camera.Focus.Position - centre
	if Vector2.new(focus.X, focus.Z).Magnitude > Themes.ShakeRangeStuds then
		return
	end
	local asset = AssetRegistry.get(Themes.GrindSoundKey)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	asset.Looped = true
	asset.Parent = SoundService
	asset:Play()
	grind = asset
	task.delay(math.max(seconds - Themes.GrindFadeSeconds, 0), function()
		if grind == asset then
			stopGrind(Themes.GrindFadeSeconds)
		end
	end)
end

local function scaleSequence(sequence: NumberSequence, scale: number): NumberSequence
	local points = {}
	for _, point in sequence.Keypoints do
		table.insert(
			points,
			NumberSequenceKeypoint.new(point.Time, point.Value * scale, point.Envelope * scale)
		)
	end
	return NumberSequence.new(points)
end

function Effects.Puff(template: Model, parent: Instance, position: Vector3, scale: number, color: Color3)
	local clone = template:Clone()
	clone:PivotTo(CFrame.new(position))
	local emitters: { ParticleEmitter } = {}
	local speedScale = math.sqrt(scale)
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Size = scaleSequence(descendant.Size, scale)
			descendant.Speed =
				NumberRange.new(descendant.Speed.Min * speedScale, descendant.Speed.Max * speedScale)
			local darken = descendant:GetAttribute("Darken")
			local amount = if type(darken) == "number" then darken else 0
			descendant.Color = ColorSequence.new(color:Lerp(Color3.new(0, 0, 0), amount))
			table.insert(emitters, descendant)
		end
	end
	clone.Parent = parent
	local countScale = LowGraphics.EmitScale() * math.min(scale, 1.5)
	for _, emitter in emitters do
		local count = emitter:GetAttribute("EmitCount")
		local base = if type(count) == "number" then count else 6
		emitter:Emit(math.max(1, math.round(base * countScale)))
	end
	Debris:AddItem(clone, Themes.DustLifetimeSeconds)
end

function Effects.DustScale(width: number): number
	return math.clamp(width / Themes.DustWidthStuds, Themes.DustScaleMin, Themes.DustScaleMax)
end

function Effects.Rumble(seconds: number, centre: Vector3)
	local started = os.clock()
	playGrind(seconds, centre)
	RunService:UnbindFromRenderStep(rumbleName)
	RunService:BindToRenderStep(rumbleName, Enum.RenderPriority.Camera.Value + 1, function()
		local elapsed = os.clock() - started
		if elapsed > seconds then
			RunService:UnbindFromRenderStep(rumbleName)
			return
		end
		local camera = workspace.CurrentCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Custom then
			return
		end
		local focus = camera.Focus.Position - centre
		if Vector2.new(focus.X, focus.Z).Magnitude > Themes.ShakeRangeStuds then
			return
		end
		local amount = Themes.ShakeStuds * (0.4 + 0.6 * (1 - elapsed / seconds))
		camera.CFrame *= CFrame.new(random:NextNumber(-1, 1) * amount, random:NextNumber(-1, 1) * amount, 0)
	end)
end

function Effects.StopRumble()
	RunService:UnbindFromRenderStep(rumbleName)
	stopGrind(0)
end

return Effects
