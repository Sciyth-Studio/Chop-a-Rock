--!strict

export type GeodePet = {
	PetKey: string,
	Weight: number,
}

export type Geode = {
	DisplayName: string,
	TabName: string,
	Order: number,
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
			TabName = "Forest",
			Order = 1,
			Price = 500,
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
		Desert = {
			DisplayName = "Desert Geode",
			TabName = "Desert",
			Order = 2,
			Price = 40000,
			StrengthRequired = 2500,
			ModelKey = "Model_Geode_Desert",
			SplitModelKey = "Model_GeodeSplit_Desert",
			Pets = {
				{ PetKey = "Pointy", Weight = 57.5 },
				{ PetKey = "Spike", Weight = 25 },
				{ PetKey = "Howdy", Weight = 11 },
				{ PetKey = "Flowy", Weight = 5 },
				{ PetKey = "Ankhy", Weight = 1.35 },
				{ PetKey = "Sunny", Weight = 0.15 },
			},
		},
		Jungle = {
			DisplayName = "Jungle Geode",
			TabName = "Jungle",
			Order = 3,
			Price = 2560000,
			StrengthRequired = 312500,
			ModelKey = "Model_Geode_Jungle",
			SplitModelKey = "Model_GeodeSplit_Jungle",
			Pets = {
				{ PetKey = "Roly", Weight = 55 },
				{ PetKey = "Leafy", Weight = 25 },
				{ PetKey = "Viney", Weight = 12 },
				{ PetKey = "Coco", Weight = 6 },
				{ PetKey = "Tiki", Weight = 1.8 },
				{ PetKey = "Bloomy", Weight = 0.2 },
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
