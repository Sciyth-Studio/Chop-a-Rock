--!strict

export type AmbienceSettings = {
	FolderName: string,
	SoundGroupName: string,
	PollSeconds: number,
	FadeSeconds: number,
}

local AmbienceConfig: AmbienceSettings = {
	FolderName = "Ambience",
	SoundGroupName = "SoundEffects",
	PollSeconds = 0.5,
	FadeSeconds = 2,
}

return table.freeze(AmbienceConfig)
