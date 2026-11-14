--!strict

local PromptStatConfig = {
	Colors = {
		Money = Color3.fromRGB(110, 255, 90),
		Time = Color3.fromRGB(255, 255, 255),
		Luck = Color3.fromRGB(255, 210, 40),
	},
	MoneyFormat = "$%s/s",
	FallingEggStat = "Rare+",
	HiddenSizes = { Normal = true },
}

return table.freeze(PromptStatConfig)
