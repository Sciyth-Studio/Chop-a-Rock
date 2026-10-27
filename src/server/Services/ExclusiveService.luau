--!strict

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ExclusiveService = { Name = "ExclusiveService" }

local settings = MonetizationConfig.Exclusives

local services: { [string]: any } = {}
local trove = Trove.new()
local sold: { [string]: number } = {}
local unsaved: { [string]: number } = {}

local itemsByKey: { [string]: MonetizationConfig.Exclusive } = {}
for _, item in settings.Items do
	itemsByKey[item.Key] = item
end

local function store(): DataStore?
	local name = if RunService:IsStudio() then `{settings.StoreName}_Studio` else settings.StoreName
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	return if ok then result else nil
end

local function showStand(stand: Instance)
	if not stand:IsA("Model") then
		return
	end
	local key = stand:GetAttribute(settings.KeyAttribute)
	local item = if type(key) == "string" then itemsByKey[key] else nil
	if not item then
		warn(`[ExclusiveService] {stand:GetFullName()} has no valid "{settings.KeyAttribute}" attribute`)
		return
	end
	stand:SetAttribute(settings.PriceAttribute, item.RobuxPrice)
	stand:SetAttribute(settings.StockAttribute, item.Stock)
	stand:SetAttribute(settings.SoldAttribute, sold[item.Key] or 0)
	services.PedestalService:ShowRok(stand, item.RokKey, settings.RokScale)
	local prompt = stand:FindFirstChild(settings.PromptName, true)
	if not prompt then
		local part = stand.PrimaryPart or stand:FindFirstChildWhichIsA("BasePart", true)
		if part then
			local created = Instance.new("ProximityPrompt")
			created.Name = settings.PromptName
			created.ActionText = "Buy"
			created.ObjectText = PetConfig.Pets[item.RokKey].DisplayName
			created.MaxActivationDistance = settings.PromptRangeStuds
			created.HoldDuration = settings.PromptHoldSeconds
			created.RequiresLineOfSight = false
			created.Parent = part
		end
	end
end

local function publishSold()
	for _, stand in CollectionService:GetTagged(settings.StandTag) do
		local key = stand:GetAttribute(settings.KeyAttribute)
		if type(key) == "string" and itemsByKey[key] then
			stand:SetAttribute(settings.SoldAttribute, sold[key] or 0)
		end
	end
end

local function sync()
	local dataStore = store()
	if not dataStore then
		return
	end
	for _, item in settings.Items do
		local add = unsaved[item.Key] or 0
		unsaved[item.Key] = nil
		local ok, result = pcall(function(): any
			if add > 0 then
				return dataStore:IncrementAsync(item.StockKey, add)
			end
			local value = dataStore:GetAsync(item.StockKey)
			return value
		end)
		if ok and type(result) == "number" then
			sold[item.Key] = result
		elseif not ok then
			unsaved[item.Key] = (unsaved[item.Key] or 0) + add
		end
	end
	publishSold()
end

function ExclusiveService.Grant(_self: any, player: Player, key: string): boolean
	local item = itemsByKey[key]
	local data = services.DataService:GetData(player)
	if not item or not data then
		return false
	end
	if not services.PetService:GrantOrQueue(player, item.RokKey) then
		return false
	end
	services.DataService:Set(player, { "Exclusives", key }, true)
	unsaved[key] = (unsaved[key] or 0) + 1
	sold[key] = (sold[key] or 0) + 1
	publishSold()
	return true
end

function ExclusiveService.ResetOwned(_self: any, player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	if not data or not itemsByKey[key] then
		return false
	end
	services.DataService:Set(player, { "Exclusives", key }, nil)
	return true
end

function ExclusiveService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ExclusiveService.Start(_self: any)
	for _, stand in CollectionService:GetTagged(settings.StandTag) do
		showStand(stand)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(settings.StandTag), showStand)
	trove:Add(task.spawn(function()
		while true do
			sync()
			task.wait(settings.RefreshSeconds)
		end
	end))
end

function ExclusiveService.Destroy(_self: any)
	trove:Destroy()
end

return ExclusiveService
