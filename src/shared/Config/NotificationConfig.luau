--!strict

local WeatherConfig = require(script.Parent.WeatherConfig)

export type NotificationSettings = {
	Kinds: { [string]: boolean },
	KindStyles: { [string]: string },
	FallbackKind: string,
	SoundKey: string,
	MaxVisible: number,
	FadeInSeconds: number,
	HoldSeconds: number,
	FadeOutSeconds: number,
	RepeatSuffix: string,
	PinnedLayoutOrder: number,
	PinPopFromScale: number,
	PinPopSeconds: number,
}

local NotificationConfig: NotificationSettings = {
	Kinds = {
		Info = true,
		Purchase = true,
		Unlock = true,
		Event = true,
		Modifier = true,
		Error = true,
		Tutorial = true,
		Pass = true,
	},
	KindStyles = {
		Pass = "Gold",
	},
	FallbackKind = "Info",
	SoundKey = "SFX_Notification",
	MaxVisible = 4,
	FadeInSeconds = 0.15,
	HoldSeconds = 2.5,
	FadeOutSeconds = 0.6,
	RepeatSuffix = " x",
	PinnedLayoutOrder = -1000,
	PinPopFromScale = 0.9,
	PinPopSeconds = 0.25,
}

for key in WeatherConfig.Modifiers do
	NotificationConfig.Kinds[WeatherConfig.NoticeKindPrefix .. key] = true
end

return table.freeze(NotificationConfig)
