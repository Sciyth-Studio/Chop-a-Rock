--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local Audio = {}

local function tracks(): { Sound }
	local found: { Sound } = {}
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local sounds = if assets then assets:FindFirstChild("Sounds") else nil
	local folder = if sounds then sounds:FindFirstChild(EnemyConfig.FightMusicFolderName, true) else nil
	if not folder then
		return found
	end
	for _, child in folder:GetChildren() do
		if child:IsA("Sound") then
			table.insert(found, child)
		end
	end
	return found
end

function Audio.SpeedUp(sound: Sound)
	local speed = 2 ^ (EnemyConfig.MusicSpeedUpSemitones / 12)
	TweenService:Create(sound, TweenInfo.new(EnemyConfig.MusicSpeedUpSeconds), { PlaybackSpeed = speed })
		:Play()
end

function Audio.Muffle(sound: Sound)
	local equalizer = Instance.new("EqualizerSoundEffect")
	equalizer.Name = "EnemyFightMuffle"
	equalizer.HighGain = 0
	equalizer.MidGain = 0
	equalizer.LowGain = 0
	equalizer.Parent = sound
	local info = TweenInfo.new(EnemyConfig.MuffleSeconds)
	TweenService:Create(equalizer, info, {
		HighGain = EnemyConfig.MuffleHighGain,
		MidGain = EnemyConfig.MuffleMidGain,
	}):Play()
end

function Audio.StartMusic(trove: TroveInstance, musicController: any): Sound?
	local choices = tracks()
	if #choices == 0 then
		return nil
	end
	trove:Add(musicController:Hold())
	local track = choices[math.random(1, #choices)]
	local sound = track:Clone()
	sound.Name = "EnemyFightMusic"
	sound.Looped = true
	sound.Volume = 0
	local start = track:GetAttribute(EnemyConfig.MusicStartAttribute)
	if type(start) == "number" then
		sound.TimePosition = start
	end
	local group = SoundService:FindFirstChild(EnemyConfig.MusicGroupName)
	if group and group:IsA("SoundGroup") then
		sound.SoundGroup = group
	end
	sound.Parent = SoundService
	sound:Play()
	local fadeIn = TweenInfo.new(EnemyConfig.MusicFadeInSeconds)
	TweenService:Create(sound, fadeIn, { Volume = track.Volume }):Play()
	trove:Add(function()
		local fadeOut =
			TweenService:Create(sound, TweenInfo.new(EnemyConfig.MusicFadeOutSeconds), { Volume = 0 })
		fadeOut.Completed:Once(function()
			sound:Destroy()
		end)
		fadeOut:Play()
	end)
	return sound
end

function Audio.Play(key: string)
	LocalSound.Play(key)
end

-- Each zone's Guardian has its own call (fight start) and hurt sound (each hit), named after the zone's Pet.
function Audio.Guardian(zone: string, format: string, fallbackKey: string?)
	local petKey = EnemyConfig.PetKeys[zone]
	if petKey then
		LocalSound.Play(string.format(format, petKey))
	elseif fallbackKey then
		LocalSound.Play(fallbackKey)
	end
end

return Audio
