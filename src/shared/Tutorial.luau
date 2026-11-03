--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type State = {
	Step: number,
	Taps: number,
	Furthest: number,
}

local Tutorial = {
	Train = 1,
	Chop = 2,
	GetGeode = 3,
	Place = 4,
	Open = 5,
	Final = 6,
	Done = 7,
	AuraBought = 8,
	AuraTrained = 9,
	SecondPet = 10,
	FirstRebirth = 11,
	Played30Min = 12,
	Played60Min = 13,
}

Tutorial.LastMilestone = Tutorial.Played60Min

Tutorial.Funnel = {
	"Train",
	"Chop",
	"GetGeode",
	"PlaceGeode",
	"OpenGeode",
	"Final",
	"Done",
	"AuraBought",
	"AuraTrained",
	"SecondPet",
	TutorialConfig.FirstRebirthFunnelName,
	"Played30Min",
	"Played60Min",
}

Tutorial.Titles = {
	[Tutorial.Train] = "Break the boards!",
	[Tutorial.Chop] = "Chop some rocks!",
	[Tutorial.GetGeode] = "Grab a geode!",
	[Tutorial.Place] = "Place your geode!",
	[Tutorial.Open] = "Open your geode!",
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

function Tutorial.IsPadOpen(step: number, _screen: string): boolean
	return not Tutorial.IsActive(step)
end

function Tutorial.CanTakeGeode(step: number): boolean
	return not Tutorial.IsActive(step) or step == Tutorial.GetGeode
end

function Tutorial.RocksBroken(data: any): number
	local index = if type(data) == "table" then data.Index else nil
	local rocks = if type(index) == "table" then index.Rocks else nil
	local count = if type(rocks) == "table" then rocks[TutorialConfig.FirstChopRockKey] else nil
	return if type(count) == "number" then count else 0
end

function Tutorial.CanBuyAura(step: number): boolean
	return not Tutorial.IsActive(step)
end

function Tutorial.StrengthGoal(step: number): number?
	if step == Tutorial.Train then
		return TutorialConfig.TrainGoal
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
