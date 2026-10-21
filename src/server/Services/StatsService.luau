--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)

local StatsService = {
	Name = "StatsService",
}

function StatsService.GetStrength(_self: any, player: Player): number
	local data = DataService:GetData(player)
	return if data then data.Strength else 0
end

function StatsService.AddStrength(_self: any, player: Player, delta: number): number
	local data = DataService:GetData(player)
	if not data then
		return 0
	end
	local before = data.Strength
	local cap = RebirthStats.Get(data.Rebirths + 1).StrengthRequired
	local after = math.max(before, math.min(before + math.max(0, math.floor(delta)), cap))
	if after == before then
		return after
	end
	DataService:Set(player, { "Strength" }, after)
	if before < cap and after >= cap then
		NotificationService:Notify(player, "Unlock", "Rebirth ready! Rebirth to keep getting stronger")
	end
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for _, rock in rocks do
		if before < rock.StrengthRequired and after >= rock.StrengthRequired then
			NotificationService:Notify(player, "Unlock", `{rock.DisplayName} unlocked!`)
		end
	end
	return after
end

function StatsService.RecordChop(_self: any, player: Player, quality: number)
	if quality < ChopQuality.Perfect then
		return
	end
	local data = DataService:GetData(player)
	if data then
		DataService:Set(player, { "PerfectChops" }, data.PerfectChops + 1)
	end
end

function StatsService.SetStrength(_self: any, player: Player, strength: number): boolean
	if not DataService:GetData(player) then
		return false
	end
	DataService:Set(player, { "Strength" }, math.max(0, math.floor(strength)))
	return DataService:RequestSave(player)
end

function StatsService.Init(_self: any, _services: { [string]: any }) end

function StatsService.Start(_self: any) end

function StatsService.Destroy(_self: any) end

return StatsService
