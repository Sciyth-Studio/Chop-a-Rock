--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local Types = require(script.Parent.Types)

local Earnings = {}

function Earnings.New(): Types.Session
	return { Rate = 0, Carry = 0, Unlogged = 0 }
end

function Earnings.Tick(session: Types.Session, seconds: number): number
	local total = session.Carry + session.Rate * seconds
	local amount = math.floor(total)
	session.Carry = total - amount
	session.Unlogged += amount
	return amount
end

function Earnings.TakeUnlogged(session: Types.Session): number
	local amount = session.Unlogged
	session.Unlogged = 0
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
