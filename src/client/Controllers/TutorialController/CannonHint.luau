--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local SharedHint = require(ReplicatedStorage.CannonHint)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Spotlight = require(script.Parent.Spotlight)
local Targets = require(script.Parent.Targets)

export type Helpers = {
	ClickVerb: () -> string,
	IsOpen: (screen: string) -> boolean,
	IsNear: (target: Targets.Target?) -> boolean,
	IsTraining: () -> boolean,
	PromptKey: (adornee: Instance?, action: string, isHold: boolean) -> string,
}

export type View = {
	Title: string?,
	Detail: string?,
	Target: Targets.Target?,
	Button: GuiObject?,
	Teleport: string?,
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
			Detail = `Save up! ${current}/${NumberFormat.Compact(cannon.Price)}`,
			IsDoing = true,
		}
	end
	if stage == SharedHint.Fire then
		local fireScreen = CannonConfig.FireButton.ScreenName
		if helpers.IsOpen(fireScreen) then
			return {
				Title = "Fire the cannon!",
				Detail = `{helpers.ClickVerb()} {CannonConfig.FireButton.Text}!`,
				Button = Spotlight.Button(fireScreen, { "Button" }),
				IsDoing = true,
			}
		end
		local entry = Targets.CannonEntry(settings.FireTargetLabel)
		return {
			Title = "Fire the cannon!",
			Detail = "Walk into the Forest",
			Target = entry,
			Teleport = TutorialConfig.ZoneTeleport,
			IsDoing = false,
		}
	end
	local title = `Buy the {cannon.DisplayName}!`
	if helpers.IsOpen(settings.ScreenName) then
		return {
			Title = title,
			Detail = `{helpers.ClickVerb()} Buy!`,
			Button = Spotlight.Button(settings.ScreenName, { `Cannon{cannon.Key}`, "BuyButton" }),
			IsDoing = true,
		}
	end
	local target = Targets.ShopPad(settings.ScreenName, settings.TargetLabel)
	return {
		Title = title,
		Detail = if helpers.IsNear(target) then "Step on orange pad" else nil,
		Target = target,
		Teleport = settings.TeleportId,
		IsDoing = false,
	}
end

return CannonHint
