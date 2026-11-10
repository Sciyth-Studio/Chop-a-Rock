--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local EggRetry = {}

local function findLabel(gui: Instance, name: string): TextLabel?
	local found = gui:FindFirstChild(name, true)
	if found and found:IsA("TextLabel") then
		return found
	end
	warn(`[EggRetry] Missing TextLabel "{name}" in {gui:GetFullName()}`)
	return nil
end

local function findButton(gui: Instance, name: string): GuiButton?
	local found = gui:FindFirstChild(name, true)
	if found and found:IsA("GuiButton") then
		return found
	end
	warn(`[EggRetry] Missing GuiButton "{name}" in {gui:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent then label.Parent:FindFirstChild(label.Name .. "Shadow") else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

function EggRetry.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local openTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local timerLabel = findLabel(gui, "Timer")
	local retryLabel = findLabel(gui, "RetryLabel")
	local retryButton = findButton(gui, "RetryButton")
	local giveUpButton = findButton(gui, "GiveUpButton")

	local currentId: number? = nil
	local choice = ""
	local endsAt = 0
	local isPaused = false

	local function choose(value: string)
		local id = currentId
		if id then
			Packets.EggRetryChoose:Fire(id, value)
		end
	end

	if retryButton then
		trove:Connect(retryButton.Activated, function()
			if choice == "Buying" then
				local productId = MonetizationConfig.RetryFight.ProductId
				if productId then
					isPaused = true
					choose("Buying")
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
				end
			elseif choice ~= "" then
				choose(choice)
			end
		end)
	end
	if giveUpButton then
		trove:Connect(giveUpButton.Activated, function()
			choose("Decline")
			context.Close("EggRetry")
		end)
	end

	trove:Add(
		Packets.EggRetryOffer.OnClientEvent:Connect(
			function(id: number, credits: number, hasFree: boolean, seconds: number)
				currentId = id
				isPaused = false
				endsAt = os.clock() + seconds
				local productId = MonetizationConfig.RetryFight.ProductId
				if hasFree then
					choice = "Free"
					setText(retryLabel, "Free Retry")
				elseif credits > 0 then
					choice = "Credit"
					setText(retryLabel, `Retry ({credits})`)
				elseif productId then
					choice = "Buying"
					setText(retryLabel, `Retry  R$ {MonetizationConfig.RetryFight.RobuxPrice}`)
				else
					choice = ""
				end
				if retryButton then
					retryButton.Visible = choice ~= ""
				end
				context.Open("EggRetry")
			end
		)
	)
	trove:Add(Packets.EggRetryClosed.OnClientEvent:Connect(function(id: number)
		if currentId == id then
			currentId = nil
			context.Close("EggRetry")
		end
	end))

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			openTrove:Connect(RunService.RenderStepped, function()
				if not isPaused then
					setText(timerLabel, `{math.max(math.ceil(endsAt - os.clock()), 0)}`)
				end
			end)
		end,
		Close = function(_self: Types.Screen)
			openTrove:Clean()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return EggRetry
