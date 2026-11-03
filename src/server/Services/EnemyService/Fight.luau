--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local Types = require(script.Parent.Types)

local Fight = {}

local roundingShare = 1e-9

function Fight.New(
	zone: string,
	anchor: Vector3,
	now: number,
	onResult: (result: Types.Result) -> ()
): Types.Fight
	local maxHealth = EnemyRules.MaxHealth(zone)
	return {
		Zone = zone,
		Anchor = anchor,
		LeaveStuds = EnemyRules.LeaveStuds(zone),
		MaxHealth = maxHealth,
		Health = maxHealth * EnemyConfig.StartShare,
		PushedAt = now,
		ShownAt = 0,
		OnResult = onResult,
	}
end

function Fight.Push(fight: Types.Fight, now: number): boolean
	local elapsed = now - fight.PushedAt
	fight.PushedAt = now
	fight.Health =
		math.min(fight.Health + fight.MaxHealth * EnemyConfig.PushSharePerSecond * elapsed, fight.MaxHealth)
	return fight.Health >= fight.MaxHealth
end

function Fight.Hit(fight: Types.Fight, strength: number): boolean
	fight.Health = math.max(fight.Health - math.max(strength, 0), 0)
	if fight.Health <= fight.MaxHealth * roundingShare then
		fight.Health = 0
		return true
	end
	return false
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
