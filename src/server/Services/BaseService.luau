--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PLOT_TAG = "BasePlot"
local OWNER_ATTRIBUTE = "OwnerUserId"
local CRACK_SPOT_NAME = "GeodeSpot"

local BaseService = {
	Name = "BaseService",
	PlotClaimed = Signal.new() :: Signal.Signal<(Player, Model)>,
	PlotReleased = Signal.new() :: Signal.Signal<(Player, Model)>,
}

local trove = Trove.new()
local services: { [string]: any } = {}
local plots: { Model } = {}
local owners: { [Model]: Player } = {}
local claims: { [Player]: Model } = {}

local function isPlot(instance: Instance): boolean
	return instance:IsA("Model") and instance:IsDescendantOf(workspace)
end

local function release(player: Player)
	local plot = claims[player]
	if not plot then
		return
	end
	claims[player] = nil
	owners[plot] = nil
	plot:SetAttribute(OWNER_ATTRIBUTE, nil)
	print(`[BaseService] {player.Name} released {plot:GetFullName()}`)
	BaseService.PlotReleased:Fire(player, plot)
end

local function claim(player: Player)
	if claims[player] or player.Parent ~= Players then
		return
	end
	for _, plot in plots do
		if not owners[plot] then
			owners[plot] = player
			claims[player] = plot
			plot:SetAttribute(OWNER_ATTRIBUTE, player.UserId)
			print(`[BaseService] {player.Name} claimed {plot:GetFullName()}`)
			BaseService.PlotClaimed:Fire(player, plot)
			return
		end
	end
	warn(`[BaseService] No free BasePlot for {player.Name}`)
end

local function addPlot(instance: Instance)
	if not isPlot(instance) or table.find(plots, instance :: Model) then
		return
	end
	local plot = instance :: Model
	plot:SetAttribute(OWNER_ATTRIBUTE, nil)
	table.insert(plots, plot)
	table.sort(plots, function(a: Model, b: Model)
		return a:GetFullName() < b:GetFullName()
	end)
	for _, player in Players:GetPlayers() do
		if not claims[player] and services.DataService:GetData(player) then
			claim(player)
		end
	end
end

local function removePlot(instance: Instance)
	local index = table.find(plots, instance :: Model)
	if not index then
		return
	end
	table.remove(plots, index)
	local owner = owners[instance :: Model]
	if owner then
		release(owner)
		claim(owner)
	end
end

function BaseService.GetPlot(_self: any, player: Player): Model?
	return claims[player]
end

function BaseService.GetOwner(_self: any, plot: Model): Player?
	return owners[plot]
end

function BaseService.GetCrackSpot(_self: any, player: Player): Attachment?
	local plot = claims[player]
	if not plot then
		return nil
	end
	local spot = plot:FindFirstChild(CRACK_SPOT_NAME, true)
	return if spot and spot:IsA("Attachment") then spot else nil
end

function BaseService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function BaseService.Start(_self: any)
	for _, tagged in CollectionService:GetTagged(PLOT_TAG) do
		addPlot(tagged)
	end
	trove:Add(CollectionService:GetInstanceAddedSignal(PLOT_TAG):Connect(addPlot))
	trove:Add(CollectionService:GetInstanceRemovedSignal(PLOT_TAG):Connect(removePlot))
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		claim(player)
	end)
	services.DataService.PlayerReleasing:Connect(function(player: Player)
		release(player)
	end)
end

function BaseService.Destroy(_self: any)
	trove:Clean()
	table.clear(plots)
	table.clear(owners)
	table.clear(claims)
end

return BaseService
