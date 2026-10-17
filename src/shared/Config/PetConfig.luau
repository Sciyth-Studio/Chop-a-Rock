--!strict

export type Pet = {
	DisplayName: string,
	Rarity: string,
	ModelKey: string,
	MoneyPerSecond: number,
}

export type Trait = {
	DisplayName: string,
	MinValue: number,
	MaxValue: number,
}

export type PetSettings = {
	Pets: { [string]: Pet },
	MaxPets: number,
	SellValueSeconds: number,
	ToolScale: number,
	ToolGrip: CFrame,
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
			MoneyPerSecond = 1,
		},
		Sprout = {
			DisplayName = "Sprout",
			Rarity = "Uncommon",
			ModelKey = "Model_Rok_Sprout",
			MoneyPerSecond = 2,
		},
		Shroomy = {
			DisplayName = "Shroomy",
			Rarity = "Rare",
			ModelKey = "Model_Rok_Shroomy",
			MoneyPerSecond = 5,
		},
		Nesty = {
			DisplayName = "Nesty",
			Rarity = "Epic",
			ModelKey = "Model_Rok_Nesty",
			MoneyPerSecond = 12,
		},
		Berry = {
			DisplayName = "Berry",
			Rarity = "Legendary",
			ModelKey = "Model_Rok_Berry",
			MoneyPerSecond = 30,
		},
		Treebo = {
			DisplayName = "Treebo",
			Rarity = "Secret",
			ModelKey = "Model_Rok_Treebo",
			MoneyPerSecond = 150,
		},
		Pointy = {
			DisplayName = "Pointy",
			Rarity = "Common",
			ModelKey = "Model_Rok_Pointy",
			MoneyPerSecond = 80,
		},
		Spike = {
			DisplayName = "Spike",
			Rarity = "Uncommon",
			ModelKey = "Model_Rok_Spike",
			MoneyPerSecond = 160,
		},
		Howdy = {
			DisplayName = "Howdy",
			Rarity = "Rare",
			ModelKey = "Model_Rok_Howdy",
			MoneyPerSecond = 400,
		},
		Flowy = {
			DisplayName = "Flowy",
			Rarity = "Epic",
			ModelKey = "Model_Rok_Flowy",
			MoneyPerSecond = 960,
		},
		Ankhy = {
			DisplayName = "Ankhy",
			Rarity = "Legendary",
			ModelKey = "Model_Rok_Ankhy",
			MoneyPerSecond = 2400,
		},
		Sunny = {
			DisplayName = "Sunny",
			Rarity = "Secret",
			ModelKey = "Model_Rok_Sunny",
			MoneyPerSecond = 12000,
		},
		Roly = {
			DisplayName = "Roly",
			Rarity = "Common",
			ModelKey = "Model_Rok_Roly",
			MoneyPerSecond = 5120,
		},
		Leafy = {
			DisplayName = "Leafy",
			Rarity = "Uncommon",
			ModelKey = "Model_Rok_Leafy",
			MoneyPerSecond = 10240,
		},
		Viney = {
			DisplayName = "Viney",
			Rarity = "Rare",
			ModelKey = "Model_Rok_Viney",
			MoneyPerSecond = 25600,
		},
		Coco = {
			DisplayName = "Coco",
			Rarity = "Epic",
			ModelKey = "Model_Rok_Coco",
			MoneyPerSecond = 61440,
		},
		Tiki = {
			DisplayName = "Tiki",
			Rarity = "Legendary",
			ModelKey = "Model_Rok_Tiki",
			MoneyPerSecond = 153600,
		},
		Bloomy = {
			DisplayName = "Bloomy",
			Rarity = "Secret",
			ModelKey = "Model_Rok_Bloomy",
			MoneyPerSecond = 768000,
		},
	},
	MaxPets = 100,
	SellValueSeconds = 100,
	ToolScale = 0.6,
	ToolGrip = CFrame.new(0, -0.3, 0.6),
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
