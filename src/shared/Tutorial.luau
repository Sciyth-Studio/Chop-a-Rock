--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	BuyGeode = 3,
	Crack = 4,
	Collect = 5,
	Final = 6,
	Done = 7,
	AuraBought = 8,
	AuraTrained = 9,
	SecondRok = 10,
	FirstRebirth = 11,
	Played30Min = 12,
	Played60Min = 13,
}

Tutorial.LastMilestone = Tutorial.Played60Min

Tutorial.Funnel = {
	"Train",
	"Chop",
	"BuyGeode",
	"Crack",
	"Collect",
	"Final",
	"Done",
	"AuraBought",
	"AuraTrained",
	"SecondRok",
	TutorialConfig.FirstRebirthFunnelName,
	"Played30Min",
	"Played60Min",
}

Tutorial.Titles = {
	[Tutorial.Train] = "Break the boards!",
	[Tutorial.Chop] = "Chop rocks for cash!",
	[Tutorial.BuyGeode] = "Buy a geode!",
	[Tutorial.Crack] = "Crack your geode!",
	[Tutorial.Collect] = "Step on green pad!",
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
	return step == Tutorial.Train
end

function Tutorial.IsChopping(step: number): boolean
	return step == Tutorial.Chop
end

function Tutorial.CanChop(step: number): boolean
	return not Tutorial.IsActive(step) or Tutorial.IsChopping(step)
end

function Tutorial.PadScreen(step: number): string?
	if step == Tutorial.BuyGeode then
		return "GeodeStand"
	end
	return nil
end

function Tutorial.IsPadOpen(step: number, screen: string): boolean
	return not Tutorial.IsActive(step) or Tutorial.PadScreen(step) == screen
end

function Tutorial.CanBuyAura(step: number): boolean
	return not Tutorial.IsActive(step)
end

function Tutorial.CanBuyGeode(step: number): boolean
	return not Tutorial.IsActive(step) or step == Tutorial.BuyGeode
end

function Tutorial.GeodePrice(): number
	return TutorialConfig.GeodePrice
end

function Tutorial.GeodeCost(step: number, geodeKey: string, amount: number): number
	local geode = GeodeConfig.Geodes[geodeKey]
	if not geode then
		return 0
	end
	if step == Tutorial.BuyGeode and geodeKey == TutorialConfig.GeodeKey and amount == 1 then
		return TutorialConfig.GeodePrice
	end
	return geode.Price * amount
end

function Tutorial.StrengthGoal(step: number): number?
	if step == Tutorial.Train then
		return TutorialConfig.TrainGoal
	end
	return nil
end

function Tutorial.CashGoal(step: number): number?
	if step == Tutorial.Chop or step == Tutorial.BuyGeode then
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
