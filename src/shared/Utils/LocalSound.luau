--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)

local LocalSound = {}

function LocalSound.Play(key: string, startSeconds: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	if startSeconds then
		asset.Parent = SoundService
		asset.TimePosition = startSeconds
		asset:Play()
	else
		SoundService:PlayLocalSound(asset)
	end
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

return LocalSound
