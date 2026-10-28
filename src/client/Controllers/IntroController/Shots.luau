--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local IntroConfig = require(ReplicatedStorage.Config.IntroConfig)

export type Shot = (elapsed: number) -> CFrame

export type State = {
	Camera: Camera,
	Shot: Shot?,
	ShakeStuds: number,
	ShakeEnds: number,
	ShakeStarts: number,
	BaseFieldOfView: number,
	Effects: { ColorCorrectionEffect },
	Clock: () -> number,
}

local Shots = {}

local BIND_NAME = "IntroCutsceneCamera"

function Shots.Start(camera: Camera, clock: () -> number): State
	local state: State = {
		Camera = camera,
		Shot = nil,
		ShakeStuds = 0,
		ShakeEnds = 0,
		ShakeStarts = 0,
		BaseFieldOfView = camera.FieldOfView,
		Effects = {},
		Clock = clock,
	}
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = IntroConfig.FieldOfView
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		local shot = state.Shot
		if not shot then
			return
		end
		local elapsed = state.Clock()
		local cframe = shot(elapsed)
		if elapsed < state.ShakeEnds and state.ShakeStuds > 0 then
			local span = math.max(state.ShakeEnds - state.ShakeStarts, 1e-3)
			local decay = math.clamp((state.ShakeEnds - elapsed) / span, 0, 1)
			local amount = state.ShakeStuds * decay
			cframe *= CFrame.new(
				(math.random() * 2 - 1) * amount * 0.3,
				(math.random() * 2 - 1) * amount * 0.3,
				0
			) * CFrame.Angles(0, 0, math.rad((math.random() * 2 - 1) * amount))
		end
		camera.CFrame = cframe
	end)
	return state
end

function Shots.Set(state: State, shot: Shot)
	state.Shot = shot
end

function Shots.Shake(state: State, studs: number, seconds: number)
	local now = state.Clock()
	state.ShakeStuds = studs
	state.ShakeStarts = now
	state.ShakeEnds = now + seconds
end

function Shots.Punch(state: State)
	local camera = state.Camera
	camera.FieldOfView = IntroConfig.PunchFieldOfView
	TweenService:Create(
		camera,
		TweenInfo.new(IntroConfig.PunchSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ FieldOfView = IntroConfig.FieldOfView }
	):Play()
end

local function colorEffect(state: State, name: string): ColorCorrectionEffect
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = name
	effect.Parent = Lighting
	table.insert(state.Effects, effect)
	return effect
end

function Shots.Darken(state: State, seconds: number): ColorCorrectionEffect
	local effect = colorEffect(state, "IntroDarken")
	TweenService:Create(
		effect,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Brightness = IntroConfig.DarkenBrightness, Saturation = IntroConfig.DarkenSaturation }
	):Play()
	return effect
end

function Shots.Flash(state: State)
	local effect = colorEffect(state, "IntroFlash")
	effect.Brightness = IntroConfig.FlashBrightness
	effect.Contrast = IntroConfig.FlashContrast
	TweenService:Create(
		effect,
		TweenInfo.new(IntroConfig.FlashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0, Contrast = 0 }
	):Play()
end

function Shots.FadeIn(state: State): ColorCorrectionEffect
	local effect = colorEffect(state, "IntroFade")
	TweenService:Create(
		effect,
		TweenInfo.new(IntroConfig.FadeInSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Brightness = IntroConfig.FadeBrightness }
	):Play()
	return effect
end

function Shots.FadeOut(effect: ColorCorrectionEffect)
	TweenService:Create(
		effect,
		TweenInfo.new(IntroConfig.FadeOutSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }
	):Play()
end

function Shots.Ease(alpha: number): number
	local clamped = math.clamp(alpha, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
end

function Shots.Stop(state: State)
	RunService:UnbindFromRenderStep(BIND_NAME)
	state.Shot = nil
	for _, effect in state.Effects do
		effect:Destroy()
	end
	table.clear(state.Effects)
	state.Camera.FieldOfView = state.BaseFieldOfView
end

return Shots
