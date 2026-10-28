--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local CannonHint = require(script.Parent.CannonHint)
local Spotlight = require(script.Parent.Spotlight)

local RebirthHint = {}

local settings = TutorialConfig.RebirthHint

function RebirthHint.View(_data: any, helpers: CannonHint.Helpers): CannonHint.View
	local isOpen = helpers.IsOpen(settings.ScreenName)
	return {
		Title = `Rebirth for x{RebirthStats.Get(1).CashMultiplier} cash!`,
		Detail = `{helpers.ClickVerb()} Rebirth!`,
		Button = if isOpen
			then Spotlight.Button(settings.ScreenName, { settings.PanelButton })
			else Spotlight.Button(settings.MenuScreen, { settings.MenuButton }),
		IsDoing = true,
	}
end

return RebirthHint
