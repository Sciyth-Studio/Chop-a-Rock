--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
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
	if not SharedHint.Cannon() then
		return { IsDoing = true }
	end
	local fireScreen = CannonConfig.FireButton.ScreenName
	if helpers.IsOpen(fireScreen) then
		return {
			Title = "Fire the cannon!",
			Detail = `{helpers.ClickVerb()} {CannonConfig.FireButton.Text}!`,
			Button = Spotlight.Button(fireScreen, { "Button" }),
			IsDoing = true,
		}
	end
	return {
		Title = "Fire the cannon!",
		Detail = "Walk into the Forest",
		Target = Targets.CannonEntry(settings.FireTargetLabel),
		Teleport = TutorialConfig.ZoneTeleport,
		IsDoing = false,
	}
end

return CannonHint
