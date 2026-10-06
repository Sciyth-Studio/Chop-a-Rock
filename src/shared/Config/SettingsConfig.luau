--!strict

export type SettingsSettings = {
	Toggles: { string },
	Sliders: { string },
	MaxVolumePercent: number,
	TopbarImage: string,
	TopbarCaption: string,
}

local SettingsConfig: SettingsSettings = {
	Toggles = { "SoundEffects" },
	Sliders = { "Music" },
	MaxVolumePercent = 100,
	TopbarImage = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
	TopbarCaption = "Settings",
}

return table.freeze(SettingsConfig)
