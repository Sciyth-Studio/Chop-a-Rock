--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopAnimationConfig = require(ReplicatedStorage.Config.ChopAnimationConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

export type Mode = "None" | "WindUp" | "Strike"

export type Tracks = {
	WindUp: AnimationTrack?,
	Strike: AnimationTrack?,
	Mode: Mode,
}

local ChopAnimation = {}

local function load(animator: Animator, key: string, isLooped: boolean): AnimationTrack?
	local animation = AssetRegistry.get(key)
	if not animation:IsA("Animation") or animation.AnimationId == "" then
		return nil
	end
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = isLooped
	return track
end

function ChopAnimation.Load(character: Model, timeout: number): Tracks?
	local humanoid = character:WaitForChild("Humanoid", timeout)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return nil
	end
	local animator = humanoid:WaitForChild("Animator", timeout)
	if not animator or not animator:IsA("Animator") then
		return nil
	end
	return {
		WindUp = load(animator, "Anim_Chop_WindUp", true),
		Strike = load(animator, "Anim_Chop_Strike", false),
		Mode = "None",
	}
end

function ChopAnimation.StrikeLeadSeconds(): number
	return math.max(ChopAnimationConfig.StrikeImpactSeconds - ChopAnimationConfig.StrikeStartSeconds, 0)
		/ ChopAnimationConfig.StrikeSpeed
end

function ChopAnimation.TrainingMode(secondsSinceChop: number, hasChopped: boolean): Mode
	if hasChopped and secondsSinceChop < ChopAnimationConfig.StrikeHoldSeconds then
		return "Strike"
	end
	if secondsSinceChop >= TrainingConfig.ChopIntervalSeconds - ChopAnimation.StrikeLeadSeconds() then
		return "Strike"
	end
	return "WindUp"
end

function ChopAnimation.LoopMode(clock: number): Mode
	local interval = TrainingConfig.ChopIntervalSeconds
	return ChopAnimation.TrainingMode(clock % interval, true)
end

function ChopAnimation.SetMode(tracks: Tracks, mode: Mode)
	if tracks.Mode == mode then
		return
	end
	tracks.Mode = mode
	local fade = ChopAnimationConfig.FadeSeconds
	local windUp = tracks.WindUp
	local strike = tracks.Strike
	if mode == "WindUp" then
		if strike and strike.IsPlaying then
			strike:Stop(fade)
		end
		if windUp then
			windUp:Play(fade, 1, ChopAnimationConfig.WindUpSpeed)
		end
	elseif mode == "Strike" then
		if windUp and windUp.IsPlaying then
			windUp:Stop(fade)
		end
		if strike then
			strike:Play(fade, 1, ChopAnimationConfig.StrikeSpeed)
			strike.TimePosition = ChopAnimationConfig.StrikeStartSeconds
		end
	else
		if windUp and windUp.IsPlaying then
			windUp:Stop(fade)
		end
		if strike and strike.IsPlaying then
			strike:Stop(fade)
		end
	end
end

function ChopAnimation.HoldStrikeEnd(tracks: Tracks)
	local strike = tracks.Strike
	if tracks.Mode ~= "Strike" or not strike or not strike.IsPlaying or strike.Speed == 0 then
		return
	end
	if strike.TimePosition >= strike.Length - ChopAnimationConfig.StrikeEndMarginSeconds then
		strike:AdjustSpeed(0)
	end
end

return ChopAnimation
