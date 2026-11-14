--!strict

export type CountsWhile = "Always" | "Training" | "InZone" | "Hatching" | "Chopping"

export type Potion = {
	Key: string,
	DisplayName: string,
	Effect: string,
	Color: Color3,
	Icon: string,
	CountsWhile: CountsWhile,
	TextStyle: string,
	PillText: string,
	Order: number,
}

local potions: { [string]: Potion } = {
	Luck = {
		Key = "Luck",
		DisplayName = "Luck Potion",
		Effect = "x2 egg luck",
		Color = Color3.fromRGB(40, 200, 40),
		Icon = "rbxassetid://136122184424656",
		CountsWhile = "InZone",
		TextStyle = "Green",
		PillText = "Luck Potion",
		Order = 1,
	},
	Strength = {
		Key = "Strength",
		DisplayName = "Strength Potion",
		Effect = "x2 training",
		Color = Color3.fromRGB(235, 30, 30),
		Icon = "rbxassetid://76548713469285",
		CountsWhile = "Training",
		TextStyle = "Strength",
		PillText = "Strength Potion",
		Order = 2,
	},
	Hatch = {
		Key = "Hatch",
		DisplayName = "Hatch Potion",
		Effect = "Eggs hatch x2 faster",
		Color = Color3.fromRGB(255, 200, 0),
		Icon = "rbxassetid://102090116512531",
		CountsWhile = "Hatching",
		TextStyle = "Gold",
		PillText = "Hatch Potion",
		Order = 3,
	},
	Speed = {
		Key = "Speed",
		DisplayName = "Speed Potion",
		Effect = "+8 walk speed",
		Color = Color3.fromRGB(0, 140, 255),
		Icon = "rbxassetid://78675091475510",
		CountsWhile = "Always",
		TextStyle = "Sky",
		PillText = "Speed Potion",
		Order = 4,
	},
	Focus = {
		Key = "Focus",
		DisplayName = "Focus Potion",
		Effect = "Bigger Perfect zone",
		Color = Color3.fromRGB(170, 40, 255),
		Icon = "rbxassetid://130676061399927",
		CountsWhile = "Chopping",
		TextStyle = "Purple",
		PillText = "Focus Potion",
		Order = 5,
	},
}

local PotionConfig = {
	Potions = table.freeze(potions),
	Seconds = 600,
	BoostPrefix = "Potion",
	MaxCount = 999,
	StrengthBonus = 1,
	LuckMultiplier = 2,
	HatchSpeed = 2,
	SpeedBonus = 8,
	SpeedSource = "Potion",
	FocusScale = 1.5,
	FocusMaxPerfectShare = 0.17,
	BossWinCount = 1,
	BossAlmostChance = 0.25,
	DrinkText = "Drink!",
	GotFormat = "+%d %s!",
	DrankFormat = "%s: %s for 10 min!",
	FullText = "That potion is already maxed out!",
}

function PotionConfig.BoostKey(potionKey: string): string
	return PotionConfig.BoostPrefix .. potionKey
end

function PotionConfig.FromBoostKey(boostKey: string): Potion?
	if string.sub(boostKey, 1, #PotionConfig.BoostPrefix) ~= PotionConfig.BoostPrefix then
		return nil
	end
	return potions[string.sub(boostKey, #PotionConfig.BoostPrefix + 1)]
end

function PotionConfig.Sorted(): { Potion }
	local list: { Potion } = {}
	for _, potion in potions do
		table.insert(list, potion)
	end
	table.sort(list, function(a: Potion, b: Potion)
		return a.Order < b.Order
	end)
	return list
end

return table.freeze(PotionConfig)
