--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type Reward = {
	Cash: number,
	Strength: number,
}

export type Zone = {
	Key: string,
	DisplayName: string,
	GeodeKey: string?,
	Entries: { string },
}

export type Page = {
	Key: string,
	DisplayName: string,
	Kind: "Pets" | "Rocks",
	Zones: { Zone },
}

export type IndexSettings = {
	Pages: { Page },
	PetRewards: { [string]: Reward },
	RockReward: Reward,
	ZoneCashBonus: number,
	ZoneKeySeparator: string,
	HiddenName: string,
	HiddenColor: Color3,
	Palette: {
		Claim: ShopConfig.MeterColors,
		Claimed: ShopConfig.MeterColors,
		TabActive: ShopConfig.MeterColors,
		TabIdle: ShopConfig.MeterColors,
		Progress: ShopConfig.MeterColors,
		ProgressDone: ShopConfig.MeterColors,
	},
	RockCardColor: Color3,
	SelectedStrokeColor: Color3,
	IdleStrokeColor: Color3,
	Preview: {
		CameraDirection: Vector3,
		FieldOfView: number,
		CameraPadding: number,
	},
	RockPreviewKeys: { [string]: string },
	Text: {
		Claim: string,
		Claimed: string,
		ClaimAll: string,
		Locked: string,
	},
}

local IndexConfig: IndexSettings = {
	Pages = {
		{
			Key = "Roks",
			DisplayName = "Roks",
			Kind = "Pets",
			Zones = {
				{
					Key = "Forest",
					DisplayName = "Forest",
					GeodeKey = "Forest",
					Entries = { "Bloky", "Sprout", "Shroomy", "Nesty", "Berry", "Treebo" },
				},
				{
					Key = "Desert",
					DisplayName = "Desert",
					GeodeKey = "Desert",
					Entries = { "Pointy", "Spike", "Howdy", "Flowy", "Ankhy", "Sunny" },
				},
				{
					Key = "Jungle",
					DisplayName = "Jungle",
					GeodeKey = "Jungle",
					Entries = { "Roly", "Leafy", "Viney", "Coco", "Tiki", "Bloomy" },
				},
			},
		},
		{
			Key = "Rocks",
			DisplayName = "Rocks",
			Kind = "Rocks",
			Zones = {
				{
					Key = "Forest",
					DisplayName = "Forest",
					Entries = { "Basic", "Second", "Third" },
				},
				{
					Key = "Desert",
					DisplayName = "Desert",
					Entries = { "DesertFirst", "DesertSecond", "DesertThird" },
				},
				{
					Key = "Jungle",
					DisplayName = "Jungle",
					Entries = { "JungleFirst", "JungleSecond", "JungleThird" },
				},
				{
					Key = "Ocean",
					DisplayName = "Ocean",
					Entries = { "OceanFirst", "OceanSecond", "OceanThird" },
				},
				{
					Key = "Snow",
					DisplayName = "Snow",
					Entries = { "SnowFirst", "SnowSecond", "SnowThird" },
				},
			},
		},
	},
	PetRewards = {
		Common = { Cash = 50, Strength = 5 },
		Uncommon = { Cash = 100, Strength = 10 },
		Rare = { Cash = 250, Strength = 25 },
		Epic = { Cash = 600, Strength = 60 },
		Legendary = { Cash = 1500, Strength = 150 },
		Secret = { Cash = 5000, Strength = 500 },
	},
	RockReward = { Cash = 100, Strength = 10 },
	ZoneCashBonus = 0.1,
	ZoneKeySeparator = ":",
	HiddenName = "???",
	HiddenColor = Color3.fromRGB(0, 0, 0),
	Palette = {
		Claim = ShopConfig.Palette.Green,
		Claimed = ShopConfig.Palette.Grey,
		TabActive = {
			Edge = Color3.fromRGB(120, 0, 220),
			Center = Color3.fromRGB(200, 120, 255),
			Studs = Color3.fromRGB(70, 0, 140),
		},
		TabIdle = ShopConfig.Palette.Grey,
		Progress = ShopConfig.Palette.Green,
		ProgressDone = {
			Edge = Color3.fromRGB(255, 170, 0),
			Center = Color3.fromRGB(255, 245, 130),
			Studs = Color3.fromRGB(190, 100, 0),
		},
	},
	RockCardColor = Color3.fromRGB(150, 150, 160),
	SelectedStrokeColor = Color3.fromRGB(255, 255, 255),
	IdleStrokeColor = Color3.fromRGB(0, 0, 0),
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
	RockPreviewKeys = {
		Basic = "Model_RockPreview_Basic",
		Second = "Model_RockPreview_Second",
		Third = "Model_RockPreview_Third",
		DesertFirst = "Model_RockPreview_DesertFirst",
		DesertSecond = "Model_RockPreview_DesertSecond",
		DesertThird = "Model_RockPreview_DesertThird",
		JungleFirst = "Model_RockPreview_JungleFirst",
		JungleSecond = "Model_RockPreview_JungleSecond",
		JungleThird = "Model_RockPreview_JungleThird",
		OceanFirst = "Model_RockPreview_OceanFirst",
		OceanSecond = "Model_RockPreview_OceanSecond",
		OceanThird = "Model_RockPreview_OceanThird",
		SnowFirst = "Model_RockPreview_SnowFirst",
		SnowSecond = "Model_RockPreview_SnowSecond",
		SnowThird = "Model_RockPreview_SnowThird",
	},
	Text = {
		Claim = "Claim",
		Claimed = "Claimed!",
		ClaimAll = "Claim All",
		Locked = "Not Found",
	},
}

return table.freeze(IndexConfig)
