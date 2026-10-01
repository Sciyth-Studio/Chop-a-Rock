--!strict

export type HudSettings = {
	BackdropName: string,
	BackdropPaddingPixels: number,
	BackdropScreenBleedPixels: number,
	BackdropMinWidthPixels: number,
	ShadowSuffix: string,
}

local HudConfig: HudSettings = {
	BackdropName = "Backdrop",
	BackdropPaddingPixels = 70,
	BackdropScreenBleedPixels = 16,
	BackdropMinWidthPixels = 260,
	ShadowSuffix = "Shadow",
}

return table.freeze(HudConfig)
