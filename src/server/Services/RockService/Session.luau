--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local Types = require(script.Parent.Types)

local Session = {}

local brokenEpsilon = 1e-6

function Session.New(rock: Types.Rock, canBreak: boolean, center: number, startTime: number): Types.Session
	local maxHealth = rock.Config.StrengthRequired * ChopConfig.HitsAtMinStrength
	return {
		Rock = rock,
		CanBreak = canBreak,
		Health = maxHealth,
		MaxHealth = maxHealth,
		Center = center,
		StartTime = startTime,
		Round = 0,
	}
end

function Session.DamageMultiplier(quality: number): number
	if quality == ChopQuality.Perfect then
		return ChopConfig.PerfectDamageMultiplier
	elseif quality == ChopQuality.Great then
		return ChopConfig.GreatDamageMultiplier
	elseif quality == ChopQuality.Good then
		return ChopConfig.GoodDamageMultiplier
	elseif quality == ChopQuality.Mid then
		return ChopConfig.MidDamageMultiplier
	end
	return ChopConfig.BadDamageMultiplier
end

function Session.PayoutMultiplier(quality: number): number
	if quality == ChopQuality.Perfect then
		return ChopConfig.PerfectPayoutMultiplier
	elseif quality == ChopQuality.Great then
		return ChopConfig.GreatPayoutMultiplier
	elseif quality == ChopQuality.Good then
		return ChopConfig.GoodPayoutMultiplier
	elseif quality == ChopQuality.Mid then
		return ChopConfig.MidPayoutMultiplier
	end
	return ChopConfig.BadPayoutMultiplier
end

function Session.Apply(session: Types.Session, strength: number, quality: number): (number, number)
	local damage = strength * Session.DamageMultiplier(quality)
	local applied = math.min(damage, session.Health)
	local share = applied / session.MaxHealth
	local payout = math.max(
		0,
		math.floor(session.Rock.Config.BasePayout * Session.PayoutMultiplier(quality) * share + 0.5)
	)
	session.Health -= applied
	return applied, payout
end

function Session.IsBroken(session: Types.Session): boolean
	return session.Health <= brokenEpsilon
end

return Session
