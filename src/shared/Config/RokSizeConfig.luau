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
	Order = { "Tiny", "Normal", "Big", "Giant", "Huge", "Colossal" },
	Sizes = {
		Tiny = { DisplayName = "Tiny", Weight = 15, Scale = 0.75, TextStyle = "Chrome" },
		Normal = { DisplayName = "Normal", Weight = 55, Scale = 1, TextStyle = "Chrome" },
		Big = { DisplayName = "Big", Weight = 20, Scale = 1.2, TextStyle = "Green" },
		Giant = { DisplayName = "Giant", Weight = 7, Scale = 1.4, TextStyle = "Sky" },
		Huge = { DisplayName = "Huge", Weight = 2.5, Scale = 1.65, TextStyle = "Orange" },
		Colossal = { DisplayName = "Colossal", Weight = 0.5, Scale = 2, TextStyle = "Gold" },
	},
	DefaultKey = "Normal",
	MaxBigShare = 0.75,
	Attribute = "Size",
	InfoLiftStudsPerScale = 4.5,
}

return table.freeze(RokSizeConfig)
