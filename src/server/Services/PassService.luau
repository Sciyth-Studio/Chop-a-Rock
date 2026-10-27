--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PassService = {
	Name = "PassService",
	PassChanged = Signal.new() :: Signal.Signal<(Player, string)>,
}

local services: { [string]: any } = {}
local trove = Trove.new()
local robloxOwned: { [Player]: { [string]: boolean } } = {}
local fakeOwned: { [Player]: { [string]: boolean } } = {}
local shown: { [Player]: { [string]: boolean } } = {}
local restricted: { [Player]: boolean } = {}

local passesByKey: { [string]: MonetizationConfig.Pass } = {}
local passesById: { [number]: MonetizationConfig.Pass } = {}
for _, pass in MonetizationConfig.Passes do
	passesByKey[pass.Key] = pass
	if pass.GamepassId then
		passesById[pass.GamepassId] = pass
	end
end

local function ownsDirectly(player: Player, key: string): boolean
	local fake = fakeOwned[player]
	if fake and fake[key] ~= nil then
		return fake[key]
	end
	local owned = robloxOwned[player]
	if owned and owned[key] then
		return true
	end
	local data = services.DataService:GetData(player)
	return data ~= nil and data.Passes[key] == true
end

local function owns(player: Player, key: string): boolean
	if ownsDirectly(player, key) then
		return true
	end
	for _, pass in MonetizationConfig.Passes do
		if pass.Includes and table.find(pass.Includes, key) and ownsDirectly(player, pass.Key) then
			return true
		end
	end
	return false
end

local function refresh(player: Player)
	if not player.Parent then
		return
	end
	local current = shown[player]
	if not current then
		current = {}
		shown[player] = current
	end
	for _, pass in MonetizationConfig.Passes do
		local isOwned = owns(player, pass.Key)
		if current[pass.Key] ~= isOwned then
			current[pass.Key] = isOwned
			player:SetAttribute(MonetizationConfig.PassAttributePrefix .. pass.Key, isOwned)
			PassService.PassChanged:Fire(player, pass.Key)
		end
	end
end

local function remember(player: Player, key: string)
	local data = services.DataService:GetData(player)
	if data and data.Passes[key] ~= true then
		services.DataService:Set(player, { "Passes", key }, true)
	end
end

local function check(player: Player, pass: MonetizationConfig.Pass, retries: number)
	local gamepassId = pass.GamepassId
	if not gamepassId then
		return
	end
	local ok, result =
		pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, gamepassId)
	if not player.Parent then
		return
	end
	if not ok then
		if retries > 0 then
			task.delay(MonetizationConfig.OwnershipRetrySeconds, function()
				check(player, pass, retries - 1)
			end)
		else
			warn(`[PassService] Ownership check for {pass.Key} failed for {player.Name}: {result}`)
		end
		return
	end
	if result == true then
		local owned = robloxOwned[player]
		if not owned then
			owned = {}
			robloxOwned[player] = owned
		end
		owned[pass.Key] = true
		remember(player, pass.Key)
	end
	refresh(player)
end

local function checkPolicy(player: Player)
	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	if not player.Parent then
		return
	end
	local isRestricted = not ok or type(info) ~= "table" or info.ArePaidRandomItemsRestricted ~= false
	restricted[player] = isRestricted
	player:SetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute, isRestricted)
end

function PassService.IsRandomItemsRestricted(_self: any, player: Player): boolean
	return restricted[player] ~= false
end

function PassService.Refresh(_self: any, player: Player)
	refresh(player)
end

function PassService.Owns(_self: any, player: Player, key: string): boolean
	return owns(player, key)
end

function PassService.GetMultiplier(_self: any, player: Player, key: string): number
	local passBonus = if owns(player, key) then MonetizationConfig.PassMultiplierBonus[key] or 0 else 0
	return 1 + passBonus + services.BoostService:GetBonus(player, key)
end

function PassService.ApplyCashMultiplier(_self: any, player: Player, amount: number): number
	return math.floor(amount * PassService:GetMultiplier(player, "Cash") + 0.5)
end

function PassService.GetBackpackSize(_self: any, player: Player): number
	local bonus = if owns(player, "Backpack") then MonetizationConfig.BackpackBonus else 0
	return PetConfig.MaxPets + bonus
end

function PassService.GetPass(_self: any, key: string): MonetizationConfig.Pass?
	return passesByKey[key]
end

function PassService.SetFake(_self: any, player: Player, key: string, isOwned: boolean): boolean
	if not RunService:IsStudio() or not passesByKey[key] then
		return false
	end
	local fake = fakeOwned[player]
	if not fake then
		fake = {}
		fakeOwned[player] = fake
	end
	fake[key] = isOwned
	refresh(player)
	return true
end

function PassService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PassService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		task.spawn(checkPolicy, player)
		refresh(player)
		for _, pass in MonetizationConfig.Passes do
			task.spawn(check, player, pass, 1)
		end
	end)
	trove:Connect(
		MarketplaceService.PromptGamePassPurchaseFinished,
		function(player: Player, gamepassId: number, wasPurchased: boolean)
			local pass = passesById[gamepassId]
			if wasPurchased and pass then
				task.spawn(check, player, pass, 1)
			end
		end
	)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		robloxOwned[player] = nil
		fakeOwned[player] = nil
		shown[player] = nil
		restricted[player] = nil
	end)
end

function PassService.Destroy(_self: any)
	trove:Destroy()
	table.clear(robloxOwned)
	table.clear(fakeOwned)
	table.clear(shown)
	table.clear(restricted)
end

return PassService
