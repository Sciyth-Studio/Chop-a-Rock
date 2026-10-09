--!strict

local ArmConfig = require(script.Parent.ArmConfig)
local ShopConfig = require(script.Parent.ShopConfig)

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
	Level: number?,
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
	Level: number,
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

local AdminConfig: AdminSettings = {
	UserIds = {},
	AttributeName = "IsAdmin",
	AutoPresetAttribute = "AdminAutoPreset",
	WarpModelName = "AdminWarps",
	WarpLabelAttribute = "Label",
	WarpOrderAttribute = "Order",
	WarpLiftStuds = 3,
	BaseWarpLabel = "My Base",
	BaseSpawnName = "BaseSpawn",
	WalkSpeedSource = "Admin",
	Tabs = { "Presets", "Move", "Stats", "Roks", "Chop", "Debug" },
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
		{ Id = "SetLevel", Label = "Set Level", Tab = "Stats", Kind = "Number", Default = "12" },
		{ Id = "SetStrength", Label = "Set Strength", Tab = "Stats", Kind = "Number", Default = "500" },
		{ Id = "SetRebirths", Label = "Set Rebirths", Tab = "Stats", Kind = "Number", Default = "1" },
		{ Id = "SetArmTier", Label = "Set Arms", Tab = "Stats", Kind = "Choice", Choices = armChoices },
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
			Id = "SpawnSpots",
			Label = "Spawn Spots",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.K,
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
			Level = 11,
			ArmTier = 2,
			Pets = { "Bloky", "Sprout" },
		},
		{
			Id = "RebirthReady",
			Label = "Rebirth Ready",
			Cash = 5000,
			Level = 12,
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
		Level = 200,
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
