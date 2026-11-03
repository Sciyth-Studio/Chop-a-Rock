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
	GeodeGapStuds = 10,
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
		Forest = { Looks = { "Model_Geode_Basic", "Model_Geode_Basic" } },
		Desert = { Looks = { "Model_Geode_Desert", "Model_Geode_Desert" } },
		Jungle = { Looks = { "Model_Geode_Jungle", "Model_Geode_Jungle" } },
		Ocean = { Looks = { "Model_Geode_Ocean", "Model_Geode_Ocean" } },
		Snow = { Looks = { "Model_Geode_Snow", "Model_Geode_Snow" } },
	},
}

return table.freeze(ZoneGeodeConfig)
