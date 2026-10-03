--!strict

export type MusicSettings = {
	FolderName: string,
	FadeInSeconds: number,
	LoadTimeoutSeconds: number,
}

local MusicConfig: MusicSettings = {
	FolderName = "Music",
	FadeInSeconds = 1.5,
	LoadTimeoutSeconds = 10,
}

return table.freeze(MusicConfig)
