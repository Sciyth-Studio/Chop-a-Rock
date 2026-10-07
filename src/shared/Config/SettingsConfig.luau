--!strict

export type SettingsSettings = {
	Toggles: { string },
	Sliders: { string },
	SoundToggles: { string },
	MasterVolume: string,
	MaxVolumePercent: number,
	VolumeStepPercent: number,
	LowGraphicsAttribute: string,
	LowGraphicsEmitScale: number,
	TopbarImage: string,
	TopbarCaption: string,
}

local SettingsConfig: SettingsSettings = {
	Toggles = { "Music", "SoundEffects", "LowGraphics", "Notifications", "AutoEquip" },
	Sliders = { "Volume" },
	SoundToggles = { "Music", "SoundEffects" },
	MasterVolume = "Volume",
	MaxVolumePercent = 100,
	VolumeStepPercent = 10,
	LowGraphicsAttribute = "LowGraphics",
	LowGraphicsEmitScale = 0.4,
	TopbarImage = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
	TopbarCaption = "Settings",
}

return table.freeze(SettingsConfig)
