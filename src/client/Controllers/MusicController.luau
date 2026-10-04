--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local MusicConfig = require(ReplicatedStorage.Config.MusicConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local soundGroupName = "Music"

local MusicController = {
	Name = "MusicController",
	_trove = nil :: TroveInstance?,
}

local function getTracks(folder: Instance): { Sound }
	local tracks: { Sound } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("Sound") then
			table.insert(tracks, child)
		end
	end
	return tracks
end

local function pickTrack(tracks: { Sound }, last: Sound?): Sound
	if #tracks == 1 then
		return tracks[1]
	end
	local choices: { Sound } = {}
	for _, track in tracks do
		if track ~= last then
			table.insert(choices, track)
		end
	end
	return choices[math.random(1, #choices)]
end

function MusicController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function MusicController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local folder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild(MusicConfig.FolderName)

	local current: Sound? = nil
	local last: Sound? = nil
	local token = 0
	local isStopped = false
	local isWaiting = false

	local function stopCurrent()
		if current then
			current:Destroy()
			current = nil
		end
	end

	local playNext: () -> ()

	local function waitForTrack()
		if isWaiting then
			return
		end
		isWaiting = true
		local connection: RBXScriptConnection
		connection = folder.ChildAdded:Connect(function(child)
			if child:IsA("Sound") then
				connection:Disconnect()
				isWaiting = false
				playNext()
			end
		end)
		trove:Add(connection)
	end

	function playNext()
		if isStopped then
			return
		end
		stopCurrent()
		local tracks = getTracks(folder)
		if #tracks == 0 then
			waitForTrack()
			return
		end
		token += 1
		local playing = token
		local track = pickTrack(tracks, last)
		last = track

		local sound = track:Clone()
		sound.Name = "MusicPlaylist"
		sound.Looped = false
		sound.Volume = 0
		local group = SoundService:FindFirstChild(soundGroupName)
		if group and group:IsA("SoundGroup") then
			sound.SoundGroup = group
		end
		sound.Parent = SoundService
		current = sound
		sound.Ended:Connect(function()
			if playing == token then
				playNext()
			end
		end)
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(MusicConfig.FadeInSeconds), { Volume = track.Volume }):Play()
		task.delay(MusicConfig.LoadTimeoutSeconds, function()
			if playing == token and not sound.IsLoaded then
				warn(`[MusicController] Track "{track.Name}" failed to load; skipping`)
				playNext()
			end
		end)
	end

	trove:Add(function()
		isStopped = true
		stopCurrent()
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
