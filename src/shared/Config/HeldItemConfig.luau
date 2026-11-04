--!strict

export type HeldItemSettings = {
	AnimationKey: string,
	FadeSeconds: number,
	LoadTimeoutSeconds: number,
	GapStuds: number,
	OverheadGrip: CFrame,
}

local HeldItemConfig: HeldItemSettings = {
	AnimationKey = "Anim_Held_Overhead",
	FadeSeconds = 0.15,
	LoadTimeoutSeconds = 5,
	GapStuds = 0.3,
	OverheadGrip = CFrame.new(
		1.2764,
		0.4642,
		-0.2684,
		0.9945,
		0.0217,
		0.1022,
		0.1010,
		0.0534,
		-0.9935,
		-0.0270,
		0.9983,
		0.0509
	),
}

return table.freeze(HeldItemConfig)
