--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local Types = require(script.Parent.Types)

local Fight = {}

function Fight.New(
	zone: string,
	anchor: Vector3,
	now: number,
	strength: number,
	isGentle: boolean,
	onResult: (result: Types.Result) -> ()
): Types.Fight
	local maxHealth = if isGentle then EnemyConfig.TutorialFightHits else EnemyConfig.FightHits
	local startsAt = now + EnemyRules.IntroSeconds()
	return {
		Zone = zone,
		Anchor = anchor,
		LeaveStuds = EnemyRules.LeaveStuds(zone),
		MaxHealth = maxHealth,
		Health = maxHealth,
		StartsAt = startsAt,
		Deadline = if isGentle then math.huge else startsAt + EnemyConfig.FightSeconds,
		StrengthRatio = strength / math.max(EnemyRules.WeakestRock(zone), 1),
		Center = 0.5,
		RoundStart = nil,
		Round = 0,
		IsGentle = isGentle,
		IsOver = false,
		ShownAt = 0,
		OnResult = onResult,
	}
end

function Fight.HasStarted(fight: Types.Fight, now: number): boolean
	return now >= fight.StartsAt
end

function Fight.IsOutOfTime(fight: Types.Fight, now: number): boolean
	return now >= fight.Deadline
end

function Fight.Quality(fight: Types.Fight, quality: number): number
	if fight.IsGentle then
		return math.max(quality, ChopQuality.Good)
	end
	return quality
end

function Fight.Hit(fight: Types.Fight, quality: number): (number, boolean)
	local damage = EnemyConfig.HitsByQuality[quality] or 0
	if quality == ChopQuality.Master then
		damage = fight.Health
	end
	fight.Health = math.max(fight.Health - damage, 0)
	return damage, fight.Health <= 0
end

function Fight.HasLeft(fight: Types.Fight, position: Vector3?): boolean
	return position == nil or (position - fight.Anchor).Magnitude > fight.LeaveStuds
end

function Fight.TakeShown(fight: Types.Fight, now: number): boolean
	if now - fight.ShownAt < EnemyConfig.OthersEffectSeconds then
		return false
	end
	fight.ShownAt = now
	return true
end

return Fight
