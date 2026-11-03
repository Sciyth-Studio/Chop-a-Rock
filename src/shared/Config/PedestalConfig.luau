--!strict

export type PedestalSettings = {
	StartingSlots: number,
	UnlockOrder: { number },
	SlotPrices: { [number]: number },
	OfflineRateMultiplier: number,
	PetScale: number,
	PedestalPartName: string,
	DisplayName: string,
	InfoTemplateKey: string,
	IncomeTickSeconds: number,
	IncomeLogSeconds: number,
	InfoHeightStuds: number,
	LabelMaxDistance: number,
	PenPartName: string,
	PenFolderName: string,
	PenPetTag: string,
	PenMarginStuds: number,
	HopCenterAttribute: string,
	HopHalfSizeAttribute: string,
}

local PedestalConfig: PedestalSettings = {
	StartingSlots = 8,
	UnlockOrder = { 1, 5, 2, 6, 3, 7, 4, 8 },
	SlotPrices = {},
	OfflineRateMultiplier = 0.04,
	PetScale = 2,
	PedestalPartName = "Pedestal",
	DisplayName = "PlacedPet",
	InfoTemplateKey = "UI_PedestalInfo",
	IncomeTickSeconds = 1,
	IncomeLogSeconds = 30,
	InfoHeightStuds = 8,
	LabelMaxDistance = 80,
	PenPartName = "BasePlot_Pen",
	PenFolderName = "PenPets",
	PenPetTag = "PenPet",
	PenMarginStuds = 6,
	HopCenterAttribute = "HopCenter",
	HopHalfSizeAttribute = "HopHalfSize",
}

return table.freeze(PedestalConfig)
