--!strict

export type SettingsSettings = {
	Toggles: { string },
	TopbarImage: string,
	TopbarCaption: string,
}

local SettingsConfig: SettingsSettings = {
	Toggles = { "Music", "SoundEffects" },
	TopbarImage = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
	TopbarCaption = "Settings",
}

return table.freeze(SettingsConfig)
