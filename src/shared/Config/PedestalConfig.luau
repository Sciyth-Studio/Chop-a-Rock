--!strict

export type PedestalSettings = {
	StartingSlots: number,
	UnlockOrder: { number },
	SlotPrices: { [number]: number },
	OfflineRateMultiplier: number,
	FlushSeconds: number,
	RokScale: number,
	PromptHoldSeconds: number,
	PromptRangeStuds: number,
	CollectCooldownSeconds: number,
	PedestalTag: string,
	FolderName: string,
	PedestalPartName: string,
	PadPartName: string,
	DisplayName: string,
	PadTemplateKey: string,
	InfoTemplateKey: string,
	IncomeTickSeconds: number,
	InfoHeightStuds: number,
	LabelMaxDistance: number,
}

local PedestalConfig: PedestalSettings = {
	StartingSlots = 3,
	UnlockOrder = { 1, 5, 2, 6, 3, 7, 4, 8 },
	SlotPrices = {
		[4] = 1000,
		[5] = 4000,
		[6] = 15000,
		[7] = 60000,
		[8] = 250000,
	},
	OfflineRateMultiplier = 0.125,
	FlushSeconds = 15,
	RokScale = 2,
	PromptHoldSeconds = 0.5,
	PromptRangeStuds = 10,
	CollectCooldownSeconds = 1,
	PedestalTag = "Pedestal",
	FolderName = "Pedestals",
	PedestalPartName = "Pedestal",
	PadPartName = "EarningsPad",
	DisplayName = "PlacedRok",
	PadTemplateKey = "UI_PedestalPad",
	InfoTemplateKey = "UI_PedestalInfo",
	IncomeTickSeconds = 1,
	InfoHeightStuds = 7.5,
	LabelMaxDistance = 80,
}

return table.freeze(PedestalConfig)
