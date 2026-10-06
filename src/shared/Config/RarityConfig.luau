--!strict

export type Rarity = {
	DisplayName: string,
	Color: Color3,
	IsLucky: boolean,
	Announce: boolean,
	HiddenUntilFound: boolean,
	RainbowLabel: boolean,
	SoundKey: string,
}

export type RaritySettings = {
	Order: { string },
	Rainbow: ColorSequence,
	Rarities: { [string]: Rarity },
}

local RarityConfig: RaritySettings = {
	Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret" },
	Rainbow = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 0)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 230, 60)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 140, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 0, 255)),
	}),
	Rarities = {
		Common = {
			DisplayName = "Common",
			Color = Color3.fromRGB(170, 170, 170),
			IsLucky = false,
			Announce = false,
			HiddenUntilFound = false,
			RainbowLabel = false,
			SoundKey = "SFX_Hatch_Common",
		},
		Uncommon = {
			DisplayName = "Uncommon",
			Color = Color3.fromRGB(0, 220, 60),
			IsLucky = false,
			Announce = false,
			HiddenUntilFound = false,
			RainbowLabel = false,
			SoundKey = "SFX_Hatch_Uncommon",
		},
		Rare = {
			DisplayName = "Rare",
			Color = Color3.fromRGB(0, 140, 255),
			IsLucky = true,
			Announce = false,
			HiddenUntilFound = false,
			RainbowLabel = false,
			SoundKey = "SFX_Hatch_Rare",
		},
		Epic = {
			DisplayName = "Epic",
			Color = Color3.fromRGB(170, 0, 255),
			IsLucky = true,
			Announce = false,
			HiddenUntilFound = false,
			RainbowLabel = false,
			SoundKey = "SFX_Hatch_Epic",
		},
		Legendary = {
			DisplayName = "Legendary",
			Color = Color3.fromRGB(255, 180, 0),
			IsLucky = true,
			Announce = false,
			HiddenUntilFound = false,
			RainbowLabel = false,
			SoundKey = "SFX_Hatch_Legendary",
		},
		Secret = {
			DisplayName = "Secret",
			Color = Color3.fromRGB(255, 0, 150),
			IsLucky = true,
			Announce = true,
			HiddenUntilFound = true,
			RainbowLabel = true,
			SoundKey = "SFX_Hatch_Secret",
		},
	},
}

return table.freeze(RarityConfig)
