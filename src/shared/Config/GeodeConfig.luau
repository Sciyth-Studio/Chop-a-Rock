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
	Pity: { [string]: number }?,
	RobuxOnly: boolean?,
	BaseKey: string?,
	MinRarity: string?,
	GuaranteedModifier: boolean?,
}

export type GeodeSettings = {
	Geodes: { [string]: Geode },
	PityRarities: { string },
	BuyAmounts: { number },
	PitPromptRangeStuds: number,
	TooWeakClearSeconds: number,
	RecrackDelaySeconds: number,
	AnnouncementKind: string,
	CrackingAttribute: string,
	ZoneStrengthRatio: number,
	LuckyKeyPrefix: string,
	LuckyMinRarity: string,
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
			DisplayName = "Forest Geode",
			TabName = "Forest",
			Order = 1,
			Price = 500,
			StrengthRequired = weakestRock("Forest"),
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
			Pity = { Legendary = 165, Secret = 1830 },
		},
		Desert = {
			DisplayName = "Desert Geode",
			TabName = "Desert",
			Order = 2,
			Price = 40000,
			StrengthRequired = weakestRock("Desert"),
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
			Pity = { Legendary = 110, Secret = 1120 },
		},
		Jungle = {
			DisplayName = "Jungle Geode",
			TabName = "Jungle",
			Order = 3,
			Price = 2560000,
			StrengthRequired = weakestRock("Jungle"),
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
			Pity = { Legendary = 75, Secret = 780 },
		},
		Ocean = {
			DisplayName = "Ocean Geode",
			TabName = "Ocean",
			Order = 4,
			Price = 491520000,
			StrengthRequired = weakestRock("Ocean"),
			ModelKey = "Model_Geode_Ocean",
			SplitModelKey = "Model_GeodeSplit_Ocean",
			Pets = {
				{ PetKey = "Drip", Weight = 50 },
				{ PetKey = "Bubbly", Weight = 25 },
				{ PetKey = "Shelly", Weight = 14 },
				{ PetKey = "Reefy", Weight = 8 },
				{ PetKey = "Glowy", Weight = 2.6 },
				{ PetKey = "Chompy", Weight = 0.4 },
			},
			Pity = { Legendary = 50, Secret = 360 },
		},
		Snow = {
			DisplayName = "Snow Geode",
			TabName = "Snow",
			Order = 5,
			Price = 36700160000,
			StrengthRequired = weakestRock("Snow"),
			ModelKey = "Model_Geode_Snow",
			SplitModelKey = "Model_GeodeSplit_Snow",
			Pets = {
				{ PetKey = "Hexy", Weight = 45 },
				{ PetKey = "Beanie", Weight = 25 },
				{ PetKey = "Cozy", Weight = 16 },
				{ PetKey = "Stacky", Weight = 10 },
				{ PetKey = "Climby", Weight = 3.5 },
				{ PetKey = "Starry", Weight = 0.5 },
			},
			Pity = { Legendary = 35, Secret = 270 },
		},
	},
	PityRarities = { "Secret", "Legendary" },
	BuyAmounts = { 1, 3 },
	PitPromptRangeStuds = 14,
	TooWeakClearSeconds = 0.8,
	RecrackDelaySeconds = 1,
	AnnouncementKind = "Event",
	CrackingAttribute = "CrackingGeode",
	ZoneStrengthRatio = 1,
	LuckyKeyPrefix = "Lucky",
	LuckyMinRarity = "Rare",
}

local baseKeys: { string } = {}
for key in GeodeConfig.Geodes do
	table.insert(baseKeys, key)
end
for _, key in baseKeys do
	local geode = GeodeConfig.Geodes[key]
	GeodeConfig.Geodes[GeodeConfig.LuckyKeyPrefix .. key] = {
		DisplayName = `Lucky {geode.TabName} Geode`,
		TabName = geode.TabName,
		Order = geode.Order,
		Price = 0,
		StrengthRequired = geode.StrengthRequired,
		ModelKey = geode.ModelKey,
		SplitModelKey = geode.SplitModelKey,
		Pets = geode.Pets,
		RobuxOnly = true,
		BaseKey = key,
		MinRarity = GeodeConfig.LuckyMinRarity,
		GuaranteedModifier = true,
	}
end

return table.freeze(GeodeConfig)
