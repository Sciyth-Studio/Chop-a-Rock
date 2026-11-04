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
	HatchSeconds: number,
	RobuxOnly: boolean?,
	IsFalling: boolean?,
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
			DisplayName = "Forest Geode",
			HatchSeconds = 30,
			TabName = "Forest",
			Order = 1,
			Price = 500,
			StrengthRequired = weakestRock("Forest"),
			ModelKey = "Model_Geode_Basic",
			SplitModelKey = "Model_GeodeSplit_Basic",
			Pets = {
				{ PetKey = "Bloky", Weight = 59.78 },
				{ PetKey = "Sprout", Weight = 25 },
				{ PetKey = "Shroomy", Weight = 10 },
				{ PetKey = "Nesty", Weight = 3.9 },
				{ PetKey = "Berry", Weight = 1.2 },
				{ PetKey = "Treebo", Weight = 0.12 },
			},
		},
		Desert = {
			DisplayName = "Desert Geode",
			HatchSeconds = 120,
			TabName = "Desert",
			Order = 2,
			Price = 40000,
			StrengthRequired = weakestRock("Desert"),
			ModelKey = "Model_Geode_Desert",
			SplitModelKey = "Model_GeodeSplit_Desert",
			Pets = {
				{ PetKey = "Pointy", Weight = 57.2 },
				{ PetKey = "Spike", Weight = 25 },
				{ PetKey = "Howdy", Weight = 11 },
				{ PetKey = "Flowy", Weight = 5 },
				{ PetKey = "Ankhy", Weight = 1.62 },
				{ PetKey = "Sunny", Weight = 0.18 },
			},
		},
		Jungle = {
			DisplayName = "Jungle Geode",
			HatchSeconds = 240,
			TabName = "Jungle",
			Order = 3,
			Price = 2560000,
			StrengthRequired = weakestRock("Jungle"),
			ModelKey = "Model_Geode_Jungle",
			SplitModelKey = "Model_GeodeSplit_Jungle",
			Pets = {
				{ PetKey = "Roly", Weight = 54.6 },
				{ PetKey = "Leafy", Weight = 25 },
				{ PetKey = "Viney", Weight = 12 },
				{ PetKey = "Coco", Weight = 6 },
				{ PetKey = "Tiki", Weight = 2.16 },
				{ PetKey = "Bloomy", Weight = 0.24 },
			},
		},
		Ocean = {
			DisplayName = "Ocean Geode",
			HatchSeconds = 300,
			TabName = "Ocean",
			Order = 4,
			Price = 491520000,
			StrengthRequired = weakestRock("Ocean"),
			ModelKey = "Model_Geode_Ocean",
			SplitModelKey = "Model_GeodeSplit_Ocean",
			Pets = {
				{ PetKey = "Drip", Weight = 49.4 },
				{ PetKey = "Bubbly", Weight = 25 },
				{ PetKey = "Shelly", Weight = 14 },
				{ PetKey = "Reefy", Weight = 8 },
				{ PetKey = "Glowy", Weight = 3.12 },
				{ PetKey = "Chompy", Weight = 0.48 },
			},
		},
		Snow = {
			DisplayName = "Snow Geode",
			HatchSeconds = 480,
			TabName = "Snow",
			Order = 5,
			Price = 36700160000,
			StrengthRequired = weakestRock("Snow"),
			ModelKey = "Model_Geode_Snow",
			SplitModelKey = "Model_GeodeSplit_Snow",
			Pets = {
				{ PetKey = "Hexy", Weight = 44.2 },
				{ PetKey = "Beanie", Weight = 25 },
				{ PetKey = "Cozy", Weight = 16 },
				{ PetKey = "Stacky", Weight = 10 },
				{ PetKey = "Climby", Weight = 4.2 },
				{ PetKey = "Starry", Weight = 0.6 },
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
		DisplayName = `Lucky {geode.TabName} Geode`,
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
		DisplayName = `Falling {geode.TabName} Geode`,
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
end

return table.freeze(GeodeConfig)
