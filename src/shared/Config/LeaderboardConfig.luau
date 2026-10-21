--!strict

export type Board = {
	Key: string,
	Title: string,
	Column: string,
	Format: "Strength" | "Rate" | "Count" | "Duration",
}

export type LeaderboardSettings = {
	RefreshSeconds: number,
	FirstRefreshDelaySeconds: number,
	Rows: number,
	RankLimit: number,
	StorePrefix: string,
	StudioStorePrefix: string,
	EncodeScale: number,
	BoardTag: string,
	BoardAttribute: string,
	RowTemplateName: string,
	StatueSpotName: string,
	StatueTag: string,
	StatueScale: number,
	UnrankedText: string,
	MedalColors: { Color3 },
	RowColors: { Color3 },
	Boards: { Board },
}

local LeaderboardConfig: LeaderboardSettings = {
	RefreshSeconds = 60,
	FirstRefreshDelaySeconds = 5,
	Rows = 10,
	RankLimit = 100,
	StorePrefix = "Leaderboard_",
	StudioStorePrefix = "Leaderboard_Studio_",
	EncodeScale = 1e13,
	BoardTag = "Leaderboard",
	BoardAttribute = "Board",
	RowTemplateName = "RowTemplate",
	StatueSpotName = "StatueSpot",
	StatueTag = "ChopDummy",
	StatueScale = 1.6,
	UnrankedText = "#100+",
	MedalColors = {
		Color3.fromRGB(255, 196, 0),
		Color3.fromRGB(200, 214, 230),
		Color3.fromRGB(230, 110, 30),
	},
	RowColors = {
		Color3.fromRGB(60, 60, 60),
		Color3.fromRGB(40, 40, 40),
	},
	Boards = {
		{ Key = "Strength", Title = "Top Strength", Column = "Strength", Format = "Strength" },
		{ Key = "MoneyPerSecond", Title = "Top Money/s", Column = "Money/s", Format = "Rate" },
		{ Key = "PerfectChops", Title = "Top Perfect Chops", Column = "Perfects", Format = "Count" },
		{ Key = "Playtime", Title = "Top Playtime", Column = "Time", Format = "Duration" },
	},
}

return table.freeze(LeaderboardConfig)
