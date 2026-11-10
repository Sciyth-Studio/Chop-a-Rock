--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local BaseUpgradeConfig = require(ReplicatedStorage.Config.BaseUpgradeConfig)
local BaseLevels = require(ReplicatedStorage.Utils.BaseLevels)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local BaseUpgradeService = { Name = "BaseUpgradeService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local storage: Folder? = nil
local levelSets: { [Model]: Instance } = {}

local function getStorage(): Folder
	if storage then
		return storage
	end
	local folder = Instance.new("Folder")
	folder.Name = BaseUpgradeConfig.StorageName
	folder.Parent = ServerStorage
	storage = folder
	return folder
end

local function placeOwnerSpot(plot: Model, pen: Instance)
	local spot = plot:FindFirstChild(BaseUpgradeConfig.OwnerSpotName, true)
	local floor = pen:FindFirstChild(BaseUpgradeConfig.FloorPartName, true)
	if not spot or not spot:IsA("BasePart") or not floor or not floor:IsA("BasePart") then
		return
	end
	local pivot = plot:GetPivot()
	local offset = pivot:PointToObjectSpace(floor.Position)
	spot.CFrame = pivot * CFrame.new(0, BaseUpgradeConfig.OwnerSpotGapStuds, offset.Z)
end

local function showLevel(plot: Model, level: number)
	local set = levelSets[plot]
	local template = if set
		then set:FindFirstChild(string.format(BaseUpgradeConfig.PenLevelFormat, BaseLevels.Clamp(level)))
		else nil
	if not template then
		return
	end
	local current = plot:FindFirstChild(BaseUpgradeConfig.ActivePenName)
	if current and current:GetAttribute("BaseLevel") == BaseLevels.Clamp(level) then
		return
	end
	if current then
		current:Destroy()
	end
	local pen = template:Clone()
	pen.Name = BaseUpgradeConfig.ActivePenName
	pen:SetAttribute("BaseLevel", BaseLevels.Clamp(level))
	pen.Parent = plot
	placeOwnerSpot(plot, pen)
end

local function addPlot(instance: Instance)
	if not instance:IsA("Model") or not instance:IsDescendantOf(workspace) or levelSets[instance] then
		return
	end
	local levels = instance:FindFirstChild(BaseUpgradeConfig.PenLevelsName)
	if not levels then
		warn(`[BaseUpgradeService] {instance:GetFullName()} has no {BaseUpgradeConfig.PenLevelsName}`)
		return
	end
	local holder = Instance.new("Folder")
	holder.Name = instance.Name
	holder.Parent = getStorage()
	levels.Parent = holder
	levelSets[instance] = levels
	showLevel(instance, 1)
end

local function syncSlots(player: Player, level: number, exact: boolean)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local slots = BaseLevels.Get(level).PenSlots
	if exact or data.PedestalSlots < slots then
		services.PedestalService:SetSlots(player, slots)
	end
end

local function apply(player: Player)
	local data = services.DataService:GetData(player)
	local plot = services.BaseService:GetPlot(player)
	if not data or not plot then
		return
	end
	showLevel(plot, data.BaseLevel)
	services.VipBaseService:Refresh(player)
	services.PedestalService:ResetPen(player)
end

local function upgrade(player: Player): string
	local data = services.DataService:GetData(player)
	if not data then
		return "Failed"
	end
	local level = BaseLevels.Clamp(data.BaseLevel)
	local nextLevel = BaseLevels.Next(level)
	if not nextLevel then
		return "Max"
	end
	if data.Cash < nextLevel.Price then
		return "Cash"
	end
	if
		not services.DataService:AdjustCash(
			player,
			-nextLevel.Price,
			AnalyticsConfig.Sinks.BaseUpgrade,
			tostring(level + 1)
		)
	then
		return "Cash"
	end
	if not services.DataService:Set(player, { "BaseLevel" }, level + 1) then
		return "Failed"
	end
	syncSlots(player, level + 1, false)
	services.DataService:RequestSave(player)
	apply(player)
	return "Upgraded"
end

function BaseUpgradeService.SetLevel(_self: any, player: Player, level: number): boolean
	if not services.DataService:GetData(player) then
		return false
	end
	local clamped = BaseLevels.Clamp(level)
	services.DataService:Set(player, { "BaseLevel" }, clamped)
	syncSlots(player, clamped, true)
	apply(player)
	return true
end

function BaseUpgradeService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function BaseUpgradeService.Start(_self: any)
	for _, tagged in CollectionService:GetTagged(BaseUpgradeConfig.Sign.PlotTag) do
		addPlot(tagged)
	end
	trove:Add(CollectionService:GetInstanceAddedSignal(BaseUpgradeConfig.Sign.PlotTag):Connect(addPlot))
	trove:Add(services.BaseService.PlotClaimed:Connect(function(player: Player)
		local data = services.DataService:GetData(player)
		if data then
			syncSlots(player, data.BaseLevel, false)
		end
		apply(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(_player: Player, plot: Model)
		showLevel(plot, 1)
	end))
	for plot in levelSets do
		local owner = services.BaseService:GetOwner(plot)
		if owner then
			apply(owner)
		end
	end
	Packets.UpgradeBase.OnServerInvoke = function(player: Player)
		return upgrade(player)
	end
end

function BaseUpgradeService.Destroy(_self: any)
	Packets.UpgradeBase.OnServerInvoke = nil
	trove:Clean()
	table.clear(levelSets)
	if storage then
		storage:Destroy()
		storage = nil
	end
end

return BaseUpgradeService
