--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local MusicConfig = require(ReplicatedStorage.Config.MusicConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local MusicController = {
	Name = "MusicController",
	_trove = nil :: TroveInstance?,
}

local function pickTrack(lastIndex: number?): number
	local count = #MusicConfig.Tracks
	if count <= 1 then
		return 1
	end
	local index = math.random(1, count - 1)
	if lastIndex and index >= lastIndex then
		index += 1
	end
	return index
end

function MusicController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function MusicController.Start(self: any)
	if #MusicConfig.Tracks == 0 then
		return
	end
	local trove = self._trove :: TroveInstance
	local sound = Instance.new("Sound")
	sound.Name = "MusicPlaylist"
	sound.Looped = false
	sound.Volume = 0
	sound.Parent = SoundService
	trove:Add(sound)

	local lastIndex: number? = nil
	local token = 0
	local isStopped = false

	local function playNext()
		if isStopped then
			return
		end
		token += 1
		local current = token
		local index = pickTrack(lastIndex)
		lastIndex = index
		sound.Volume = 0
		sound.SoundId = `rbxassetid://{MusicConfig.Tracks[index]}`
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(MusicConfig.FadeInSeconds), { Volume = MusicConfig.Volume })
			:Play()
		task.delay(MusicConfig.LoadTimeoutSeconds, function()
			if current == token and not sound.IsLoaded then
				warn(`[MusicController] Track {index} failed to load; skipping`)
				playNext()
			end
		end)
	end

	trove:Connect(sound.Ended, playNext)
	trove:Add(function()
		isStopped = true
	end)
	playNext()
end

function MusicController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return MusicController
