--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ShopCards = require(script.Parent.Parent.ShopCards)
local Types = require(script.Parent.Parent.Types)

local SHOW_SECONDS = 4

local PurchaseBanner = {}

local function message(kind: string, buyer: string, recipient: string, item: string): string?
	if kind == "Gift" then
		return `{buyer} gifted {recipient} {item}!`
	elseif kind == "ServerBoost" then
		for _, boost in MonetizationConfig.ServerBoosts do
			if boost.Key == item then
				return `{buyer} boosted the server: {boost.DisplayName}!`
			end
		end
	end
	return nil
end

function PurchaseBanner.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local containerInstance = gui:FindFirstChild("Container")
	local container: GuiObject? = if containerInstance and containerInstance:IsA("GuiObject")
		then containerInstance
		else nil
	if not container then
		warn(`[PurchaseBanner] Missing "Container" in {gui:GetFullName()}`)
	end
	local queue: { string } = {}
	local isShowing = false

	local function showNext()
		local text = table.remove(queue, 1)
		if not container or not text then
			isShowing = false
			if container then
				container.Visible = false
			end
			return
		end
		isShowing = true
		ShopCards.SetText(container, "Label", text)
		container.Visible = true
		LocalSound.Play(MonetizationConfig.BoughtSound)
		task.delay(SHOW_SECONDS, showNext)
	end

	trove:Add(
		Packets.PurchaseAnnounced.OnClientEvent:Connect(
			function(kind: string, buyer: string, recipient: string, item: string)
				local text = message(kind, buyer, recipient, item)
				if not text then
					return
				end
				table.insert(queue, text)
				if not isShowing then
					showNext()
				end
			end
		)
	)

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return PurchaseBanner
