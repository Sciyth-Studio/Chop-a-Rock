--!strict

export type BossSounds = {
	Hit: string,
}

local bosses: { [string]: BossSounds } = {
	BigCroc = table.freeze({ Hit = "SFX_Boss_HitHide" }),
	BoulderCrab = table.freeze({ Hit = "SFX_Boss_HitShell" }),
	FrostYeti = table.freeze({ Hit = "SFX_Boss_HitFur" }),
}

local BossSoundConfig = table.freeze({
	Bosses = table.freeze(bosses),
	Snore = "SFX_Boss_Snore",
	WakeRoar = "SFX_Boss_Roar",
	MadRoar = "SFX_Boss_MadRoar",
	Swing = "SFX_Boss_Swing",
	AttackImpact = "SFX_Boss_Slam",
	StompImpact = "SFX_Boss_Stomp",
	BigAttackLand = "SFX_Boss_BigLand",
	SpotMoved = "SFX_Boss_SpotMoved",
	Dizzy = "SFX_Boss_Dizzy",
	KnockOut = "SFX_Boss_KnockOut",
	TimerTick = "SFX_Boss_Tick",
	DefeatThud = "SFX_Boss_Thud",
	Poof = "SFX_Boss_Poof",
	Win = "SFX_Boss_Win",
	-- Signature moves; played by the ChopBar overlay (BossOverlays) when each effect shows.
	Chomp = "SFX_Boss_Chomp",
	ShellHide = "SFX_Boss_ShellHide",
	Frost = "SFX_Boss_Frost",
	RoarMarker = "Roar",
	HitMarker = "Hit",
	LandMarker = "Land",
	RoarFallbackSeconds = 1.7,
	AttackHitFallbackSeconds = 1.5,
	StompHitFallbackSeconds = 1,
	BigAttackHitFallbackSeconds = 4,
	LandFallbackSeconds = 0.9,
	SwingLeadSeconds = 0.16,
	HitMinGapSeconds = 0.07,
	HitPitchSpread = 0.06,
	TickSeconds = 10,
	HearDistance = 260,
	RollOffMinDistance = 100,
	RollOffMaxDistance = 500,
	LoopFadeSeconds = 0.4,
})

return BossSoundConfig
