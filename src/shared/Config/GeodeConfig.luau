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
	SecondModelKey: string?,
	SplitModelKey: string,
	Pets: { GeodePet },
	HatchSeconds: number,
	RobuxOnly: boolean?,
	IsFalling: boolean?,
	IsSecondLook: boolean?,
	ShortName: string?,
	BaseKey: string?,
	MinRarity: string?,
	GuaranteedModifier: boolean?,
}

export type GeodeSettings = {
	Geodes: { [string]: Geode },
	HatchPromptRangeStuds: number,
	HatchPromptHoldSeconds: number,
	HatchPadCount: number,
	HatchPadPrefix: string,
	HatchPadTag: string,
	HatchSpotName: string,
	HatchPathPartName: string,
	HatchRefreshSeconds: number,
	PlacePromptText: string,
	PlaceAllPromptText: string,
	OpenPromptText: string,
	SkipPromptText: string,
	HatchReadyText: string,
	HatchLabelHeightStuds: number,
	PickPromptKey: Enum.KeyCode,
	PickPromptGamepadKey: Enum.KeyCode,
	AnnouncementKind: string,
	ZoneStrengthRatio: number,
	LuckyKeyPrefix: string,
	LuckyMinRarity: string,
	FallingKeyPrefix: string,
	FallingMinRarity: string,
	SecondLookSuffix: string,
	ToolKeyAttribute: string,
	ToolScale: number,
}

local RockConfig = require(script.Parent.RockConfig)
local RockSpawnConfig = require(script.Parent.RockSpawnConfig)

local function weakestRock(zone: string): number
	local weakest = math.huge
	local spawnZone = RockSpawnConfig.Zones[zone]
	if spawnZone then
		for rockKey in spawnZone.Weights do
			local rock = RockConfig.Rocks[rockKey]
			if rock then
				weakest = math.min(weakest, rock.StrengthRequired)
			end
		end
	end
	if weakest == math.huge then
		error(`[GeodeConfig] no rocks for zone {zone}`)
	end
	return weakest
end

local GeodeConfig: GeodeSettings = {
	Geodes = {
		Forest = {
			DisplayName = "Forest Egg",
			HatchSeconds = 30,
			TabName = "Forest",
			Order = 1,
			Price = 500,
			StrengthRequired = weakestRock("Forest"),
			ModelKey = "Model_Egg_ForestMossy",
			SecondModelKey = "Model_Egg_ForestMushroom",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Bunny", Weight = 59.78 },
				{ PetKey = "Squirrel", Weight = 25 },
				{ PetKey = "Fox", Weight = 10 },
				{ PetKey = "Owl", Weight = 3.9 },
				{ PetKey = "Bear", Weight = 1.2 },
				{ PetKey = "Unicorn", Weight = 0.12 },
			},
		},
		Desert = {
			DisplayName = "Desert Egg",
			HatchSeconds = 120,
			TabName = "Desert",
			Order = 2,
			Price = 40000,
			StrengthRequired = weakestRock("Desert"),
			ModelKey = "Model_Egg_DesertMesa",
			SecondModelKey = "Model_Egg_DesertCactus",
			SplitModelKey = "Model_GeodeSplit_Desert",
			Pets = {
				{ PetKey = "Gecko", Weight = 57.2 },
				{ PetKey = "Armadillo", Weight = 25 },
				{ PetKey = "Scorpion", Weight = 11 },
				{ PetKey = "Vulture", Weight = 5 },
				{ PetKey = "Camel", Weight = 1.62 },
				{ PetKey = "Sphinx", Weight = 0.18 },
			},
		},
		Jungle = {
			DisplayName = "Jungle Egg",
			HatchSeconds = 240,
			TabName = "Jungle",
			Order = 3,
			Price = 2560000,
			StrengthRequired = weakestRock("Jungle"),
			ModelKey = "Model_Egg_JungleVine",
			SecondModelKey = "Model_Egg_JungleTiki",
			SplitModelKey = "Model_GeodeSplit_Jungle",
			Pets = {
				{ PetKey = "Monkey", Weight = 54.6 },
				{ PetKey = "Toucan", Weight = 25 },
				{ PetKey = "Sloth", Weight = 12 },
				{ PetKey = "Tiger", Weight = 6 },
				{ PetKey = "Gorilla", Weight = 2.16 },
				{ PetKey = "Panther", Weight = 0.24 },
			},
		},
		Ocean = {
			DisplayName = "Ocean Egg",
			HatchSeconds = 300,
			TabName = "Ocean",
			Order = 4,
			Price = 491520000,
			StrengthRequired = weakestRock("Ocean"),
			ModelKey = "Model_Egg_OceanReef",
			SecondModelKey = "Model_Egg_OceanBarnacle",
			SplitModelKey = "Model_GeodeSplit_Ocean",
			Pets = {
				{ PetKey = "Crab", Weight = 49.4 },
				{ PetKey = "Clownfish", Weight = 25 },
				{ PetKey = "Turtle", Weight = 14 },
				{ PetKey = "Octopus", Weight = 8 },
				{ PetKey = "Shark", Weight = 3.12 },
				{ PetKey = "Narwhal", Weight = 0.48 },
			},
		},
		Snow = {
			DisplayName = "Snow Egg",
			HatchSeconds = 480,
			TabName = "Snow",
			Order = 5,
			Price = 36700160000,
			StrengthRequired = weakestRock("Snow"),
			ModelKey = "Model_Egg_SnowCap",
			SecondModelKey = "Model_Egg_SnowIcicle",
			SplitModelKey = "Model_GeodeSplit_Snow",
			Pets = {
				{ PetKey = "Penguin", Weight = 44.2 },
				{ PetKey = "Seal", Weight = 25 },
				{ PetKey = "Reindeer", Weight = 16 },
				{ PetKey = "Walrus", Weight = 10 },
				{ PetKey = "ArcticWolf", Weight = 4.2 },
				{ PetKey = "Yeti", Weight = 0.6 },
			},
		},
		Swamp = {
			DisplayName = "Swamp Egg",
			HatchSeconds = 660,
			TabName = "Swamp",
			Order = 6,
			Price = 4026531840000,
			StrengthRequired = weakestRock("Swamp"),
			ModelKey = "Model_Egg_SwampMud",
			SecondModelKey = "Model_Egg_SwampLily",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Frog", Weight = 39 },
				{ PetKey = "Duck", Weight = 25 },
				{ PetKey = "Snail", Weight = 18 },
				{ PetKey = "Beaver", Weight = 12 },
				{ PetKey = "Alligator", Weight = 5.16 },
				{ PetKey = "Hydra", Weight = 0.84 },
			},
		},
		Savanna = {
			DisplayName = "Savanna Egg",
			HatchSeconds = 720,
			TabName = "Savanna",
			Order = 7,
			Price = 343597383680000,
			StrengthRequired = weakestRock("Savanna"),
			ModelKey = "Model_Egg_SavannaAcacia",
			SecondModelKey = "Model_Egg_SavannaAnthill",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Zebra", Weight = 37 },
				{ PetKey = "Giraffe", Weight = 25 },
				{ PetKey = "Rhino", Weight = 19 },
				{ PetKey = "Elephant", Weight = 13 },
				{ PetKey = "Cheetah", Weight = 5.04 },
				{ PetKey = "Lion", Weight = 0.96 },
			},
		},
		Bamboo = {
			DisplayName = "Bamboo Egg",
			HatchSeconds = 900,
			TabName = "Bamboo",
			Order = 8,
			Price = 2.74877906944e+16,
			StrengthRequired = weakestRock("Bamboo"),
			ModelKey = "Model_Egg_BambooStalk",
			SecondModelKey = "Model_Egg_BambooPagoda",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Beetle", Weight = 35 },
				{ PetKey = "Koi", Weight = 25 },
				{ PetKey = "Crane", Weight = 20 },
				{ PetKey = "Panda", Weight = 14 },
				{ PetKey = "RedPanda", Weight = 4.92 },
				{ PetKey = "MonkeySensei", Weight = 1.08 },
			},
		},
		Volcano = {
			DisplayName = "Volcano Egg",
			HatchSeconds = 1200,
			TabName = "Volcano",
			Order = 9,
			Price = 2.11106232532992e+18,
			StrengthRequired = weakestRock("Volcano"),
			ModelKey = "Model_Egg_VolcanoEmber",
			SecondModelKey = "Model_Egg_VolcanoCrater",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Salamander", Weight = 33 },
				{ PetKey = "ImpCat", Weight = 25 },
				{ PetKey = "LavaTortoise", Weight = 21 },
				{ PetKey = "Hellhound", Weight = 15 },
				{ PetKey = "Dragon", Weight = 4.8 },
				{ PetKey = "Phoenix", Weight = 1.2 },
			},
		},
		Ruins = {
			DisplayName = "Ruins Egg",
			HatchSeconds = 1620,
			TabName = "Ruins",
			Order = 10,
			Price = 1.4636698788954112e+20,
			StrengthRequired = weakestRock("Ruins"),
			ModelKey = "Model_Egg_RuinsRune",
			SecondModelKey = "Model_Egg_RuinsColumn",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Bat", Weight = 31 },
				{ PetKey = "Raven", Weight = 25 },
				{ PetKey = "WizardCat", Weight = 22 },
				{ PetKey = "GuardDog", Weight = 16 },
				{ PetKey = "Minotaur", Weight = 4.8 },
				{ PetKey = "NineTailedFox", Weight = 1.2 },
			},
		},
	},
	HatchPromptRangeStuds = 8,
	HatchPromptHoldSeconds = 0.3,
	HatchPadCount = 8,
	HatchPadPrefix = "BasePlot_Pad",
	HatchPadTag = "HatchPad",
	HatchSpotName = "HatchSpot",
	HatchPathPartName = "BasePlot_Path",
	HatchRefreshSeconds = 1,
	PlacePromptText = "Place",
	PlaceAllPromptText = "Place All",
	OpenPromptText = "Open",
	SkipPromptText = "Skip Wait",
	HatchReadyText = "Ready!",
	HatchLabelHeightStuds = 7,
	PickPromptKey = Enum.KeyCode.F,
	PickPromptGamepadKey = Enum.KeyCode.ButtonY,
	AnnouncementKind = "Event",
	ZoneStrengthRatio = 1,
	LuckyKeyPrefix = "Lucky",
	LuckyMinRarity = "Rare",
	FallingKeyPrefix = "Falling",
	FallingMinRarity = "Rare",
	SecondLookSuffix = "B",
	ToolKeyAttribute = "GeodeKey",
	ToolScale = 0.5,
}

local baseKeys: { string } = {}
for key in GeodeConfig.Geodes do
	table.insert(baseKeys, key)
end
for _, key in baseKeys do
	local geode = GeodeConfig.Geodes[key]
	GeodeConfig.Geodes[GeodeConfig.LuckyKeyPrefix .. key] = {
		DisplayName = `Lucky {geode.TabName} Egg`,
		ShortName = `Lucky {geode.TabName}`,
		TabName = geode.TabName,
		Order = geode.Order,
		Price = 0,
		HatchSeconds = 0,
		StrengthRequired = geode.StrengthRequired,
		ModelKey = geode.ModelKey,
		SplitModelKey = geode.SplitModelKey,
		Pets = geode.Pets,
		RobuxOnly = true,
		BaseKey = key,
		MinRarity = GeodeConfig.LuckyMinRarity,
		GuaranteedModifier = true,
	}
	GeodeConfig.Geodes[GeodeConfig.FallingKeyPrefix .. key] = {
		DisplayName = `Falling {geode.TabName} Egg`,
		ShortName = `Falling {geode.TabName}`,
		TabName = geode.TabName,
		Order = geode.Order,
		Price = 0,
		HatchSeconds = geode.HatchSeconds,
		StrengthRequired = geode.StrengthRequired,
		ModelKey = geode.ModelKey,
		SplitModelKey = geode.SplitModelKey,
		Pets = geode.Pets,
		IsFalling = true,
		BaseKey = key,
		MinRarity = GeodeConfig.FallingMinRarity,
	}
	GeodeConfig.Geodes[key .. GeodeConfig.SecondLookSuffix] = {
		DisplayName = geode.DisplayName,
		TabName = geode.TabName,
		Order = geode.Order,
		Price = geode.Price,
		HatchSeconds = geode.HatchSeconds,
		StrengthRequired = geode.StrengthRequired,
		ModelKey = geode.SecondModelKey or geode.ModelKey,
		SplitModelKey = geode.SplitModelKey,
		Pets = geode.Pets,
		IsSecondLook = true,
		BaseKey = key,
	}
end

return table.freeze(GeodeConfig)
