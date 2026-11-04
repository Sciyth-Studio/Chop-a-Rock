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
		Bunny = {
			DisplayName = "Bunny",
			Rarity = "Common",
			ModelKey = "Model_Pet_Bunny",
			MoneyPerSecond = 2,
		},
		Squirrel = {
			DisplayName = "Squirrel",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Squirrel",
			MoneyPerSecond = 4,
		},
		Fox = {
			DisplayName = "Fox",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Fox",
			MoneyPerSecond = 10,
		},
		Owl = {
			DisplayName = "Owl",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Owl",
			MoneyPerSecond = 24,
		},
		Bear = {
			DisplayName = "Bear",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Bear",
			MoneyPerSecond = 60,
		},
		Unicorn = {
			DisplayName = "Unicorn",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Unicorn",
			MoneyPerSecond = 300,
		},
		Gecko = {
			DisplayName = "Gecko",
			Rarity = "Common",
			ModelKey = "Model_Pet_Gecko",
			MoneyPerSecond = 120,
		},
		Armadillo = {
			DisplayName = "Armadillo",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Armadillo",
			MoneyPerSecond = 240,
		},
		Scorpion = {
			DisplayName = "Scorpion",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Scorpion",
			MoneyPerSecond = 600,
		},
		Vulture = {
			DisplayName = "Vulture",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Vulture",
			MoneyPerSecond = 1440,
		},
		Camel = {
			DisplayName = "Camel",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Camel",
			MoneyPerSecond = 3600,
		},
		Sphinx = {
			DisplayName = "Sphinx",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Sphinx",
			MoneyPerSecond = 18000,
		},
		Monkey = {
			DisplayName = "Monkey",
			Rarity = "Common",
			ModelKey = "Model_Pet_Monkey",
			MoneyPerSecond = 7680,
		},
		Toucan = {
			DisplayName = "Toucan",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Toucan",
			MoneyPerSecond = 15360,
		},
		Sloth = {
			DisplayName = "Sloth",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Sloth",
			MoneyPerSecond = 38400,
		},
		Tiger = {
			DisplayName = "Tiger",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Tiger",
			MoneyPerSecond = 92160,
		},
		Gorilla = {
			DisplayName = "Gorilla",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Gorilla",
			MoneyPerSecond = 230400,
		},
		Panther = {
			DisplayName = "Panther",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Panther",
			MoneyPerSecond = 1152000,
		},
		Crab = {
			DisplayName = "Crab",
			Rarity = "Common",
			ModelKey = "Model_Pet_Crab",
			MoneyPerSecond = 409600,
		},
		Clownfish = {
			DisplayName = "Clownfish",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Clownfish",
			MoneyPerSecond = 819200,
		},
		Turtle = {
			DisplayName = "Turtle",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Turtle",
			MoneyPerSecond = 2048000,
		},
		Octopus = {
			DisplayName = "Octopus",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Octopus",
			MoneyPerSecond = 4915200,
		},
		Shark = {
			DisplayName = "Shark",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Shark",
			MoneyPerSecond = 12288000,
		},
		Narwhal = {
			DisplayName = "Narwhal",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Narwhal",
			MoneyPerSecond = 61440000,
		},
		Penguin = {
			DisplayName = "Penguin",
			Rarity = "Common",
			ModelKey = "Model_Pet_Penguin",
			MoneyPerSecond = 20971520,
		},
		Seal = {
			DisplayName = "Seal",
			Rarity = "Uncommon",
			ModelKey = "Model_Pet_Seal",
			MoneyPerSecond = 41943040,
		},
		Reindeer = {
			DisplayName = "Reindeer",
			Rarity = "Rare",
			ModelKey = "Model_Pet_Reindeer",
			MoneyPerSecond = 120000000,
		},
		Walrus = {
			DisplayName = "Walrus",
			Rarity = "Epic",
			ModelKey = "Model_Pet_Walrus",
			MoneyPerSecond = 251658240,
		},
		ArcticWolf = {
			DisplayName = "Arctic Wolf",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_ArcticWolf",
			MoneyPerSecond = 629145600,
		},
		Yeti = {
			DisplayName = "Yeti",
			Rarity = "Secret",
			ModelKey = "Model_Pet_Yeti",
			MoneyPerSecond = 3145728000,
		},
		Capybara = {
			DisplayName = "Capybara",
			Rarity = "Legendary",
			ModelKey = "Model_Pet_Capybara",
			MoneyPerSecond = 100,
			Exclusive = true,
		},
		KingRex = {
			DisplayName = "King Rex",
			Rarity = "Secret",
			ModelKey = "Model_Pet_KingRex",
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
