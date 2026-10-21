--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type Cannon = {
	Key: string,
	DisplayName: string,
	ZoneName: string,
	ZoneNumber: number,
	Price: number,
	StrengthRequired: number,
	Color: Color3,
	Marker: string,
}

export type Shake = {
	Degrees: number,
	Seconds: number,
	Frequency: number,
}

export type CannonEffects = {
	Fuse: string,
	Charge: string,
	Blast: string,
	Trail: string,
	Land: string,
	Equip: string,
}

export type CannonSounds = {
	Fuse: string,
	Boom: string,
	Whoosh: string,
	Land: string,
	Equip: string,
}

export type ShopStyle = {
	Outline: Color3,
	EquippedOutline: Color3,
	FireButton: ShopConfig.MeterColors,
}

export type CannonSettings = {
	ScreenName: string,
	CannonName: string,
	MuzzleName: string,
	TintAttribute: string,
	EmptyColor: Color3,
	FlightSeconds: number,
	CooldownSeconds: number,
	ArcHeightRatio: number,
	MinArcHeightStuds: number,
	MuzzleFallbackHeightStuds: number,
	StreamTimeoutSeconds: number,
	ChargeSeconds: number,
	PullSeconds: number,
	PullRangeStuds: number,
	FuseName: string,
	BoreName: string,
	LandLeadSeconds: number,
	TrailFadeSeconds: number,
	ChargeLighten: number,
	TintSaturation: number,
	BlastShake: Shake,
	LandShake: Shake,
	Effects: CannonEffects,
	Sounds: CannonSounds,
	Shop: ShopStyle,
	Cannons: { Cannon },
}

local CannonConfig: CannonSettings = {
	ScreenName = "CannonShop",
	CannonName = "LobbyCannon",
	MuzzleName = "Muzzle",
	TintAttribute = "ZoneTint",
	EmptyColor = Color3.fromRGB(120, 120, 120),
	FlightSeconds = 2,
	CooldownSeconds = 3,
	ArcHeightRatio = 0.25,
	MinArcHeightStuds = 60,
	MuzzleFallbackHeightStuds = 6,
	StreamTimeoutSeconds = 2,
	ChargeSeconds = 0.5,
	PullSeconds = 0.25,
	PullRangeStuds = 30,
	FuseName = "Fuse",
	BoreName = "Bore",
	LandLeadSeconds = 0.08,
	TrailFadeSeconds = 0.6,
	ChargeLighten = 0.45,
	TintSaturation = 0.3,
	BlastShake = { Degrees = 1.2, Seconds = 0.4, Frequency = 18 },
	LandShake = { Degrees = 0.6, Seconds = 0.25, Frequency = 20 },
	Effects = {
		Fuse = "VFX_Cannon_Fuse",
		Charge = "VFX_Cannon_Charge",
		Blast = "VFX_Cannon_Blast",
		Trail = "VFX_Cannon_Trail",
		Land = "VFX_Cannon_Land",
		Equip = "VFX_Cannon_Equip",
	},
	Sounds = {
		Fuse = "SFX_Cannon_Fuse",
		Boom = "SFX_Cannon_Boom",
		Whoosh = "SFX_Cannon_Whoosh",
		Land = "SFX_Cannon_Land",
		Equip = "SFX_Cannon_Equip",
	},
	Shop = {
		Outline = Color3.fromRGB(0, 0, 0),
		EquippedOutline = Color3.fromRGB(0, 255, 60),
		FireButton = {
			Edge = Color3.fromRGB(225, 0, 0),
			Center = Color3.fromRGB(255, 110, 90),
			Studs = Color3.fromRGB(150, 0, 0),
		},
	},
	Cannons = {
		{
			Key = "Desert",
			DisplayName = "Desert Cannon",
			ZoneName = "Desert",
			ZoneNumber = 2,
			Price = 80000,
			StrengthRequired = 500,
			Color = Color3.fromRGB(255, 170, 0),
			Marker = "CannonDesert",
		},
		{
			Key = "Jungle",
			DisplayName = "Jungle Cannon",
			ZoneName = "Jungle",
			ZoneNumber = 3,
			Price = 5100000,
			StrengthRequired = 62500,
			Color = Color3.fromRGB(0, 210, 40),
			Marker = "CannonJungle",
		},
		{
			Key = "Ocean",
			DisplayName = "Ocean Cannon",
			ZoneName = "Ocean",
			ZoneNumber = 4,
			Price = 328000000,
			StrengthRequired = 7812500,
			Color = Color3.fromRGB(0, 90, 255),
			Marker = "CannonOcean",
		},
		{
			Key = "Snow",
			DisplayName = "Snow Cannon",
			ZoneName = "Snow",
			ZoneNumber = 5,
			Price = 21000000000,
			StrengthRequired = 976562500,
			Color = Color3.fromRGB(140, 220, 255),
			Marker = "CannonSnow",
		},
	},
}

return table.freeze(CannonConfig)
