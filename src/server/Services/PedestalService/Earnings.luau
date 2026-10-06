--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local Types = require(script.Parent.Types)

local Earnings = {}

function Earnings.Now(): number
	return workspace:GetServerTimeNow()
end

function Earnings.New(banked: number, now: number): Types.SlotEarnings
	return { Rate = 0, Banked = banked, BankedAt = now }
end

function Earnings.Current(slot: Types.SlotEarnings, now: number): number
	return slot.Banked + slot.Rate * math.max(0, now - slot.BankedAt)
end

function Earnings.SetRate(slot: Types.SlotEarnings, rate: number, now: number)
	if slot.Rate == rate then
		return
	end
	slot.Banked = Earnings.Current(slot, now)
	slot.BankedAt = now
	slot.Rate = rate
end

function Earnings.Take(slot: Types.SlotEarnings, now: number): number
	local current = Earnings.Current(slot, now)
	local amount = math.floor(current)
	slot.Banked = current - amount
	slot.BankedAt = now
	return amount
end

function Earnings.OfflineSeconds(lastSeenAt: number, nowUnix: number): number
	if lastSeenAt <= 0 then
		return 0
	end
	return math.clamp(nowUnix - lastSeenAt, 0, EconomyConfig.OfflineCapSeconds)
end

function Earnings.Offline(rate: number, seconds: number): number
	return rate * seconds * PedestalConfig.OfflineRateMultiplier
end

return Earnings
