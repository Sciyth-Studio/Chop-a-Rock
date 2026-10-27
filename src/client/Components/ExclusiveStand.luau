--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)

local settings = MonetizationConfig.Exclusives

type ExclusiveStand = {
	Instance: Instance,
	Trove: any,
}

local function findItem(key: any): MonetizationConfig.Exclusive?
	for _, item in settings.Items do
		if item.Key == key then
			return item
		end
	end
	return nil
end

local function setText(root: Instance, name: string, text: string)
	local label = root:FindFirstChild(name, true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

return function(controllers: { [string]: any })
	local ExclusiveStand = Component.new({ Tag = settings.StandTag }) :: any

	function ExclusiveStand.Start(self: ExclusiveStand)
		self.Trove = Trove.new()
		local stand = self.Instance
		local item = findItem(stand:GetAttribute(settings.KeyAttribute))
		if not item then
			return
		end
		local dataController = controllers.DataController

		local function isOwned(): boolean
			return dataController:Get({ "Exclusives", item.Key }) == true
		end

		local function isSoldOut(): boolean
			local sold = stand:GetAttribute(settings.SoldAttribute)
			return type(sold) == "number" and sold >= item.Stock
		end

		local function refresh()
			local sold = stand:GetAttribute(settings.SoldAttribute)
			local left = math.max(0, item.Stock - (if type(sold) == "number" then sold else 0))
			setText(stand, "Pitch", item.Pitch)
			setText(
				stand,
				"Stock",
				if left > 0
					then `Stock: {NumberFormat.Commas(left)} / {NumberFormat.Commas(item.Stock)}`
					else "Sold out"
			)
			setText(
				stand,
				"Price",
				if isOwned()
					then "Owned!"
					elseif left > 0 then `R$ {NumberFormat.Commas(item.RobuxPrice)}`
					else ""
			)
			local prompt = stand:FindFirstChild(settings.PromptName, true)
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = not isOwned() and left > 0
				prompt.ActionText = `Buy R$ {NumberFormat.Commas(item.RobuxPrice)}`
			end
		end

		local function onTriggered(prompt: ProximityPrompt)
			if prompt.Name ~= settings.PromptName or isOwned() or isSoldOut() then
				return
			end
			local productId = item.ProductId
			if productId then
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
			elseif controllers.NotificationController then
				controllers.NotificationController:Notify("Info", "Coming soon!")
			end
		end

		self.Trove:Connect(stand:GetAttributeChangedSignal(settings.SoldAttribute), refresh)
		self.Trove:Add(dataController:Observe({ "Exclusives" }, refresh))
		self.Trove:Connect(stand.DescendantAdded, function(descendant: Instance)
			if descendant:IsA("ProximityPrompt") then
				refresh()
			end
		end)
		self.Trove:Connect(
			game:GetService("ProximityPromptService").PromptTriggered,
			function(prompt: ProximityPrompt)
				if prompt:IsDescendantOf(stand) then
					onTriggered(prompt)
				end
			end
		)
		refresh()
	end

	function ExclusiveStand.Stop(self: ExclusiveStand)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return ExclusiveStand
end
