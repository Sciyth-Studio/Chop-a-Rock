--!strict

export type Zone = {
	Looks: { string },
}

export type ZoneGeodeSettings = {
	RingTag: string,
	GrantWithoutEnemyService: boolean,
	GeodesPerZone: number,
	RespawnSeconds: number,
	RetrySeconds: number,
	CentreClearRatio: number,
	GeodeGapStuds: number,
	PlayerClearanceStuds: number,
	ClearanceSize: Vector3,
	PromptRangeStuds: number,
	PromptRangeSlackStuds: number,
	PromptHoldSeconds: number,
	PromptText: string,
	RiseSeconds: number,
	SinkSeconds: number,
	SinkStuds: number,
	AdminSpawnStuds: number,
	AdminGroundDepthStuds: number,
	TooWeakText: string,
	BagFullText: string,
	FolderName: string,
	Zones: { [string]: Zone },
}

local ZoneGeodeConfig: ZoneGeodeSettings = {
	RingTag = "ZoneGeodeRing",
	GrantWithoutEnemyService = false,
	GeodesPerZone = 4,
	RespawnSeconds = 30,
	RetrySeconds = 5,
	CentreClearRatio = 0.35,
	GeodeGapStuds = 30,
	PlayerClearanceStuds = 6,
	ClearanceSize = Vector3.new(8, 7, 8),
	PromptRangeStuds = 10,
	PromptRangeSlackStuds = 6,
	PromptHoldSeconds = 0,
	PromptText = "Take",
	RiseSeconds = 0.6,
	SinkSeconds = 0.3,
	SinkStuds = 0.2,
	AdminSpawnStuds = 10,
	AdminGroundDepthStuds = 40,
	TooWeakText = "Get stronger!",
	BagFullText = "Bag full! Sell Pets",
	FolderName = "ZoneGeodes",
	Zones = {
		Forest = { Looks = { "Forest", "ForestB" } },
		Desert = { Looks = { "Desert", "DesertB" } },
		Jungle = { Looks = { "Jungle", "JungleB" } },
		Ocean = { Looks = { "Ocean", "OceanB" } },
		Snow = { Looks = { "Snow", "SnowB" } },
		Swamp = { Looks = { "Swamp", "SwampB" } },
		Savanna = { Looks = { "Savanna", "SavannaB" } },
		Bamboo = { Looks = { "Bamboo", "BambooB" } },
		Volcano = { Looks = { "Volcano", "VolcanoB" } },
		Ruins = { Looks = { "Ruins", "RuinsB" } },
	},
}

return table.freeze(ZoneGeodeConfig)
