--!strict

export type HudSettings = {
	BackdropName: string,
	BackdropPaddingPixels: number,
	BackdropScreenBleedPixels: number,
	ShadowSuffix: string,
}

local HudConfig: HudSettings = {
	BackdropName = "Backdrop",
	BackdropPaddingPixels = 70,
	BackdropScreenBleedPixels = 16,
	ShadowSuffix = "Shadow",
}

return table.freeze(HudConfig)
