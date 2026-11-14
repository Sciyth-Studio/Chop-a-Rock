--!strict

export type Outcome = number

local Outcomes = table.freeze({
	Blocked = 1,
	Perfect = 2,
	Missed = 3,
})

local BlockRoundConfig = table.freeze({
	Outcomes = Outcomes,
	ZoneWidth = 0.13,
	PerfectWidth = 0.04,
	LeadSeconds = 0.6,
	Difficulties = table.freeze({
		Normal = table.freeze({ Speed = 1, ZoneScale = 1 }),
		Mad = table.freeze({ Speed = 1.2, ZoneScale = 0.85 }),
	}),
	RockTestEvery = 4,
	CheatName = "BlockRounds",
	MadCheatName = "BlockRoundsMad",
	WarningText = "Block!",
	WarningTextStyle = "Red",
	OutcomeTexts = table.freeze({
		[Outcomes.Blocked] = "Blocked!",
		[Outcomes.Perfect] = "Perfect block!",
		[Outcomes.Missed] = "Ouch!",
	}),
	OutcomeTextStyles = table.freeze({
		[Outcomes.Blocked] = "Green",
		[Outcomes.Missed] = "Red",
	}),
	WarningSound = "SFX_Cannon_Whoosh",
	OutcomeSounds = table.freeze({
		[Outcomes.Blocked] = "SFX_Train_Vault",
		[Outcomes.Perfect] = "SFX_Chop_Perfect",
		[Outcomes.Missed] = "SFX_Enemy_Hit",
	}),
	MissedShakeIntensity = 0.6,
	MissedShakeSeconds = 0.35,
})

return BlockRoundConfig
