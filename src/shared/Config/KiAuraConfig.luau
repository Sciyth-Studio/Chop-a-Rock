--!strict

export type KiAuraTextures = {
	Glow: string,
	CoreGlow: string,
	Flame: string,
	Ring: string,
	Spark: string,
	Crackle: string,
}

export type KiAuraSettings = {
	ColorAttribute: string,
	AccentAttribute: string,
	IntensityAttribute: string,
	EnabledAttribute: string,
	DefaultColor: Color3,
	DefaultIntensity: number,
	MinRateScale: number,
	MinSizeScale: number,
	MinHeightScale: number,
	MinLightScale: number,
	PulsePeriodSlow: number,
	PulsePeriodFast: number,
	PopScale: number,
	PopTime: number,
	PopLight: number,
	FadeTime: number,
	LightBrightness: number,
	LightRange: number,
	FlickerAmount: number,
	SwayAmount: number,
	GlowParts: { string },
	Textures: KiAuraTextures,
}

local function texture(id: number): string
	return `rbxassetid://{id}`
end

local KiAuraConfig: KiAuraSettings = {
	ColorAttribute = "AuraColor",
	AccentAttribute = "AuraAccentColor",
	IntensityAttribute = "AuraIntensity",
	EnabledAttribute = "AuraEnabled",
	DefaultColor = Color3.fromRGB(255, 200, 60),
	DefaultIntensity = 1,
	MinRateScale = 0.4,
	MinSizeScale = 0.78,
	MinHeightScale = 0.65,
	MinLightScale = 0.45,
	PulsePeriodSlow = 2,
	PulsePeriodFast = 1.1,
	PopScale = 1.6,
	PopTime = 0.4,
	PopLight = 2.5,
	FadeTime = 0.3,
	LightBrightness = 0.9,
	LightRange = 13,
	FlickerAmount = 0.18,
	SwayAmount = 6,
	GlowParts = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	},
	Textures = {
		Glow = texture(867619398),
		CoreGlow = texture(14183571391),
		Flame = texture(567395887),
		Ring = texture(7083340510),
		Spark = texture(6679618752),
		Crackle = texture(13771290435),
	},
}

return table.freeze(KiAuraConfig)
