--!strict

export type MusicSettings = {
	FolderName: string,
	FadeInSeconds: number,
	LoadTimeoutSeconds: number,
	BossFightFolderName: string,
	BossStingFolderName: string,
	BossFadeInSeconds: number,
	BossFadeOutSeconds: number,
	BossMadSemitones: number,
	BossMadSeconds: number,
	BossStingDuck: number,
	BossStingDuckSeconds: number,
	BossCheckSeconds: number,
	BossHearMin: Vector2,
	BossHearMax: Vector2,
}

local MusicConfig: MusicSettings = {
	FolderName = "Music",
	FadeInSeconds = 1.5,
	LoadTimeoutSeconds = 10,
	BossFightFolderName = "BossFight",
	BossStingFolderName = "BossFinish",
	BossFadeInSeconds = 0.5,
	BossFadeOutSeconds = 1.5,
	BossMadSemitones = 2,
	BossMadSeconds = 0.4,
	BossStingDuck = 0.35,
	BossStingDuckSeconds = 6,
	BossCheckSeconds = 0.5,
	BossHearMin = Vector2.new(-132, -781),
	BossHearMax = Vector2.new(216, -433),
}

return table.freeze(MusicConfig)
