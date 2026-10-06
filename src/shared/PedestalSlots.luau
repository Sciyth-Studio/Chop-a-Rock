--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)

local PedestalSlots = {}

function PedestalSlots.Total(): number
	return #PedestalConfig.UnlockOrder
end

function PedestalSlots.Unlocked(count: number): { number }
	local slots: { number } = {}
	for index = 1, math.min(count, PedestalSlots.Total()) do
		table.insert(slots, PedestalConfig.UnlockOrder[index])
	end
	return slots
end

function PedestalSlots.IsUnlocked(count: number, slot: number): boolean
	return table.find(PedestalSlots.Unlocked(count), slot) ~= nil
end

function PedestalSlots.Next(count: number): (number?, number?)
	local nextCount = count + 1
	if nextCount > PedestalSlots.Total() then
		return nil, nil
	end
	return PedestalConfig.UnlockOrder[nextCount], PedestalConfig.SlotPrices[nextCount]
end

function PedestalSlots.Placed(pets: { [string]: any }): { [number]: string }
	local placed: { [number]: string } = {}
	for id, pet in pets do
		if type(pet) == "table" and type(pet.Slot) == "number" then
			placed[pet.Slot] = id
		end
	end
	return placed
end

return PedestalSlots
