--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local Analytics = require(ServerScriptService.Utils.Analytics)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Types = require(script.Parent.Types)

local Purchasing = {}

function Purchasing.UnopenedCount(data: any): number
	local total = 0
	for _, count in data.Geodes do
		total += count
	end
	return total
end

function Purchasing.Buy(context: Types.Context, player: Player, geodeKey: any, amount: any): boolean
	if
		type(geodeKey) ~= "string"
		or type(amount) ~= "number"
		or not table.find(GeodeConfig.BuyAmounts, amount)
	then
		return false
	end
	local geode = GeodeConfig.Geodes[geodeKey]
	local dataService = context.Services.DataService
	local data = dataService:GetData(player)
	if
		not geode
		or geode.RobuxOnly
		or not data
		or not Tutorial.CanBuyGeode(Tutorial.StepOf(data.Tutorial))
	then
		return false
	end
	if data.Strength < geode.StrengthRequired then
		return false
	end
	local unopened = Purchasing.UnopenedCount(data)
	local size = context.Services.PassService:GetBackpackSize(player)
	if context.Services.PetService:Count(player) + unopened + amount > size then
		return false
	end
	local price = Tutorial.GeodeCost(Tutorial.StepOf(data.Tutorial), geodeKey, amount)
	if data.Cash < price then
		return false
	end
	local isFirst = unopened == 0 and next(data.Index.Pets) == nil
	dataService:Set(player, { "Cash" }, data.Cash - price)
	Analytics.LogCash(player, AnalyticsConfig.Sinks.Geode, -price, data.Cash, geodeKey)
	dataService:Set(player, { "Geodes", geodeKey }, (data.Geodes[geodeKey] or 0) + amount)
	dataService:RequestSave(player)
	local notifications = context.Services.NotificationService
	notifications:Notify(
		player,
		"Purchase",
		if amount == 1 then `Bought a {geode.DisplayName}!` else `Bought {amount} {geode.DisplayName}s!`
	)
	if isFirst then
		notifications:Notify(player, "Info", "Crack it at your base!")
	end
	print(`[GeodeService] {player.Name} bought {amount} {geodeKey} for {price}`)
	return true
end

return Purchasing
