--!strict

export type Pack = {
	Key: string,
	DisplayName: string,
	ProductId: number,
	RobuxPrice: number,
	Geodes: number,
}

export type CashPackSettings = {
	Packs: { Pack },
	BoughtKind: string,
	BoughtFormat: string,
	BoughtSound: string,
}

local CashPackConfig: CashPackSettings = {
	Packs = {
		{ Key = "Small", DisplayName = "Small", ProductId = 3720804848, RobuxPrice = 25, Geodes = 3 },
		{ Key = "Medium", DisplayName = "Medium", ProductId = 3720804851, RobuxPrice = 79, Geodes = 12 },
		{ Key = "Large", DisplayName = "Large", ProductId = 3720804855, RobuxPrice = 199, Geodes = 40 },
		{ Key = "Huge", DisplayName = "Huge", ProductId = 3720804860, RobuxPrice = 499, Geodes = 150 },
	},
	BoughtKind = "Purchase",
	BoughtFormat = "+$%s cash!",
	BoughtSound = "SFX_Money_Gain",
}

return table.freeze(CashPackConfig)
