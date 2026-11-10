--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggDropConfig = require(ReplicatedStorage.Config.EggDropConfig)

local Roll = {}

function Roll.Luck(random: Random, skill: number, hadMaster: boolean, isGolden: boolean): number
	local curve = EggDropConfig.LuckCurveAtNoSkill
		+ (EggDropConfig.LuckCurveAtFullSkill - EggDropConfig.LuckCurveAtNoSkill)
			* math.clamp(skill, 0, 1)
	local span = EggDropConfig.LuckMaxHundredths - EggDropConfig.LuckMinHundredths
	local luck = EggDropConfig.LuckMinHundredths + span * random:NextNumber() ^ curve
	if isGolden then
		luck += EggDropConfig.GoldenLuckBonusHundredths
	end
	if hadMaster then
		luck = math.max(luck, EggDropConfig.MasterLuckFloorHundredths)
	end
	return math.clamp(
		math.floor(luck + 0.5),
		EggDropConfig.LuckMinHundredths,
		EggDropConfig.LuckMaxHundredths
	)
end

function Roll.IsRare(random: Random, skill: number): boolean
	local chance = EggDropConfig.RareChanceAtNoSkill
		+ (EggDropConfig.RareChanceAtFullSkill - EggDropConfig.RareChanceAtNoSkill)
			* math.clamp(skill, 0, 1)
	return random:NextNumber() < chance
end

return Roll
