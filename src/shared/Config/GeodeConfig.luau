--!strict

export type GeodePet = {
	PetKey: string,
	Weight: number,
}

export type Geode = {
	DisplayName: string,
	Price: number,
	StrengthRequired: number,
	ModelKey: string,
	SplitModelKey: string,
	Pets: { GeodePet },
}

export type GeodeSettings = {
	Geodes: { [string]: Geode },
	BuyAmounts: { number },
	PitPromptRangeStuds: number,
	TooWeakClearSeconds: number,
	RecrackDelaySeconds: number,
	AnnouncementKind: string,
	ZoneStrengthRatio: number,
}

local GeodeConfig: GeodeSettings = {
	Geodes = {
		Forest = {
			DisplayName = "Forest Geode",
			Price = 250,
			StrengthRequired = 10,
			ModelKey = "Model_Geode_Basic",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Bloky", Weight = 60 },
				{ PetKey = "Sprout", Weight = 25 },
				{ PetKey = "Shroomy", Weight = 10 },
				{ PetKey = "Nesty", Weight = 3.9 },
				{ PetKey = "Berry", Weight = 1 },
				{ PetKey = "Treebo", Weight = 0.1 },
			},
		},
	},
	BuyAmounts = { 1, 3 },
	PitPromptRangeStuds = 14,
	TooWeakClearSeconds = 0.8,
	RecrackDelaySeconds = 1,
	AnnouncementKind = "Event",
	ZoneStrengthRatio = 1,
}

return table.freeze(GeodeConfig)
