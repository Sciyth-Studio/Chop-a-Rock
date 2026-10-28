--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local SharedHint = require(ReplicatedStorage.RockHint)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local CannonHint = require(script.Parent.CannonHint)
local Targets = require(script.Parent.Targets)

local RockHint = {}

local settings = TutorialConfig.RockHint

function RockHint.View(data: any, helpers: CannonHint.Helpers): CannonHint.View
	local stage = SharedHint.StageOf(data)
	local rock = SharedHint.Rock()
	if not rock then
		return { IsDoing = true }
	end
	if stage == SharedHint.Train then
		local strength = if type(data.Strength) == "number" then data.Strength else 0
		local current = NumberFormat.Commas(math.floor(math.min(strength, rock.StrengthRequired)))
		local title = `Train for the {rock.DisplayName}! {current}/{rock.StrengthRequired}`
		if helpers.IsTraining() then
			return { Title = title, Detail = nil, IsDoing = true }
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
	local target = Targets.NearestRock(settings.RockKey)
	local adornee = if target then target.Adornee else nil
	return {
		Title = `Chop {rock.DisplayName}s! {SharedHint.PayoutMultiple()}x cash!`,
		Detail = if helpers.IsNear(target)
			then `{helpers.PromptKey(adornee, "Chop", true)} to chop!`
			else nil,
		Target = target,
		Teleport = settings.TeleportId,
		IsDoing = false,
	}
end

return RockHint
