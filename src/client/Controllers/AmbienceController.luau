--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local AmbienceConfig = require(ReplicatedStorage.Config.AmbienceConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ZoneAt = require(ReplicatedStorage.Utils.ZoneAt)

type TroveInstance = typeof(Trove.new())

local AmbienceController = {
	Name = "AmbienceController",
	_trove = nil :: TroveInstance?,
}

local function fadeOut(sound: Sound)
	local tween = TweenService:Create(sound, TweenInfo.new(AmbienceConfig.FadeSeconds), { Volume = 0 })
	tween.Completed:Once(function()
		sound:Destroy()
	end)
	tween:Play()
end

function AmbienceController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function AmbienceController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local folder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild(AmbienceConfig.FolderName)
	local group = SoundService:FindFirstChild(AmbienceConfig.SoundGroupName)

	local zone = ""
	local current: Sound? = nil

	local function switch(nextZone: string)
		zone = nextZone
		if current then
			fadeOut(current)
			current = nil
		end
		local template = folder:FindFirstChild(nextZone)
		if not template or not template:IsA("Sound") then
			return
		end
		local sound = template:Clone()
		sound.Looped = true
		sound.Volume = 0
		if group and group:IsA("SoundGroup") then
			sound.SoundGroup = group
		end
		sound.Parent = SoundService
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(AmbienceConfig.FadeSeconds), { Volume = template.Volume })
			:Play()
		current = sound
	end

	local loop = task.spawn(function()
		while true do
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local nextZone = if root and root:IsA("BasePart") then ZoneAt(root.Position) else ""
			if nextZone ~= zone then
				switch(nextZone)
			end
			task.wait(AmbienceConfig.PollSeconds)
		end
	end)
	trove:Add(loop)
	trove:Add(function()
		if current then
			current:Destroy()
			current = nil
		end
	end)
end

function AmbienceController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return AmbienceController
