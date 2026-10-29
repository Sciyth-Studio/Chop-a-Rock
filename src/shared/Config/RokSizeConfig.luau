--!strict

export type Size = {
	DisplayName: string,
	Weight: number,
	Scale: number,
	TextStyle: string,
}

export type RokSizeSettings = {
	Order: { string },
	Sizes: { [string]: Size },
	DefaultKey: string,
	MaxBigShare: number,
	Attribute: string,
	InfoLiftStudsPerScale: number,
}

local RokSizeConfig: RokSizeSettings = {
	Order = { "Normal", "Large", "Huge", "Giant", "Enormous" },
	Sizes = {
		Normal = { DisplayName = "Normal", Weight = 70, Scale = 1, TextStyle = "Chrome" },
		Large = { DisplayName = "Large", Weight = 20, Scale = 1.2, TextStyle = "Green" },
		Huge = { DisplayName = "Huge", Weight = 7, Scale = 1.4, TextStyle = "Sky" },
		Giant = { DisplayName = "Giant", Weight = 2.5, Scale = 1.65, TextStyle = "Orange" },
		Enormous = { DisplayName = "Enormous", Weight = 0.5, Scale = 2, TextStyle = "Gold" },
	},
	DefaultKey = "Normal",
	MaxBigShare = 0.75,
	Attribute = "Size",
	InfoLiftStudsPerScale = 4.5,
}

return table.freeze(RokSizeConfig)
