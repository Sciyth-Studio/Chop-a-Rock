--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local SharedHint = require(ReplicatedStorage.CannonHint)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Spotlight = require(script.Parent.Spotlight)
local Targets = require(script.Parent.Targets)

export type Helpers = {
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
	local isBuy = stage == SharedHint.Buy
	local title = if isBuy then `Buy the {cannon.DisplayName}!` else "Fire the cannon!"
	if helpers.IsOpen(settings.ScreenName) then
		return {
			Title = title,
			Detail = if isBuy
				then `{helpers.ClickVerb()} the price to buy it!`
				else `{helpers.ClickVerb()} Fire to launch!`,
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

return CannonHint
