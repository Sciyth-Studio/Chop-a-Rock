--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local Week = require(ReplicatedStorage.Utils.Week)
local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)

local StatsService = {
	Name = "StatsService",
}

local weekOffset = 0

function StatsService.GetWeek(_self: any): number
	return Week.Current(nil, weekOffset)
end

function StatsService.GetWeekEndsAt(_self: any): number
	return Week.EndsAt(StatsService:GetWeek(), weekOffset)
end

function StatsService.SetWeekOffset(_self: any, offset: number)
	weekOffset = offset
end

function StatsService.GetWeekly(_self: any, player: Player): { [string]: number }?
	local data = DataService:GetData(player)
	if not data then
		return nil
	end
	local week = StatsService:GetWeek()
	if data.Weekly.Week ~= week then
		DataService:Set(
			player,
			{ "Weekly" },
			{ Week = week, Strength = 0, PerfectChops = 0, Playtime = 0, MoneyPerSecond = 0 }
		)
	end
	return data.Weekly :: any
end

function StatsService.AddWeekly(_self: any, player: Player, key: string, amount: number)
	local weekly = StatsService:GetWeekly(player)
	if weekly and amount > 0 then
		DataService:Set(player, { "Weekly", key }, weekly[key] + amount)
	end
end

function StatsService.RaiseWeekly(_self: any, player: Player, key: string, value: number)
	local weekly = StatsService:GetWeekly(player)
	if weekly and value > weekly[key] then
		DataService:Set(player, { "Weekly", key }, value)
	end
end

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
	if after > data.PeakStrength then
		DataService:Set(player, { "PeakStrength" }, after)
	end
	DataService:Set(player, { "Strength" }, after)
	StatsService:AddWeekly(player, "Strength", after - before)
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
		StatsService:AddWeekly(player, "PerfectChops", 1)
	end
end

function StatsService.SetStrength(_self: any, player: Player, strength: number): boolean
	if not DataService:GetData(player) then
		return false
	end
	local value = math.max(0, math.floor(strength))
	DataService:Set(player, { "PeakStrength" }, value)
	DataService:Set(player, { "Strength" }, value)
	return DataService:RequestSave(player)
end

function StatsService.Init(_self: any, _services: { [string]: any }) end

function StatsService.Start(_self: any) end

function StatsService.Destroy(_self: any) end

return StatsService
