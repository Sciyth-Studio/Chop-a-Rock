--!strict

export type HudSettings = {
	BackdropName: string,
	BackdropPaddingPixels: number,
	BackdropScreenBleedPixels: number,
	BackdropMinWidthPixels: number,
	InviteButtonName: string,
	InviteGapPixels: number,
	InviteExtraPaddingPixels: number,
	ShadowSuffix: string,
	ContainerName: string,
	TouchDockScreenName: string,
	TouchDockFrameName: string,
	TouchDockGapPixels: number,
}

local HudConfig: HudSettings = {
	BackdropName = "Backdrop",
	BackdropPaddingPixels = 70,
	BackdropScreenBleedPixels = 16,
	BackdropMinWidthPixels = 260,
	InviteButtonName = "InviteButton",
	InviteGapPixels = 18,
	InviteExtraPaddingPixels = 90,
	ShadowSuffix = "Shadow",
	ContainerName = "Container",
	TouchDockScreenName = "MenuButtons",
	TouchDockFrameName = "Container",
	TouchDockGapPixels = 10,
}

return table.freeze(HudConfig)
