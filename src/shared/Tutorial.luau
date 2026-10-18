--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type State = {
	Step: number,
	Taps: number,
	Furthest: number,
}

local Tutorial = {
	Train = 1,
	Chop = 2,
	BuyArms = 3,
	TrainAgain = 4,
	ChopAgain = 5,
	BuyGeode = 6,
	Crack = 7,
	Collect = 8,
	Final = 9,
	Done = 10,
	FirstRebirth = 11,
}

Tutorial.Funnel = {
	"Train",
	"Chop",
	"BuyArms",
	"TrainAgain",
	"ChopAgain",
	"BuyGeode",
	"Crack",
	"Collect",
	"Final",
	"Done",
	TutorialConfig.FirstRebirthFunnelName,
}

Tutorial.Titles = {
	[Tutorial.Train] = "Break the boards!",
	[Tutorial.Chop] = "Chop rocks for cash!",
	[Tutorial.BuyArms] = "Buy new arms!",
	[Tutorial.TrainAgain] = "Train with your new arms!",
	[Tutorial.ChopAgain] = "Chop rocks for cash!",
	[Tutorial.BuyGeode] = "Buy a geode!",
	[Tutorial.Crack] = "Crack it at your base!",
	[Tutorial.Collect] = "Grab your Rok's cash!",
	[Tutorial.Final] = "You're ready! Go chop!",
}

function Tutorial.NewState(): State
	return { Step = Tutorial.Train, Taps = 0, Furthest = 0 }
end

function Tutorial.StepOf(state: any): number
	if type(state) == "table" and type(state.Step) == "number" then
		return state.Step
	end
	return Tutorial.Done
end

function Tutorial.IsActive(step: number): boolean
	return step < Tutorial.Done
end

function Tutorial.IsTraining(step: number): boolean
	return step == Tutorial.Train or step == Tutorial.TrainAgain
end

function Tutorial.IsChopping(step: number): boolean
	return step == Tutorial.Chop or step == Tutorial.ChopAgain
end

function Tutorial.CanChop(step: number): boolean
	return not Tutorial.IsActive(step) or Tutorial.IsChopping(step)
end

function Tutorial.PadScreen(step: number): string?
	if step == Tutorial.BuyArms then
		return "Shop"
	elseif step == Tutorial.BuyGeode then
		return "GeodeStand"
	end
	return nil
end

function Tutorial.IsPadOpen(step: number, screen: string): boolean
	return not Tutorial.IsActive(step) or Tutorial.PadScreen(step) == screen
end

function Tutorial.CanBuyArm(step: number): boolean
	return not Tutorial.IsActive(step) or step == Tutorial.BuyArms
end

function Tutorial.CanBuyGeode(step: number): boolean
	return not Tutorial.IsActive(step) or step == Tutorial.BuyGeode
end

function Tutorial.ArmPrice(): number
	local tier = ArmConfig.Tiers[2]
	return if tier then tier.Price else 0
end

function Tutorial.GeodePrice(): number
	local geode = GeodeConfig.Geodes[TutorialConfig.GeodeKey]
	return if geode then geode.Price else 0
end

function Tutorial.StrengthGoal(step: number): number?
	if step == Tutorial.Train then
		return TutorialConfig.TrainGoal
	elseif step == Tutorial.TrainAgain then
		return TutorialConfig.TrainAgainGoal
	end
	return nil
end

function Tutorial.CashGoal(step: number): number?
	if step == Tutorial.Chop or step == Tutorial.BuyArms then
		return Tutorial.ArmPrice()
	elseif step == Tutorial.ChopAgain or step == Tutorial.BuyGeode then
		return Tutorial.GeodePrice()
	end
	return nil
end

function Tutorial.ForcesPerfect(step: number, data: any): boolean
	if step ~= Tutorial.Chop or type(data) ~= "table" then
		return false
	end
	local index = data.Index
	local rocks = if type(index) == "table" then index.Rocks else nil
	return type(rocks) ~= "table" or rocks[TutorialConfig.FirstChopRockKey] == nil
end

function Tutorial.IsValid(state: any): boolean
	if type(state) ~= "table" then
		return false
	end
	for _, key in { "Step", "Taps", "Furthest" } do
		local value = state[key]
		if value ~= nil and (type(value) ~= "number" or value ~= value or value < 0 or value % 1 ~= 0) then
			return false
		end
	end
	return true
end

return table.freeze(Tutorial)
