--!strict

export type Pet = {
	DisplayName: string,
	Rarity: string,
	ModelKey: string,
	MoneyMultiplier: number,
}

export type Trait = {
	DisplayName: string,
	MinValue: number,
	MaxValue: number,
}

export type PetSettings = {
	Pets: { [string]: Pet },
	MaxPets: number,
	TraitChance: number,
	TraitRarities: { [string]: boolean },
	Traits: { [string]: Trait },
}

local PetConfig: PetSettings = {
	Pets = {
		Bloky = {
			DisplayName = "Bloky",
			Rarity = "Common",
			ModelKey = "Model_Rok_Bloky",
			MoneyMultiplier = 1.1,
		},
		Sprout = {
			DisplayName = "Sprout",
			Rarity = "Uncommon",
			ModelKey = "Model_Rok_Sprout",
			MoneyMultiplier = 1.25,
		},
		Shroomy = {
			DisplayName = "Shroomy",
			Rarity = "Rare",
			ModelKey = "Model_Rok_Shroomy",
			MoneyMultiplier = 1.5,
		},
		Nesty = {
			DisplayName = "Nesty",
			Rarity = "Epic",
			ModelKey = "Model_Rok_Nesty",
			MoneyMultiplier = 2,
		},
		Berry = {
			DisplayName = "Berry",
			Rarity = "Legendary",
			ModelKey = "Model_Rok_Berry",
			MoneyMultiplier = 3,
		},
		Treebo = {
			DisplayName = "Treebo",
			Rarity = "Secret",
			ModelKey = "Model_Rok_Treebo",
			MoneyMultiplier = 5,
		},
	},
	MaxPets = 100,
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
