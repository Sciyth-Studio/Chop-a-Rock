--!strict

export type ZoneBanner = {
	Title: string,
	Emoji: string,
	TextStyle: string,
	RecommendedRock: string,
}

export type ZoneBannerSettings = {
	Zones: { [string]: ZoneBanner },
	TemplateName: string,
	TitleName: string,
	RecommendedName: string,
	LabelName: string,
	ValueName: string,
	IconName: string,
	RecommendedText: string,
	ValueSuffix: string,
	ValueStyle: string,
	HoldSeconds: number,
	FadeInSeconds: number,
	FadeOutSeconds: number,
	LayoutOrder: number,
	PollSeconds: number,
}

local ZoneBannerConfig: ZoneBannerSettings = {
	Zones = {
		Forest = { Title = "Forest Zone", Emoji = "🌲", TextStyle = "Green", RecommendedRock = "Basic" },
		Desert = {
			Title = "Desert Zone",
			Emoji = "🌵",
			TextStyle = "Gold",
			RecommendedRock = "DesertFirst",
		},
		Jungle = {
			Title = "Jungle Zone",
			Emoji = "🌴",
			TextStyle = "Green",
			RecommendedRock = "JungleFirst",
		},
		Ocean = { Title = "Ocean Zone", Emoji = "🌊", TextStyle = "Sky", RecommendedRock = "OceanFirst" },
		Snow = { Title = "Snow Zone", Emoji = "❄️", TextStyle = "Chrome", RecommendedRock = "SnowFirst" },
		Swamp = { Title = "Swamp Zone", Emoji = "🐸", TextStyle = "Green", RecommendedRock = "SwampFirst" },
		Savanna = {
			Title = "Savanna Zone",
			Emoji = "🦁",
			TextStyle = "Gold",
			RecommendedRock = "SavannaFirst",
		},
		Bamboo = {
			Title = "Bamboo Zone",
			Emoji = "🎋",
			TextStyle = "Green",
			RecommendedRock = "BambooFirst",
		},
		Volcano = {
			Title = "Volcano Zone",
			Emoji = "🌋",
			TextStyle = "Red",
			RecommendedRock = "VolcanoFirst",
		},
		Ruins = {
			Title = "Ruins Zone",
			Emoji = "🏛️",
			TextStyle = "Chrome",
			RecommendedRock = "RuinsFirst",
		},
	},
	TemplateName = "ZoneTemplate",
	TitleName = "Title",
	RecommendedName = "Recommended",
	LabelName = "Label",
	ValueName = "Value",
	IconName = "Icon",
	RecommendedText = "Recommended:",
	ValueSuffix = " Strength",
	ValueStyle = "Strength",
	HoldSeconds = 3,
	FadeInSeconds = 0.25,
	FadeOutSeconds = 0.6,
	LayoutOrder = -2000,
	PollSeconds = 0.5,
}

return table.freeze(ZoneBannerConfig)
