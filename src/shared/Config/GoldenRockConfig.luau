--!strict

export type GoldenRockSettings = {
	Modifier: string,
	Chance: number,
	PayoutMultiplier: number,
	GoldenAttribute: string,
	Color: Color3,
	OutlineColor: Color3,
	GlowKey: string,
	BurstKey: string,
	BreakSoundKey: string,
	PopMain: Color3,
	PopLight: Color3,
	PopDark: Color3,
}

local GoldenRockConfig: GoldenRockSettings = {
	Modifier = "Golden",
	Chance = 0.02,
	PayoutMultiplier = 3,
	GoldenAttribute = "IsGolden",
	Color = Color3.fromRGB(255, 200, 0),
	OutlineColor = Color3.fromRGB(255, 230, 0),
	GlowKey = "VFX_Rush_Glow",
	BurstKey = "VFX_Rush_Burst",
	BreakSoundKey = "SFX_Rush_Chime",
	PopMain = Color3.fromRGB(255, 200, 0),
	PopLight = Color3.fromRGB(255, 255, 120),
	PopDark = Color3.fromRGB(255, 100, 0),
}

return table.freeze(GoldenRockConfig)
