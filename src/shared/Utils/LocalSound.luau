--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)

local LocalSound = {}

function LocalSound.PlayInstance(sound: Sound, startSeconds: number?)
	if startSeconds then
		sound.TimePosition = startSeconds
	end
	if sound.TimePosition > 0 then
		sound.Parent = SoundService
		sound:Play()
	else
		SoundService:PlayLocalSound(sound)
	end
end

function LocalSound.Play(key: string, startSeconds: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	LocalSound.PlayInstance(asset, startSeconds)
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

return LocalSound
