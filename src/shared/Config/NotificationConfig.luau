--!strict

local WeatherConfig = require(script.Parent.WeatherConfig)

export type NotificationSettings = {
	Kinds: { [string]: boolean },
	FallbackKind: string,
	SoundKey: string,
	MaxVisible: number,
	FadeInSeconds: number,
	HoldSeconds: number,
	FadeOutSeconds: number,
	RepeatSuffix: string,
}

local NotificationConfig: NotificationSettings = {
	Kinds = {
		Info = true,
		Purchase = true,
		Unlock = true,
		Event = true,
		Modifier = true,
		Error = true,
	},
	FallbackKind = "Info",
	SoundKey = "SFX_Notification",
	MaxVisible = 4,
	FadeInSeconds = 0.15,
	HoldSeconds = 2.5,
	FadeOutSeconds = 0.6,
	RepeatSuffix = " x",
}

for key in WeatherConfig.Modifiers do
	NotificationConfig.Kinds[WeatherConfig.NoticeKindPrefix .. key] = true
end

return table.freeze(NotificationConfig)
