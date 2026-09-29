--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)

local LocalSound = {}

function LocalSound.Play(key: string)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	SoundService:PlayLocalSound(asset)
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

return LocalSound
