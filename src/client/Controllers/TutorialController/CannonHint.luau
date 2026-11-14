--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedHint = require(ReplicatedStorage.CannonHint)
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
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

function CannonHint.View(_data: any, helpers: Helpers): View
	if not SharedHint.Cannon() then
		return { IsDoing = true }
	end
	local launch = TeleportConfig.LaunchId
	local label = launch
	for _, destination in TeleportConfig.Destinations do
		if destination.Id == launch then
			label = destination.Label
		end
	end
	return {
		Title = "Fire the cannon!",
		Detail = `{helpers.ClickVerb()} {label}!`,
		Button = Spotlight.Button(
			TeleportConfig.ScreenName,
			{ launch .. TeleportConfig.ButtonSuffix, TeleportConfig.ClickButtonName }
		),
		IsDoing = true,
	}
end

return CannonHint
