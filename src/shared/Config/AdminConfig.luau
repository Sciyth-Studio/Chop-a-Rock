--!strict

local ArmConfig = require(script.Parent.ArmConfig)
local ShopConfig = require(script.Parent.ShopConfig)
local WeatherConfig = require(script.Parent.WeatherConfig)

export type Kind = "Button" | "Number" | "Choice"

export type Choice = {
	Value: string,
	Label: string,
}

export type Command = {
	Id: string,
	Label: string,
	Tab: string,
	Kind: Kind,
	Default: string?,
	Choices: { Choice }?,
	Shortcut: Enum.KeyCode?,
}

export type Preset = {
	Id: string,
	Label: string,
	Cash: number?,
	Strength: number?,
	Rebirths: number?,
	ArmTier: number?,
	PedestalSlots: number?,
	Geodes: { [string]: number }?,
	Pets: { string }?,
	CompleteIndex: boolean?,
}

export type Limits = {
	Cash: number,
	Strength: number,
	WalkSpeed: number,
}

export type AdminSettings = {
	UserIds: { number },
	AttributeName: string,
	AutoPresetAttribute: string,
	WarpModelName: string,
	WarpLabelAttribute: string,
	WarpOrderAttribute: string,
	WarpLiftStuds: number,
	BaseWarpLabel: string,
	BaseSpawnName: string,
	WalkSpeedSource: string,
	Tabs: { string },
	PresetTab: string,
	WarpTab: string,
	Commands: { Command },
	Presets: { Preset },
	Limits: Limits,
	ShortcutModifiers: { Enum.KeyCode },
	CashAmount: number,
	TopbarLabel: string,
	Palette: {
		Command: ShopConfig.MeterColors,
		Preset: ShopConfig.MeterColors,
		Warp: ShopConfig.MeterColors,
		TabActive: ShopConfig.MeterColors,
		TabIdle: ShopConfig.MeterColors,
	},
}

local armChoices: { Choice } = {}
for index, tier in ArmConfig.Tiers do
	table.insert(armChoices, { Value = tostring(index), Label = tier.DisplayName })
end

local weatherChoices: { Choice } = {}
for _, event in WeatherConfig.Events do
	table.insert(weatherChoices, { Value = event.Key, Label = event.DisplayName })
end

local modifierChoices: { Choice } = {}
for _, event in WeatherConfig.Events do
	local modifier = WeatherConfig.Modifiers[event.Modifier]
	table.insert(modifierChoices, { Value = event.Modifier, Label = modifier.DisplayName })
end

local AdminConfig: AdminSettings = {
	UserIds = { 467512659, 169380679 },
	AttributeName = "IsAdmin",
	AutoPresetAttribute = "AdminAutoPreset",
	WarpModelName = "AdminWarps",
	WarpLabelAttribute = "Label",
	WarpOrderAttribute = "Order",
	WarpLiftStuds = 3,
	BaseWarpLabel = "My Base",
	BaseSpawnName = "BaseSpawn",
	WalkSpeedSource = "Admin",
	Tabs = { "Presets", "Move", "Stats", "Roks", "Chop", "Weather", "Debug" },
	PresetTab = "Presets",
	WarpTab = "Move",
	Commands = {
		{ Id = "SetWalkSpeed", Label = "Set Walk Speed", Tab = "Move", Kind = "Number", Default = "60" },
		{ Id = "SetCash", Label = "Set Cash", Tab = "Stats", Kind = "Number", Default = "1m" },
		{
			Id = "GrantCash",
			Label = "+1,000 Cash",
			Tab = "Stats",
			Kind = "Button",
			Shortcut = Enum.KeyCode.C,
		},
		{ Id = "SetStrength", Label = "Set Strength", Tab = "Stats", Kind = "Number", Default = "100" },
		{ Id = "SetRebirths", Label = "Set Rebirths", Tab = "Stats", Kind = "Number", Default = "1" },
		{ Id = "SetArmTier", Label = "Set Arms", Tab = "Stats", Kind = "Choice", Choices = armChoices },
		{
			Id = "SetTrainingTier",
			Label = "Set Training Tier",
			Tab = "Stats",
			Kind = "Number",
			Default = "1",
		},
		{ Id = "SetPedestalSlots", Label = "Set Slots", Tab = "Stats", Kind = "Number", Default = "8" },
		{ Id = "GrantPet", Label = "Grant Rok", Tab = "Roks", Kind = "Button", Shortcut = Enum.KeyCode.P },
		{ Id = "GrantGeode", Label = "+1 Geode", Tab = "Roks", Kind = "Button", Shortcut = Enum.KeyCode.G },
		{
			Id = "ForceSecret",
			Label = "Next Hatch: Secret",
			Tab = "Roks",
			Kind = "Button",
			Shortcut = Enum.KeyCode.H,
		},
		{
			Id = "ForceMaster",
			Label = "Next Chop: Master",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.M,
		},
		{
			Id = "ForceRush",
			Label = "Next Rock: Rush",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.R,
		},
		{
			Id = "SpawnDiamond",
			Label = "Spawn Diamond Rock",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.D,
		},
		{
			Id = "DiamondTimeLeft",
			Label = "Diamond: 10s Left",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.T,
		},
		{
			Id = "SpawnSpots",
			Label = "Spawn Spots",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.K,
		},
		{
			Id = "WeatherStart",
			Label = "Weather: Start",
			Tab = "Weather",
			Kind = "Choice",
			Choices = weatherChoices,
		},
		{
			Id = "WeatherEnd",
			Label = "Weather: End",
			Tab = "Weather",
			Kind = "Button",
		},
		{
			Id = "WeatherNext",
			Label = "Weather: Next in 10s",
			Tab = "Weather",
			Kind = "Button",
			Shortcut = Enum.KeyCode.N,
		},
		{
			Id = "GiveModifier",
			Label = "Rok: Give Modifier",
			Tab = "Weather",
			Kind = "Choice",
			Choices = modifierChoices,
		},
		{
			Id = "ResetData",
			Label = "Reset My Data",
			Tab = "Debug",
			Kind = "Button",
			Shortcut = Enum.KeyCode.Backspace,
		},
	},
	Presets = {
		{ Id = "Fresh", Label = "Fresh Start" },
		{
			Id = "PreRebirth",
			Label = "Pre-Rebirth",
			Cash = 2400,
			Strength = 90,
			ArmTier = 2,
			Pets = { "Bloky", "Sprout" },
		},
		{
			Id = "RebirthReady",
			Label = "Rebirth Ready",
			Cash = 5000,
			Strength = 100,
			ArmTier = 3,
			Pets = { "Bloky", "Sprout", "Shroomy" },
		},
		{
			Id = "Desert",
			Label = "Desert",
			Cash = 20000,
			Strength = 500,
			Rebirths = 1,
			ArmTier = 3,
			PedestalSlots = 5,
			Geodes = { Forest = 3 },
			Pets = { "Bloky", "Bloky", "Sprout", "Shroomy", "Nesty" },
		},
		{
			Id = "LateGame",
			Label = "Late Game",
			Cash = 1000000,
			Strength = 12500,
			Rebirths = 1,
			ArmTier = 5,
			PedestalSlots = 8,
			Geodes = { Forest = 10 },
			Pets = { "Bloky", "Sprout", "Shroomy", "Nesty", "Berry", "Treebo", "Berry", "Nesty" },
			CompleteIndex = true,
		},
	},
	Limits = {
		Cash = 1e15,
		Strength = 1e15,
		WalkSpeed = 250,
	},
	ShortcutModifiers = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },
	CashAmount = 1000,
	TopbarLabel = "Admin",
	Palette = {
		Command = ShopConfig.Palette.Grey,
		Preset = ShopConfig.Palette.Green,
		Warp = ShopConfig.Palette.Orange,
		TabActive = {
			Edge = Color3.fromRGB(220, 0, 30),
			Center = Color3.fromRGB(255, 120, 130),
			Studs = Color3.fromRGB(130, 0, 15),
		},
		TabIdle = ShopConfig.Palette.Grey,
	},
}

return table.freeze(AdminConfig)
