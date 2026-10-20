--!strict

local HatchOdds = require(script.Parent.HatchOdds)
local IndexConfig = require(script.Parent.Config.IndexConfig)
local PetConfig = require(script.Parent.Config.PetConfig)
local RockConfig = require(script.Parent.Config.RockConfig)

export type Claim = {
	Page: IndexConfig.Page,
	Zone: IndexConfig.Zone,
	Key: string?,
}

local IndexRewards = {}

local function lookup(index: any, path: { string }): any
	local node = index
	for _, key in path do
		if type(node) ~= "table" then
			return nil
		end
		node = node[key]
	end
	return node
end

function IndexRewards.FindPage(pageKey: string): IndexConfig.Page?
	for _, page in IndexConfig.Pages do
		if page.Key == pageKey then
			return page
		end
	end
	return nil
end

function IndexRewards.FindZone(page: IndexConfig.Page, zoneKey: string): IndexConfig.Zone?
	for _, zone in page.Zones do
		if zone.Key == zoneKey then
			return zone
		end
	end
	return nil
end

function IndexRewards.ZoneOf(page: IndexConfig.Page, key: string): IndexConfig.Zone?
	for _, zone in page.Zones do
		if table.find(zone.Entries, key) then
			return zone
		end
	end
	return nil
end

function IndexRewards.ZoneId(page: IndexConfig.Page, zone: IndexConfig.Zone): string
	return page.Key .. IndexConfig.ZoneKeySeparator .. zone.Key
end

local function toughestRock(zone: IndexConfig.Zone): RockConfig.Rock?
	local key = zone.Entries[#zone.Entries]
	return if key then RockConfig.Rocks[key] else nil
end

local function zoneScale(zoneKey: string): (number, number)
	for _, page in IndexConfig.Pages do
		if page.Kind ~= "Rocks" then
			continue
		end
		local base = page.Zones[1] and toughestRock(page.Zones[1])
		local zone = IndexRewards.FindZone(page, zoneKey)
		local rock = if zone then toughestRock(zone) else nil
		if base and rock then
			return rock.BasePayout / base.BasePayout, rock.StrengthRequired / base.StrengthRequired
		end
	end
	return 1, 1
end

function IndexRewards.Reward(page: IndexConfig.Page, key: string): IndexConfig.Reward?
	local base: IndexConfig.Reward? = nil
	if page.Kind == "Rocks" then
		base = if RockConfig.Rocks[key] then IndexConfig.RockReward else nil
	else
		local pet = PetConfig.Pets[key]
		base = if pet then IndexConfig.PetRewards[pet.Rarity] else nil
	end
	local zone = IndexRewards.ZoneOf(page, key)
	if not base or not zone then
		return base
	end
	local cashScale, strengthScale = zoneScale(zone.Key)
	return {
		Cash = math.floor(base.Cash * cashScale + 0.5),
		Strength = math.floor(base.Strength * strengthScale + 0.5),
	}
end

function IndexRewards.Count(index: any, page: IndexConfig.Page, key: string): number
	local count = lookup(index, { page.Kind, key })
	return if type(count) == "number" then count else 0
end

function IndexRewards.IsFound(index: any, page: IndexConfig.Page, key: string): boolean
	return IndexRewards.Count(index, page, key) > 0
end

function IndexRewards.IsClaimed(index: any, page: IndexConfig.Page, key: string): boolean
	return lookup(index, { "Claimed", page.Kind, key }) == true
end

function IndexRewards.IsZoneClaimed(index: any, page: IndexConfig.Page, zone: IndexConfig.Zone): boolean
	return lookup(index, { "Claimed", "Zones", IndexRewards.ZoneId(page, zone) }) == true
end

function IndexRewards.FoundCount(
	index: any,
	page: IndexConfig.Page,
	zone: IndexConfig.Zone?
): (number, number)
	local found, total = 0, 0
	for _, entryZone in page.Zones do
		if zone and entryZone ~= zone then
			continue
		end
		for _, key in entryZone.Entries do
			total += 1
			if IndexRewards.IsFound(index, page, key) then
				found += 1
			end
		end
	end
	return found, total
end

function IndexRewards.IsZoneComplete(index: any, page: IndexConfig.Page, zone: IndexConfig.Zone): boolean
	local found, total = IndexRewards.FoundCount(index, page, zone)
	return total > 0 and found == total
end

function IndexRewards.CanClaim(index: any, page: IndexConfig.Page, key: string): boolean
	return IndexRewards.ZoneOf(page, key) ~= nil
		and IndexRewards.Reward(page, key) ~= nil
		and IndexRewards.IsFound(index, page, key)
		and not IndexRewards.IsClaimed(index, page, key)
end

function IndexRewards.CanClaimZone(index: any, page: IndexConfig.Page, zone: IndexConfig.Zone): boolean
	return IndexRewards.IsZoneComplete(index, page, zone)
		and not IndexRewards.IsZoneClaimed(index, page, zone)
end

function IndexRewards.Claimable(index: any, onlyPage: IndexConfig.Page?): { Claim }
	local claims: { Claim } = {}
	for _, page in IndexConfig.Pages do
		if onlyPage and page ~= onlyPage then
			continue
		end
		for _, zone in page.Zones do
			for _, key in zone.Entries do
				if IndexRewards.CanClaim(index, page, key) then
					table.insert(claims, { Page = page, Zone = zone, Key = key })
				end
			end
			if IndexRewards.CanClaimZone(index, page, zone) then
				table.insert(claims, { Page = page, Zone = zone })
			end
		end
	end
	return claims
end

function IndexRewards.CashMultiplier(index: any): number
	local claimed = lookup(index, { "Claimed", "Zones" })
	local count = 0
	if type(claimed) == "table" then
		for _, page in IndexConfig.Pages do
			for _, zone in page.Zones do
				if claimed[IndexRewards.ZoneId(page, zone)] == true then
					count += 1
				end
			end
		end
	end
	return 1 + count * IndexConfig.ZoneCashBonus
end

function IndexRewards.OneIn(geodeKey: string, petKey: string): number?
	for _, entry in HatchOdds.Chances(geodeKey, 1) do
		if entry.PetKey == petKey and entry.Chance > 0 then
			return math.max(1, math.floor(1 / entry.Chance + 0.5))
		end
	end
	return nil
end

return IndexRewards
