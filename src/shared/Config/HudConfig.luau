--!strict

export type StrengthPopSettings = {
	IconName: string,
	IconCount: number,
	IconSizePixels: number,
	OriginHeightStuds: number,
	BurstPixels: number,
	BurstSeconds: number,
	StaggerSeconds: number,
	FlySeconds: number,
	BumpScale: number,
	BumpSeconds: number,
	ZIndex: number,
	TextStyle: string,
	TextGapPixels: number,
	TextRisePixels: number,
	TextSeconds: number,
}

export type HudSettings = {
	BackdropName: string,
	BackdropPaddingPixels: number,
	BackdropScreenBleedPixels: number,
	BackdropMinWidthPixels: number,
	InviteButtonName: string,
	InviteGapPixels: number,
	InviteExtraPaddingPixels: number,
	ShadowSuffix: string,
	StrengthPop: StrengthPopSettings,
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
	StrengthPop = {
		IconName = "Icon",
		IconCount = 3,
		IconSizePixels = 192,
		OriginHeightStuds = 2,
		BurstPixels = 180,
		BurstSeconds = 0.25,
		StaggerSeconds = 0.06,
		FlySeconds = 0.4,
		BumpScale = 1.25,
		BumpSeconds = 0.2,
		ZIndex = 20,
		TextStyle = "Strength",
		TextGapPixels = 14,
		TextRisePixels = 24,
		TextSeconds = 0.8,
	},
}

return table.freeze(HudConfig)
