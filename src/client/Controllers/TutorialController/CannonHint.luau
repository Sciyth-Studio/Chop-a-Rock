--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local SharedHint = require(ReplicatedStorage.CannonHint)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Spotlight = require(script.Parent.Spotlight)
local Targets = require(script.Parent.Targets)

export type Helpers = {
	PromptKey: (adornee: Instance?, action: string, isHold: boolean) -> string,
	ClickVerb: () -> string,
	IsOpen: (screen: string) -> boolean,
	IsNear: (target: Targets.Target?) -> boolean,
}

export type View = {
	Title: string?,
	Detail: string?,
	Target: Targets.Target?,
	Button: GuiObject?,
	IsDoing: boolean,
}

local CannonHint = {}

local settings = TutorialConfig.CannonHint

function CannonHint.View(data: any, helpers: Helpers): View
	local stage = SharedHint.StageOf(data)
	local cannon = SharedHint.Cannon()
	if not cannon then
		return { IsDoing = true }
	end
	if stage == SharedHint.Save then
		local cash = if type(data.Cash) == "number" then data.Cash else 0
		local current = NumberFormat.Compact(math.min(cash, cannon.Price))
		return {
			Title = `{cannon.DisplayName} unlocked!`,
			Detail = `Save up for it: ${current}/${NumberFormat.Compact(cannon.Price)}`,
			IsDoing = true,
		}
	end
	local isShopOpen = helpers.IsOpen(settings.ScreenName)
	if stage == SharedHint.Buy then
		local title = `Buy the {cannon.DisplayName}!`
		if isShopOpen then
			return {
				Title = title,
				Detail = `{helpers.ClickVerb()} the price to buy it!`,
				Button = Spotlight.Button(settings.ScreenName, { `Cannon{cannon.Key}`, "BuyButton" }),
				IsDoing = true,
			}
		end
		local target = Targets.ShopPad(settings.ScreenName, settings.TargetLabel)
		return {
			Title = title,
			Detail = if helpers.IsNear(target) then "Walk onto the orange pad" else "Follow the arrows",
			Target = target,
			IsDoing = false,
		}
	end
	if isShopOpen then
		return { Title = "Fire the cannon!", Detail = "Close the shop, then fire!", IsDoing = true }
	end
	local target = Targets.LobbyCannon()
	local isHold = CannonConfig.PromptHoldSeconds > 0
	return {
		Title = "Fire the cannon!",
		Detail = if helpers.IsNear(target)
			then `{helpers.PromptKey(if target then target.Adornee else nil, "Fire", isHold)} to fire!`
			else "Follow the arrows",
		Target = target,
		IsDoing = false,
	}
end

return CannonHint
