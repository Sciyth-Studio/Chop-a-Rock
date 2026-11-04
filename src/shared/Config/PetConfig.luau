--!strict

export type Pet = {
	DisplayName: string,
	Rarity: string,
	ModelKey: string,
	MoneyPerSecond: number,
	Exclusive: boolean?,
	IncomeRule: string?,
	IncomeMultiplier: number?,
	AuraKey: string?,
}

export type Trait = {
	DisplayName: string,
	MinValue: number,
	MaxValue: number,
}

export type PetSettings = {
	Pets: { [string]: Pet },
	MaxPets: number,
	PendingCheckSeconds: number,
	SellValueSeconds: number,
	ToolScale: number,
	TraitChance: number,
	TraitRarities: { [string]: boolean },
	Traits: { [string]: Trait },
}

local PetConfig: PetSettings = {
	Pets = {
		Bloky = {
			DisplayName = "Bloky",
			Rarity = "Common",
			ModelKey = "Model_Pet_Bloky",
			MoneyPerSecond = 2,
		},
		Sprout = {
			DisplayName = "Sprout",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Sprout",
			MoneyPerSecond = 4,
		},
		Shroomy = {
			DisplayName = "Shroomy",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Shroomy",
			MoneyPerSecond = 10,
		},
		Nesty = {
			DisplayName = "Nesty",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Nesty",
			MoneyPerSecond = 24,
		},
		Berry = {
			DisplayName = "Berry",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Berry",
			MoneyPerSecond = 60,
		},
		Treebo = {
			DisplayName = "Treebo",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Treebo",
			MoneyPerSecond = 300,
		},
		Pointy = {
			DisplayName = "Pointy",
			Rarity = "Common",
			ModelKey = "Model_Pet_Pointy",
			MoneyPerSecond = 120,
		},
		Spike = {
			DisplayName = "Spike",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Spike",
			MoneyPerSecond = 240,
		},
		Howdy = {
			DisplayName = "Howdy",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Howdy",
			MoneyPerSecond = 600,
		},
		Flowy = {
			DisplayName = "Flowy",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Flowy",
			MoneyPerSecond = 1440,
		},
		Ankhy = {
			DisplayName = "Ankhy",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Ankhy",
			MoneyPerSecond = 3600,
		},
		Sunny = {
			DisplayName = "Sunny",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Sunny",
			MoneyPerSecond = 18000,
		},
		Roly = {
			DisplayName = "Roly",
			Rarity = "Common",
			ModelKey = "Model_Pet_Roly",
			MoneyPerSecond = 7680,
		},
		Leafy = {
			DisplayName = "Leafy",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Leafy",
			MoneyPerSecond = 15360,
		},
		Viney = {
			DisplayName = "Viney",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Viney",
			MoneyPerSecond = 38400,
		},
		Coco = {
			DisplayName = "Coco",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Coco",
			MoneyPerSecond = 92160,
		},
		Tiki = {
			DisplayName = "Tiki",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Tiki",
			MoneyPerSecond = 230400,
		},
		Bloomy = {
			DisplayName = "Bloomy",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Bloomy",
			MoneyPerSecond = 1152000,
		},
		Drip = {
			DisplayName = "Drip",
			Rarity = "Common",
			ModelKey = "Model_Pet_Drip",
			MoneyPerSecond = 409600,
		},
		Bubbly = {
			DisplayName = "Bubbly",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Bubbly",
			MoneyPerSecond = 819200,
		},
		Shelly = {
			DisplayName = "Shelly",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Shelly",
			MoneyPerSecond = 2048000,
		},
		Reefy = {
			DisplayName = "Reefy",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Reefy",
			MoneyPerSecond = 4915200,
		},
		Glowy = {
			DisplayName = "Glowy",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Glowy",
			MoneyPerSecond = 12288000,
		},
		Chompy = {
			DisplayName = "Chompy",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Chompy",
			MoneyPerSecond = 61440000,
		},
		Hexy = {
			DisplayName = "Hexy",
			Rarity = "Common",
			ModelKey = "Model_Pet_Hexy",
			MoneyPerSecond = 20971520,
		},
		Beanie = {
			DisplayName = "Beanie",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Beanie",
			MoneyPerSecond = 41943040,
		},
		Cozy = {
			DisplayName = "Cozy",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Cozy",
			MoneyPerSecond = 120000000,
		},
		Stacky = {
			DisplayName = "Stacky",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Stacky",
			MoneyPerSecond = 251658240,
		},
		Climby = {
			DisplayName = "Climby",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Climby",
			MoneyPerSecond = 629145600,
		},
		Starry = {
			DisplayName = "Starry",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Starry",
			MoneyPerSecond = 3145728000,
		},
		Champ = {
			DisplayName = "Champ",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Champ",
			MoneyPerSecond = 100,
			Exclusive = true,
		},
		Kingy = {
			DisplayName = "Kingy",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Kingy",
			MoneyPerSecond = 100,
			Exclusive = true,
			IncomeRule = "BestTimes",
			IncomeMultiplier = 3,
			AuraKey = "VFX_Pet_GoldAura",
		},
	},
	MaxPets = 100,
	PendingCheckSeconds = 5,
	SellValueSeconds = 15,
	ToolScale = 0.6,
	TraitChance = 0.25,
	TraitRarities = {
		Epic = true,
		Legendary = true,
		Secret = true,
	},
	Traits = {
		WalkSpeed = {
			DisplayName = "Speed",
			MinValue = 1,
			MaxValue = 3,
		},
		Luck = {
			DisplayName = "Luck",
			MinValue = 0.05,
			MaxValue = 0.15,
		},
		TrainingSpeed = {
			DisplayName = "Training",
			MinValue = 0.05,
			MaxValue = 0.1,
		},
	},
}

return table.freeze(PetConfig)
