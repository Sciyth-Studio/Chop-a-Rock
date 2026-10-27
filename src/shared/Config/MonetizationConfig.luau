--!strict

local IconConfig = require(script.Parent.IconConfig)

export type Pass = {
	Key: string,
	DisplayName: string,
	Blurb: string,
	GamepassId: number?,
	RobuxPrice: number,
	Includes: { string }?,
}

export type BoostProduct = {
	ProductId: number?,
	RobuxPrice: number,
	Seconds: number,
}

export type Boost = {
	Key: string,
	DisplayName: string,
	Products: { BoostProduct },
	OnlyWhileTraining: boolean?,
}

export type ServerBoost = {
	Key: string,
	DisplayName: string,
	ProductId: number?,
	RobuxPrice: number,
	Seconds: number,
}

export type LuckyGeodeProduct = {
	ProductId: number?,
	RobuxPrice: number,
	Count: number,
	IsFirstOnly: boolean,
}

export type StarterPack = {
	ProductId: number?,
	RobuxPrice: number,
	Geodes: number,
	RokKey: string,
	BoostKey: string,
	BoostSeconds: number,
	LuckyGeodes: number,
	RestrictedExtraGeodes: number,
	OfferSeconds: number,
	DueAttribute: string,
}

export type OfflineClaim = {
	ProductId: number?,
	RobuxPrice: number,
	ExtraMultiplier: number,
	MinAwaySeconds: number,
	MinGeodes: number,
	DueAttribute: string,
}

export type BoostPillEntry = {
	Source: "Personal" | "Server",
	Key: string,
	Text: string,
	TextStyle: string,
	Icon: string,
}

export type BoostPillSettings = {
	EdgeOffsetPixels: number,
	WeatherHeightPixels: number,
	GapPixels: number,
	MinutesFormat: string,
	HoursFormat: string,
	PausedSuffix: string,
	Pills: { BoostPillEntry },
}

export type Exclusive = {
	Key: string,
	RokKey: string,
	ProductId: number?,
	RobuxPrice: number,
	Stock: number,
	StockKey: string,
	Pitch: string,
}

export type ExclusiveSettings = {
	Items: { Exclusive },
	StandTag: string,
	KeyAttribute: string,
	SoldAttribute: string,
	StockAttribute: string,
	PriceAttribute: string,
	StoreName: string,
	RefreshSeconds: number,
	RokScale: number,
	PromptName: string,
	PromptRangeStuds: number,
	PromptHoldSeconds: number,
}

export type Gift = {
	Key: string,
	Kind: "Pass" | "Boost" | "Lucky" | "CashPack" | "Exclusive",
	Target: string,
	Index: number?,
	ProductId: number?,
}

export type VipBase = {
	PartColors: { [string]: Color3 },
	CarpetName: string,
	CarpetColor: Color3,
	Carpets: { { Size: Vector3, Offset: Vector3 } },
}

export type VipSettings = {
	PassKey: string,
	Base: VipBase,
	ChatTag: string,
	TagColor: string,
	NameColor: string,
}

export type MonetizationSettings = {
	Vip: VipSettings,
	Passes: { Pass },
	PassAttributePrefix: string,
	OwnershipRetrySeconds: number,
	PassMultiplierBonus: { [string]: number },
	BackpackBonus: number,
	Boosts: { Boost },
	BoostBonus: number,
	BoostCapSeconds: number,
	BoostSaveSeconds: number,
	BoostEndsAttributePrefix: string,
	BoostPausedAttributePrefix: string,
	TasteBoostKey: string,
	TasteSeconds: number,
	TasteOfferKey: string,
	ServerBoosts: { ServerBoost },
	ServerBoostBonus: number,
	ServerBoostCapSeconds: number,
	ServerBoostEndsAttributePrefix: string,
	ServerBoostByAttributePrefix: string,
	ServerBoostMaxNames: number,
	ServerBoostNameSeparator: string,
	LuckyGeodeProducts: { LuckyGeodeProduct },
	FirstLuckyOfferKey: string,
	RandomItemsRestrictedAttribute: string,
	StarterPack: StarterPack,
	OfflineClaim: OfflineClaim,
	BoostPill: BoostPillSettings,
	Exclusives: ExclusiveSettings,
	Gifts: { Gift },
	MaxGiftsReceived: number,
	ComingSoonText: string,
	BoughtSound: string,
	RobuxGlyph: string,
	RobuxButtonColors: { Edge: Color3, Center: Color3, Studs: Color3 },
}

local MonetizationConfig: MonetizationSettings = {
	Vip = {
		PassKey = "VIP",
		Base = {
			PartColors = {
				BasePlot_Floor = Color3.fromRGB(214, 198, 160),
				BasePlot_Stone = Color3.fromRGB(255, 190, 0),
				BasePlot_Crack = Color3.fromRGB(230, 170, 20),
				BasePlot_Trim = Color3.fromRGB(255, 190, 0),
				Pedestal = Color3.fromRGB(196, 178, 136),
				EarningsPadEdge = Color3.fromRGB(255, 190, 0),
			},
			CarpetName = "VipCarpet",
			CarpetColor = Color3.fromRGB(200, 0, 25),
			Carpets = {},
		},
		ChatTag = "[VIP]",
		TagColor = "#FFD500",
		NameColor = "#FFC400",
	},
	Passes = {
		{
			Key = "Luck",
			DisplayName = "2x Luck",
			Blurb = "Twice the luck on every geode you crack",
			GamepassId = 2052498180,
			RobuxPrice = 299,
		},
		{
			Key = "Strength",
			DisplayName = "2x Strength",
			Blurb = "Twice the strength every rep",
			GamepassId = 2053392229,
			RobuxPrice = 249,
		},
		{
			Key = "Cash",
			DisplayName = "2x Cash",
			Blurb = "Twice the cash from every chop",
			GamepassId = 2052162295,
			RobuxPrice = 199,
		},
		{
			Key = "AutoOpen",
			DisplayName = "Auto Open",
			Blurb = "Your pit cracks geodes for you",
			GamepassId = 2053686145,
			RobuxPrice = 199,
		},
		{
			Key = "Backpack",
			DisplayName = "Big Backpack",
			Blurb = "Room for 100 more Roks",
			GamepassId = 2055384154,
			RobuxPrice = 99,
		},
		{
			Key = "VIP",
			DisplayName = "VIP",
			Blurb = "Every pass, a VIP tag and a gold name",
			GamepassId = 2053344170,
			RobuxPrice = 799,
			Includes = { "Luck", "Strength", "Cash", "AutoOpen", "Backpack" },
		},
	},
	PassAttributePrefix = "Pass",
	OwnershipRetrySeconds = 30,
	PassMultiplierBonus = {
		Cash = 1,
		Strength = 1,
	},
	BackpackBonus = 100,
	Boosts = {
		{
			Key = "Cash",
			DisplayName = "2x Cash",
			Products = {
				{ ProductId = 3722325235, RobuxPrice = 19, Seconds = 900 },
				{ ProductId = 3722325239, RobuxPrice = 59, Seconds = 3600 },
			},
		},
		{
			Key = "Strength",
			DisplayName = "2x Strength",
			OnlyWhileTraining = true,
			Products = {
				{ ProductId = 3722325242, RobuxPrice = 19, Seconds = 900 },
				{ ProductId = 3722325247, RobuxPrice = 59, Seconds = 3600 },
			},
		},
	},
	BoostBonus = 1,
	BoostCapSeconds = 21600,
	BoostSaveSeconds = 30,
	BoostEndsAttributePrefix = "BoostEnds",
	BoostPausedAttributePrefix = "BoostPaused",
	TasteBoostKey = "Strength",
	TasteSeconds = 300,
	TasteOfferKey = "BoostTaste",
	ServerBoosts = {
		{
			Key = "Cash",
			DisplayName = "Server 2x Cash",
			ProductId = 3722325254,
			RobuxPrice = 99,
			Seconds = 900,
		},
		{
			Key = "Strength",
			DisplayName = "Server 2x Strength",
			ProductId = 3722325261,
			RobuxPrice = 99,
			Seconds = 900,
		},
		{
			Key = "Luck",
			DisplayName = "Server 2x Luck",
			ProductId = 3722325266,
			RobuxPrice = 169,
			Seconds = 900,
		},
	},
	ServerBoostBonus = 1,
	ServerBoostCapSeconds = 7200,
	ServerBoostEndsAttributePrefix = "ServerBoostEnds",
	ServerBoostByAttributePrefix = "ServerBoostBy",
	ServerBoostMaxNames = 3,
	ServerBoostNameSeparator = ", ",
	LuckyGeodeProducts = {
		{ ProductId = 3722325271, RobuxPrice = 9, Count = 1, IsFirstOnly = true },
		{ ProductId = 3722325276, RobuxPrice = 49, Count = 1, IsFirstOnly = false },
		{ ProductId = 3722325278, RobuxPrice = 129, Count = 3, IsFirstOnly = false },
		{ ProductId = 3722325281, RobuxPrice = 399, Count = 10, IsFirstOnly = false },
	},
	FirstLuckyOfferKey = "FirstLuckyGeode",
	RandomItemsRestrictedAttribute = "RandomItemsRestricted",
	StarterPack = {
		ProductId = 3722325285,
		RobuxPrice = 29,
		Geodes = 20,
		RokKey = "Champ",
		BoostKey = "Strength",
		BoostSeconds = 1800,
		LuckyGeodes = 1,
		RestrictedExtraGeodes = 3,
		OfferSeconds = 86400,
		DueAttribute = "StarterOfferDue",
	},
	OfflineClaim = {
		ProductId = 3722325288,
		RobuxPrice = 29,
		ExtraMultiplier = 2,
		MinAwaySeconds = 600,
		MinGeodes = 1,
		DueAttribute = "WelcomeBackDue",
	},
	BoostPill = {
		EdgeOffsetPixels = 16,
		WeatherHeightPixels = 64,
		GapPixels = 10,
		MinutesFormat = "%s (%02d:%02d)",
		HoursFormat = "%s (%d:%02d:%02d)",
		PausedSuffix = "paused",
		Pills = {
			{
				Source = "Server",
				Key = "Luck",
				Text = "Server 2x Luck",
				TextStyle = "Green",
				Icon = IconConfig.Luck,
			},
			{
				Source = "Server",
				Key = "Cash",
				Text = "Server 2x Cash",
				TextStyle = "Green",
				Icon = IconConfig.Money,
			},
			{
				Source = "Server",
				Key = "Strength",
				Text = "Server 2x Strength",
				TextStyle = "Strength",
				Icon = IconConfig.Strength,
			},
			{
				Source = "Personal",
				Key = "Cash",
				Text = "2x Cash",
				TextStyle = "Green",
				Icon = IconConfig.Money,
			},
			{
				Source = "Personal",
				Key = "Strength",
				Text = "2x Strength",
				TextStyle = "Strength",
				Icon = IconConfig.Strength,
			},
		},
	},
	Exclusives = {
		Items = {
			{
				Key = "Kingy",
				RokKey = "Kingy",
				ProductId = 3722325299,
				RobuxPrice = 1499,
				Stock = 10000,
				StockKey = "Kingy_1",
				Pitch = "Always 3x your best Rok!",
			},
		},
		StandTag = "ExclusiveStand",
		KeyAttribute = "Exclusive",
		SoldAttribute = "Sold",
		StockAttribute = "Stock",
		PriceAttribute = "Price",
		StoreName = "ExclusiveStock",
		RefreshSeconds = 60,
		RokScale = 3,
		PromptName = "BuyPrompt",
		PromptRangeStuds = 12,
		PromptHoldSeconds = 0,
	},
	Gifts = {
		{ Key = "Pass_Luck", Kind = "Pass", Target = "Luck", ProductId = 3722325304 },
		{ Key = "Pass_Strength", Kind = "Pass", Target = "Strength", ProductId = 3722325307 },
		{ Key = "Pass_Cash", Kind = "Pass", Target = "Cash", ProductId = 3722325310 },
		{ Key = "Pass_AutoOpen", Kind = "Pass", Target = "AutoOpen", ProductId = 3722325313 },
		{ Key = "Pass_Backpack", Kind = "Pass", Target = "Backpack", ProductId = 3722325315 },
		{ Key = "Pass_VIP", Kind = "Pass", Target = "VIP", ProductId = 3722325318 },
		{ Key = "Boost_Cash_15", Kind = "Boost", Target = "Cash", Index = 1, ProductId = 3722325325 },
		{ Key = "Boost_Cash_60", Kind = "Boost", Target = "Cash", Index = 2, ProductId = 3722325327 },
		{ Key = "Boost_Strength_15", Kind = "Boost", Target = "Strength", Index = 1, ProductId = 3722325334 },
		{ Key = "Boost_Strength_60", Kind = "Boost", Target = "Strength", Index = 2, ProductId = 3722325339 },
		{ Key = "Lucky_1", Kind = "Lucky", Target = "Lucky", Index = 2, ProductId = 3722325346 },
		{ Key = "Lucky_3", Kind = "Lucky", Target = "Lucky", Index = 3, ProductId = 3722325351 },
		{ Key = "Lucky_10", Kind = "Lucky", Target = "Lucky", Index = 4, ProductId = 3722325354 },
		{ Key = "Cash_Small", Kind = "CashPack", Target = "Small", ProductId = 3722325359 },
		{ Key = "Cash_Medium", Kind = "CashPack", Target = "Medium", ProductId = 3722325364 },
		{ Key = "Cash_Large", Kind = "CashPack", Target = "Large", ProductId = 3722325368 },
		{ Key = "Cash_Huge", Kind = "CashPack", Target = "Huge", ProductId = 3722325369 },
		{ Key = "Cash_Mega", Kind = "CashPack", Target = "Mega", ProductId = 3722325376 },
		{ Key = "Exclusive_Kingy", Kind = "Exclusive", Target = "Kingy", ProductId = 3722325382 },
	},
	MaxGiftsReceived = 100,
	ComingSoonText = "Coming soon!",
	BoughtSound = "SFX_Money_Gain",
	RobuxGlyph = utf8.char(0xE002),
	RobuxButtonColors = {
		Edge = Color3.fromRGB(230, 150, 0),
		Center = Color3.fromRGB(255, 230, 90),
		Studs = Color3.fromRGB(190, 105, 0),
	},
}

return table.freeze(MonetizationConfig)
