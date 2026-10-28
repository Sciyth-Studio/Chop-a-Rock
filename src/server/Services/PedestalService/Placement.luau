--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local Types = require(script.Parent.Types)

local Placement = {}

local function setSlot(context: Types.Context, player: Player, petId: string, slot: number?)
	local replica = context.Services.DataService:GetReplica(player)
	if replica then
		replica:Set({ "Pets", petId, "Slot" }, slot)
	end
end

function Placement.Sanitize(context: Types.Context, player: Player)
	local data = context.Services.DataService:GetData(player)
	if not data then
		return
	end
	local taken: { [number]: boolean } = {}
	local ids: { string } = {}
	for id in data.Pets do
		table.insert(ids, id)
	end
	table.sort(ids, function(a: string, b: string)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	for _, id in ids do
		local slot = data.Pets[id].Slot
		if slot == nil then
			continue
		end
		if taken[slot] or not PedestalSlots.IsUnlocked(data.PedestalSlots, slot) then
			setSlot(context, player, id, nil)
		else
			taken[slot] = true
		end
	end
end

function Placement.Place(context: Types.Context, player: Player, slot: number, petId: string): boolean
	local data = context.Services.DataService:GetData(player)
	local pet = if data then data.Pets[petId] else nil
	if not data or not pet or pet.Slot ~= nil or not PetConfig.Pets[pet.Key] then
		return false
	end
	if not PedestalSlots.IsUnlocked(data.PedestalSlots, slot) or PedestalSlots.Placed(data.Pets)[slot] then
		return false
	end
	setSlot(context, player, petId, slot)
	return true
end

function Placement.PickUp(context: Types.Context, player: Player, slot: number): boolean
	local data = context.Services.DataService:GetData(player)
	local petId = if data then PedestalSlots.Placed(data.Pets)[slot] else nil
	if not petId then
		return false
	end
	setSlot(context, player, petId, nil)
	return true
end

function Placement.EquipBest(context: Types.Context, player: Player): boolean
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	local unlocked = PedestalSlots.Unlocked(data.PedestalSlots)
	local ids: { string } = {}
	for id, pet in data.Pets do
		if PetConfig.Pets[pet.Key] then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a: string, b: string)
		local petA, petB = data.Pets[a], data.Pets[b]
		local rateA, rateB = services.PetService:GetRate(petA), services.PetService:GetRate(petB)
		if rateA ~= rateB then
			return rateA > rateB
		end
		if (petA.Slot ~= nil) ~= (petB.Slot ~= nil) then
			return petA.Slot ~= nil
		end
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	local chosen: { [string]: boolean } = {}
	for index = 1, math.min(#unlocked, #ids) do
		chosen[ids[index]] = true
	end
	local occupied: { [number]: boolean } = {}
	for id, pet in data.Pets do
		if pet.Slot ~= nil then
			if chosen[id] and table.find(unlocked, pet.Slot) then
				occupied[pet.Slot] = true
			else
				setSlot(context, player, id, nil)
			end
		end
	end
	for index = 1, math.min(#unlocked, #ids) do
		local id = ids[index]
		if data.Pets[id].Slot == nil then
			for _, slot in unlocked do
				if not occupied[slot] then
					occupied[slot] = true
					setSlot(context, player, id, slot)
					break
				end
			end
		end
	end
	return true
end

function Placement.BuySlot(context: Types.Context, player: Player): boolean
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	local slot, price = PedestalSlots.Next(data.PedestalSlots)
	if not slot or not price then
		return false
	end
	if data.Cash < price then
		services.NotificationService:Notify(player, "Error", "Not enough money!")
		return false
	end
	if
		not services.DataService:AdjustCash(
			player,
			-price,
			AnalyticsConfig.Sinks.PedestalSlot,
			tostring(slot)
		)
	then
		return false
	end
	services.DataService:Set(player, { "PedestalSlots" }, data.PedestalSlots + 1)
	services.NotificationService:Notify(player, "Purchase", "New pedestal unlocked!")
	return true
end

return Placement
