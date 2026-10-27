--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Gifts = require(script.Gifts)
local Products = require(script.Products)

type GiftTarget = { UserId: number, Key: string }

local PurchaseService = { Name = "PurchaseService" }
local registry: { [string]: any } = {}
local trove = Trove.new()
local giftTargets: { [Player]: GiftTarget } = {}
local maxReceipts = 100

local function prune(receipts: { [string]: number })
	local ids = {}
	for purchaseId in receipts do
		table.insert(ids, purchaseId)
	end
	if #ids <= maxReceipts then
		return
	end
	table.sort(ids, function(a, b)
		return receipts[a] < receipts[b]
	end)
	for index = 1, #ids - maxReceipts do
		receipts[ids[index]] = nil
	end
end

local function announceGift(buyer: Player, recipient: Player, gift: MonetizationConfig.Gift)
	local name = Gifts.DisplayName(gift)
	Packets.PurchaseAnnounced:FireAllClients("Gift", buyer.DisplayName, recipient.DisplayName, name)
	Packets.GiftReceived:FireClient(recipient, buyer.DisplayName, name, buyer.UserId)
	registry.NotificationService:Notify(buyer, "Purchase", `You gifted {name} to {recipient.DisplayName}!`)
	registry.NotificationService:Notify(recipient, "Purchase", `{buyer.DisplayName} gifted you {name}!`)
end

local function waitForSave(player: Player, key: string, purchaseId: string): boolean
	return registry.DataService:WaitForSave(player, function(snapshot: any)
		return type(snapshot[key]) == "table" and snapshot[key][purchaseId] ~= nil
	end)
end

local function deliverGift(buyer: Player, gift: MonetizationConfig.Gift, purchaseId: string): boolean
	local target = giftTargets[buyer]
	if not target or target.Key ~= gift.Key or target.UserId == buyer.UserId then
		return Gifts.Credit(registry, buyer, gift)
	end
	local recipient = Players:GetPlayerByUserId(target.UserId)
	local recipientData = if recipient then registry.DataService:GetData(recipient) else nil
	if recipient and recipientData then
		if recipientData.GiftsReceived[purchaseId] == nil then
			if not Gifts.CanReceive(registry, recipient, gift) then
				return Gifts.Credit(registry, buyer, gift)
			end
			if not Gifts.Apply(registry, recipient, gift) then
				return false
			end
			Gifts.Remember(recipientData, purchaseId)
			announceGift(buyer, recipient, gift)
		end
		return waitForSave(recipient, "GiftsReceived", purchaseId)
	end
	local sent = registry.DataService:SendMessage(target.UserId, {
		Type = "Gift",
		Key = gift.Key,
		PurchaseId = purchaseId,
		From = buyer.DisplayName,
		FromUserId = buyer.UserId,
	})
	if sent then
		return true
	end
	return Gifts.Credit(registry, buyer, gift)
end

local function processGift(receipt: { [string]: any }, buyer: Player, gift: MonetizationConfig.Gift)
	local purchaseId = tostring(receipt.PurchaseId)
	local dataService = registry.DataService
	local data = dataService:GetData(buyer)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.Receipts[purchaseId] == nil then
		local ok, delivered = pcall(deliverGift, buyer, gift, purchaseId)
		if not ok then
			warn(`[PurchaseService] Gift {gift.Key} failed: {delivered}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local current = dataService:GetData(buyer)
		if delivered ~= true or not current then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		current.Receipts[purchaseId] = os.time()
		prune(current.Receipts)
	end
	return if waitForSave(buyer, "Receipts", purchaseId)
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local purchaseId = tostring(receipt.PurchaseId)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local dataService = registry.DataService
	local data = player and dataService:GetData(player)
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local gift = Gifts.ByProductId(receipt.ProductId)
	if gift then
		return processGift(receipt, player, gift)
	end
	if data.Receipts[purchaseId] == nil then
		local grant = Products[receipt.ProductId]
		if not grant then
			warn(`[PurchaseService] No grant for product {receipt.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(grant, player, registry)
		if not ok then
			warn(`[PurchaseService] Grant for product {receipt.ProductId} failed: {granted}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if granted ~= true or dataService:GetData(player) ~= data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		data.Receipts[purchaseId] = os.time()
		prune(data.Receipts)
	end
	local saved = dataService:WaitForSave(player, function(snapshot: any)
		return type(snapshot.Receipts) == "table" and snapshot.Receipts[purchaseId] ~= nil
	end)
	return if saved
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

local function onMessage(player: Player, message: any, processed: () -> ())
	if type(message) ~= "table" or message.Type ~= "Gift" then
		return
	end
	local data = registry.DataService:GetData(player)
	local gift = if type(message.Key) == "string" then Gifts.ByKey(message.Key) else nil
	local purchaseId = if type(message.PurchaseId) == "string" then message.PurchaseId else nil
	if not data or not gift or not purchaseId then
		processed()
		return
	end
	if data.GiftsReceived[purchaseId] == nil then
		if Gifts.CanReceive(registry, player, gift) and not Gifts.Apply(registry, player, gift) then
			return
		end
		Gifts.Remember(data, purchaseId)
		local from = if type(message.From) == "string" then message.From else "A friend"
		local fromUserId = if type(message.FromUserId) == "number" then message.FromUserId else 0
		Packets.GiftReceived:FireClient(player, from, Gifts.DisplayName(gift), fromUserId)
		registry.NotificationService:Notify(
			player,
			"Purchase",
			`{from} gifted you {Gifts.DisplayName(gift)}!`
		)
		registry.DataService:RequestSave(player)
	end
	processed()
end

local function sendCredit(buyer: Player, recipientUserId: number, giftKey: string): boolean
	local gift = Gifts.ByKey(giftKey)
	local data = registry.DataService:GetData(buyer)
	local recipient = Players:GetPlayerByUserId(recipientUserId)
	if not gift or not data or not recipient or recipient == buyer then
		return false
	end
	local credits = data.GiftCredits[giftKey] or 0
	if credits < 1 or not Gifts.CanReceive(registry, recipient, gift) then
		return false
	end
	if not Gifts.Apply(registry, recipient, gift) then
		return false
	end
	registry.DataService:Set(buyer, { "GiftCredits", giftKey }, if credits > 1 then credits - 1 else nil)
	registry.DataService:RequestSave(buyer)
	registry.DataService:RequestSave(recipient)
	announceGift(buyer, recipient, gift)
	return true
end

function PurchaseService.SimulateGift(_self: any, buyer: Player, giftKey: string): string
	local gift = Gifts.ByKey(giftKey)
	if not gift then
		return "no such gift"
	end
	for _, other in Players:GetPlayers() do
		if other ~= buyer and registry.DataService:GetData(other) then
			if not Gifts.CanReceive(registry, other, gift) then
				Gifts.Credit(registry, buyer, gift)
				return `{other.DisplayName} can't receive it, so you got a gift credit`
			end
			if Gifts.Apply(registry, other, gift) then
				announceGift(buyer, other, gift)
				return `gifted {Gifts.DisplayName(gift)} to {other.DisplayName}`
			end
			return "gift failed"
		end
	end
	Gifts.Credit(registry, buyer, gift)
	return "nobody else here, so you got a gift credit"
end

function PurchaseService.Init(_self: any, services: { [string]: any })
	registry = services
end

function PurchaseService.Start(_self: any)
	MarketplaceService.ProcessReceipt = processReceipt
	registry.DataService.MessageReceived:Connect(onMessage)
	trove:Add(
		Packets.SetGiftTarget.OnServerEvent:Connect(function(player: Player, userId: number, giftKey: string)
			if type(userId) ~= "number" or type(giftKey) ~= "string" or not Gifts.ByKey(giftKey) then
				return
			end
			local recipient = Players:GetPlayerByUserId(userId)
			if recipient and recipient ~= player then
				giftTargets[player] = { UserId = userId, Key = giftKey }
			end
		end)
	)
	Packets.SendGiftCredit.OnServerInvoke = function(player: Player, userId: number, giftKey: string): boolean
		if type(userId) ~= "number" or type(giftKey) ~= "string" then
			return false
		end
		return sendCredit(player, userId, giftKey)
	end
	trove:Add(Packets.ThankGift.OnServerEvent:Connect(function(player: Player, userId: number)
		local giver = if type(userId) == "number" then Players:GetPlayerByUserId(userId) else nil
		if giver and giver ~= player then
			registry.NotificationService:Notify(
				giver,
				"Purchase",
				`{player.DisplayName} says thanks for the gift!`
			)
		end
	end))
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		giftTargets[player] = nil
	end)
end

function PurchaseService.Destroy(_self: any)
	MarketplaceService.ProcessReceipt = nil :: any
	Packets.SendGiftCredit.OnServerInvoke = nil
	trove:Destroy()
	table.clear(giftTargets)
end

return PurchaseService
