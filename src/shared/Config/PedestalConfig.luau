--!strict

export type PedestalSettings = {
	StartingSlots: number,
	UnlockOrder: { number },
	SlotPrices: { [number]: number },
	OfflineRateMultiplier: number,
	FlushSeconds: number,
	PetScale: number,
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
	StartingSlots = 8,
	UnlockOrder = { 1, 5, 2, 6, 3, 7, 4, 8 },
	SlotPrices = {},
	OfflineRateMultiplier = 0.125,
	FlushSeconds = 15,
	PetScale = 2,
	PromptHoldSeconds = 0.5,
	PromptRangeStuds = 10,
	CollectCooldownSeconds = 1,
	PedestalTag = "Pedestal",
	FolderName = "Pedestals",
	PedestalPartName = "Pedestal",
	PadPartName = "EarningsPad",
	DisplayName = "PlacedPet",
	PadTemplateKey = "UI_PedestalPad",
	InfoTemplateKey = "UI_PedestalInfo",
	IncomeTickSeconds = 1,
	InfoHeightStuds = 8,
	LabelMaxDistance = 80,
}

return table.freeze(PedestalConfig)
