--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)

local Shake = {}

local count = 0

function Shake.Play(settings: CannonConfig.Shake): () -> ()
	count += 1
	local name = `CannonShake{count}`
	local camera = workspace.CurrentCamera
	local began = os.clock()
	local offset = CFrame.identity
	local stopped = false
	local function stop()
		if stopped then
			return
		end
		stopped = true
		RunService:UnbindFromRenderStep(`{name}Undo`)
		RunService:UnbindFromRenderStep(name)
		if camera then
			camera.CFrame *= offset:Inverse()
		end
		offset = CFrame.identity
	end
	if not camera then
		return stop
	end
	RunService:BindToRenderStep(`{name}Undo`, Enum.RenderPriority.Camera.Value - 1, function()
		camera.CFrame *= offset:Inverse()
		offset = CFrame.identity
	end)
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local elapsed = os.clock() - began
		if elapsed >= settings.Seconds then
			stop()
			return
		end
		local amplitude = math.rad(settings.Degrees) * (1 - elapsed / settings.Seconds)
		local phase = elapsed * settings.Frequency
		offset = CFrame.Angles(
			math.noise(phase, 0.31) * amplitude * 2,
			math.noise(phase, 0.67) * amplitude * 2,
			math.noise(phase, 0.93) * amplitude
		)
		camera.CFrame *= offset
	end)
	return stop
end

return Shake
