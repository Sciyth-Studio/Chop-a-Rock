--!strict

export type SettingsSettings = {
	Toggles: { string },
	Sliders: { string },
	SoundSliders: { [string]: string },
	MaxVolumePercent: number,
	VolumeStepPercent: number,
	LowGraphicsAttribute: string,
	LowGraphicsEmitScale: number,
	TopbarImage: string,
	TopbarCaption: string,
}

local SettingsConfig: SettingsSettings = {
	Toggles = { "LowGraphics", "Notifications", "AutoEquip" },
	Sliders = { "MusicVolume", "SoundEffectsVolume" },
	SoundSliders = {
		MusicVolume = "Music",
		SoundEffectsVolume = "SoundEffects",
	},
	MaxVolumePercent = 100,
	VolumeStepPercent = 10,
	LowGraphicsAttribute = "LowGraphics",
	LowGraphicsEmitScale = 0.4,
	TopbarImage = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
	TopbarCaption = "Settings",
}

return table.freeze(SettingsConfig)
