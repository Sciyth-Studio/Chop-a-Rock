--!strict

export type MusicSettings = {
	Tracks: { string },
	Volume: number,
	FadeInSeconds: number,
	LoadTimeoutSeconds: number,
}

local MusicConfig: MusicSettings = {
	Tracks = {},
	Volume = 0.4,
	FadeInSeconds = 1.5,
	LoadTimeoutSeconds = 10,
}

return table.freeze(MusicConfig)
