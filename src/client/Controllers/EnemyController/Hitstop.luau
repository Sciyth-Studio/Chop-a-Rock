--!strict

local Hitstop = {}

function Hitstop.Character(character: Model, seconds: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not animator then
		return
	end
	local frozen: { [AnimationTrack]: number } = {}
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Speed ~= 0 then
			frozen[track] = track.Speed
			track:AdjustSpeed(0)
		end
	end
	task.delay(seconds, function()
		for track, speed in frozen do
			if track.IsPlaying and track.Speed == 0 then
				track:AdjustSpeed(speed)
			end
		end
	end)
end

return Hitstop
