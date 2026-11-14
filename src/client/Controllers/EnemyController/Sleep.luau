--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Motion = require(script.Parent.Motion)

type State = {
	Snore: Sound?,
	NextSnort: number,
	NextGrumble: number,
	HasGrowled: boolean,
	LastTick: number,
}

local Sleep = {}

local states: { [string]: State } = {}

local function attach(key: string, parent: Instance, speed: number, isLooped: boolean): Sound?
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return nil
	end
	asset.PlaybackSpeed *= speed
	asset.Looped = isLooped
	asset.RollOffMode = Enum.RollOffMode.InverseTapered
	asset.RollOffMinDistance = EnemyConfig.SleepSoundMinStuds
	asset.RollOffMaxDistance = EnemyConfig.SleepSoundMaxStuds
	asset.Parent = parent
	asset:Play()
	if not isLooped then
		Debris:AddItem(asset, EnemyConfig.SleepSoundLifetimeSeconds)
	end
	return asset
end

local function voiceKey(zone: string, format: string): string?
	local petKey = EnemyConfig.PetKeys[zone]
	return if petKey then string.format(format, petKey) else nil
end

local function stopSnore(state: State)
	local snore = state.Snore
	if snore then
		snore:Destroy()
		state.Snore = nil
	end
end

function Sleep.Step(zone: string, enemy: Motion.Enemy, left: number, now: number)
	local anchor = enemy.Model.PrimaryPart or enemy.Model:FindFirstChildWhichIsA("BasePart", true)
	if not anchor then
		return
	end
	local state = states[zone]
	if not state then
		state = {
			Snore = nil,
			NextSnort = 0,
			NextGrumble = 0,
			HasGrowled = false,
			LastTick = math.huge,
		}
		states[zone] = state
	end
	if left > EnemyConfig.RollSeconds then
		if not state.Snore then
			state.Snore = attach(EnemyConfig.SnoreSoundKey, anchor, 1, true)
		end
		local snore = state.Snore
		if snore then
			snore.PlaybackSpeed = if left <= EnemyConfig.StirSeconds then EnemyConfig.SnoreStirSpeed else 1
		end
		if left <= EnemyConfig.StirSeconds and now >= state.NextSnort then
			state.NextSnort = now + EnemyConfig.SnortEverySeconds
			enemy.TwitchAt = now
			attach(EnemyConfig.SnortSoundKey, anchor, 1, false)
		end
	else
		stopSnore(state)
		if left > EnemyConfig.SitSeconds and now >= state.NextGrumble then
			state.NextGrumble = now + EnemyConfig.GrumbleEverySeconds
			enemy.TwitchAt = now
			local key = voiceKey(zone, EnemyConfig.GuardianHurtFormat)
			if key then
				attach(key, anchor, EnemyConfig.GrumbleSpeed, false)
			end
		elseif left <= EnemyConfig.SitSeconds and not state.HasGrowled then
			state.HasGrowled = true
			local key = voiceKey(zone, EnemyConfig.GuardianCallFormat)
			attach(key or EnemyConfig.RoarSoundKey, anchor, EnemyConfig.GrowlSpeed, false)
		end
	end
	local whole = math.ceil(left)
	if whole <= EnemyConfig.TickFromSeconds and whole < state.LastTick and whole > 0 then
		LocalSound.Play(EnemyConfig.TickSoundKey)
	end
	state.LastTick = whole
end

function Sleep.Stop(zone: string)
	local state = states[zone]
	if state then
		stopSnore(state)
		states[zone] = nil
	end
end

return Sleep
