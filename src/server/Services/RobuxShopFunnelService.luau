--!strict

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Analytics = require(ServerScriptService.Utils.Analytics)

type FunnelSession = {
	Id: string,
	Logged: { [number]: boolean },
	LastPrompt: string?,
}

local RobuxShopFunnelService = { Name = "RobuxShopFunnelService" }
local trove = Trove.new()
local funnel = AnalyticsConfig.RobuxShopFunnel
local steps = funnel.Steps
local sessions: { [Player]: FunnelSession } = {}

local function promptKey(kind: string, id: number): string
	return `{kind}{AnalyticsConfig.SkuSeparator}{id}`
end

local function logStep(player: Player, session: FunnelSession, step: number)
	if session.Logged[step] then
		return
	end
	session.Logged[step] = true
	Analytics.LogFunnelStep(player, funnel, session.Id, step)
end

local function onOpened(player: Player)
	local session: FunnelSession = { Id = HttpService:GenerateGUID(false), Logged = {}, LastPrompt = nil }
	sessions[player] = session
	logStep(player, session, steps.Opened)
end

local function onPrompted(player: Player, kind: any, id: any)
	local session = sessions[player]
	if
		not session
		or type(kind) ~= "string"
		or not table.find(AnalyticsConfig.PromptKinds, kind)
		or type(id) ~= "number"
		or id <= 0
		or id % 1 ~= 0
	then
		return
	end
	session.LastPrompt = promptKey(kind, id)
	logStep(player, session, steps.Prompted)
end

local function onFinished(player: Player?, kind: string, id: number, isPurchased: boolean)
	local session = if player then sessions[player] else nil
	if not player or not session or not isPurchased or session.LastPrompt ~= promptKey(kind, id) then
		return
	end
	logStep(player, session, steps.Purchased)
end

function RobuxShopFunnelService.Init(_self: any, _registry: { [string]: any }) end

function RobuxShopFunnelService.Start(_self: any)
	trove:Add(Packets.RobuxShopOpened.OnServerEvent:Connect(onOpened))
	trove:Add(Packets.RobuxShopPrompted.OnServerEvent:Connect(onPrompted))
	trove:Connect(
		MarketplaceService.PromptProductPurchaseFinished,
		function(userId: number, productId: number, isPurchased: boolean)
			onFinished(Players:GetPlayerByUserId(userId), "Product", productId, isPurchased)
		end
	)
	trove:Connect(
		MarketplaceService.PromptGamePassPurchaseFinished,
		function(player: Player, gamepassId: number, wasPurchased: boolean)
			onFinished(player, "Pass", gamepassId, wasPurchased)
		end
	)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		sessions[player] = nil
	end)
end

function RobuxShopFunnelService.Destroy(_self: any)
	trove:Destroy()
	table.clear(sessions)
end

return RobuxShopFunnelService
