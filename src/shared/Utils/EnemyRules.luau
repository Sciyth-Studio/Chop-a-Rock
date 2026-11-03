--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)

local EnemyRules = {}

function EnemyRules.IsZone(zone: string): boolean
	return RockSpawnConfig.Zones[zone] ~= nil
end

function EnemyRules.WeakestRock(zone: string): number
	local spawnZone = RockSpawnConfig.Zones[zone]
	local weakest = math.huge
	if spawnZone then
		local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
		for key in spawnZone.Weights do
			local rock = configs[key]
			if rock then
				weakest = math.min(weakest, rock.StrengthRequired)
			end
		end
	end
	return weakest
end

function EnemyRules.MaxHealth(zone: string): number
	return EnemyRules.WeakestRock(zone) * EnemyConfig.HealthClicksAtGate
end

function EnemyRules.IntroSeconds(): number
	return EnemyConfig.IntroBannerSeconds + EnemyConfig.CountSeconds * EnemyConfig.CountFrom
end

function EnemyRules.IntroPhase(elapsed: number): ("Banner" | "Count" | "Fight", number)
	if elapsed < EnemyConfig.IntroBannerSeconds then
		return "Banner", 0
	end
	local counted = math.floor((elapsed - EnemyConfig.IntroBannerSeconds) / EnemyConfig.CountSeconds)
	if counted < EnemyConfig.CountFrom then
		return "Count", EnemyConfig.CountFrom - counted
	end
	return "Fight", 0
end

function EnemyRules.CanFight(strength: number, zone: string): boolean
	return strength >= EnemyRules.WeakestRock(zone)
end

function EnemyRules.Flees(strength: number, zone: string): boolean
	return strength >= EnemyRules.WeakestRock(zone) * EnemyConfig.FleeStrengthMultiplier
end

function EnemyRules.PetKey(zone: string): string
	return EnemyConfig.PetKeys[zone] or EnemyConfig.FallbackPetKey
end

function EnemyRules.ModelScale(zone: string): number
	return EnemyConfig.ModelScale * ZoneScale.Of(zone)
end

function EnemyRules.LeaveStuds(zone: string): number
	return EnemyConfig.LeaveStuds * ZoneScale.Of(zone)
end

return EnemyRules
