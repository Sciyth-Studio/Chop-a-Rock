--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local SharedHint = require(ReplicatedStorage.AuraHint)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local CannonHint = require(script.Parent.CannonHint)
local Spotlight = require(script.Parent.Spotlight)
local Targets = require(script.Parent.Targets)

local AuraHint = {}

local settings = TutorialConfig.AuraHint

function AuraHint.View(data: any, helpers: CannonHint.Helpers): CannonHint.View
	local stage = SharedHint.StageOf(data)
	local aura = SharedHint.Aura()
	if not aura then
		return { IsDoing = true }
	end
	if stage == SharedHint.Save then
		local cash = if type(data.Cash) == "number" then data.Cash else 0
		local current = NumberFormat.Compact(math.min(cash, aura.Price))
		return {
			Title = `{aura.DisplayName} unlocked!`,
			Detail = `Save up! ${current}/${NumberFormat.Compact(aura.Price)}`,
			IsDoing = true,
		}
	end
	if stage == SharedHint.Train then
		local reps = math.min(SharedHint.RepsOf(data), settings.TrainReps)
		local title = `Train with your aura! {reps}/{settings.TrainReps}`
		if helpers.IsTraining() then
			return {
				Title = title,
				Detail = `x{aura.TrainingGainMultiplier} strength!`,
				IsDoing = true,
			}
		end
		local target = Targets.TrainingStand()
		local adornee = if target then target.Adornee else nil
		return {
			Title = title,
			Detail = if helpers.IsNear(target)
				then `{helpers.PromptKey(adornee, "Train", false)} to train`
				else nil,
			Target = target,
			Teleport = settings.TrainTeleportId,
			IsDoing = false,
		}
	end
	local title = `Buy the {aura.DisplayName}!`
	if helpers.IsOpen(settings.ScreenName) then
		return {
			Title = title,
			Detail = `{helpers.ClickVerb()} Buy!`,
			Button = Spotlight.Button(settings.ScreenName, { `Tier{settings.Tier}`, "BuyButton" }),
			IsDoing = true,
		}
	end
	local target = Targets.ShopPad(settings.ScreenName, settings.TargetLabel)
	return {
		Title = title,
		Detail = if helpers.IsNear(target) then "Step on red pad" else nil,
		Target = target,
		Teleport = settings.TeleportId,
		IsDoing = false,
	}
end

return AuraHint
