--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
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
	local after = before + math.max(0, math.floor(delta))
	DataService:Set(player, { "Strength" }, after)
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for _, rock in rocks do
		if before < rock.StrengthRequired and after >= rock.StrengthRequired then
			NotificationService:Notify(player, "Unlock", `{rock.DisplayName} unlocked!`)
		end
	end
	return after
end

function StatsService.Init(_self: any, _services: { [string]: any }) end

function StatsService.Start(_self: any) end

function StatsService.Destroy(_self: any) end

return StatsService
