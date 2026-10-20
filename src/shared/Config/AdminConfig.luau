--!strict

local AuraConfig = require(script.Parent.AuraConfig)
local GeodeConfig = require(script.Parent.GeodeConfig)
local GeodeOrder = require(script.Parent.Parent.Utils.GeodeOrder)
local HotStreakConfig = require(script.Parent.HotStreakConfig)
local IndexConfig = require(script.Parent.IndexConfig)
local PetConfig = require(script.Parent.PetConfig)
local RarityConfig = require(script.Parent.RarityConfig)
local RockConfig = require(script.Parent.RockConfig)
local ShopConfig = require(script.Parent.ShopConfig)
local WeatherConfig = require(script.Parent.WeatherConfig)

export type Kind = "Button" | "Number" | "Choice" | "Text"

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
	Placeholder: string?,
	Choices: { Choice }?,
	Shortcut: Enum.KeyCode?,
	Alias: string?,
}

export type CommandBarExtra = {
	Alias: string,
	Id: string,
}

export type Preset = {
	Id: string,
	Label: string,
	Cash: number?,
	Strength: number?,
	Rebirths: number?,
	AuraTier: number?,
	PedestalSlots: number?,
	Geodes: { [string]: number }?,
	Pets: { string }?,
	CompleteIndex: boolean?,
}

export type Limits = {
	Cash: number,
	Strength: number,
	WalkSpeed: number,
	OfflineHours: number,
	GeodeGrant: number,
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
	GeodeGrantAmount: number,
	ResetConfirmSeconds: number,
	IndexAllValue: string,
	IndexSeparator: string,
	NoTraitValue: string,
	Snapshots: {
		StoreName: string,
		MaxPerPlayer: number,
		MaxNameLength: number,
	},
	CommandBar: {
		Key: Enum.KeyCode,
		ScreenName: string,
		MaxHints: number,
		Extras: { CommandBarExtra },
	},
	TopbarLabel: string,
	Palette: {
		Command: ShopConfig.MeterColors,
		Preset: ShopConfig.MeterColors,
		Warp: ShopConfig.MeterColors,
		TabActive: ShopConfig.MeterColors,
		TabIdle: ShopConfig.MeterColors,
	},
}

local auraChoices: { Choice } = {}
for index, tier in AuraConfig.Tiers do
	table.insert(auraChoices, { Value = tostring(index), Label = tier.DisplayName })
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

local rokChoices: { Choice } = {}
local rockChoices: { Choice } = {}
local indexChoices: { Choice } = { { Value = "All", Label = "All" } }
for _, page in IndexConfig.Pages do
	for _, zone in page.Zones do
		table.insert(
			indexChoices,
			{ Value = `{page.Key}/{zone.Key}`, Label = `{page.DisplayName}: {zone.DisplayName}` }
		)
		for _, key in zone.Entries do
			local pet = PetConfig.Pets[key]
			local rock = (RockConfig.Rocks :: any)[key]
			if page.Kind == "Pets" and pet then
				table.insert(rokChoices, { Value = key, Label = `{pet.DisplayName} ({pet.Rarity})` })
			elseif page.Kind == "Rocks" and rock then
				table.insert(rockChoices, { Value = key, Label = `{zone.DisplayName}: {rock.DisplayName}` })
			end
		end
	end
end

local traitChoices: { Choice } = { { Value = "None", Label = "No Trait" } }
local traitKeys: { string } = {}
for key in PetConfig.Traits do
	table.insert(traitKeys, key)
end
table.sort(traitKeys)
for _, key in traitKeys do
	table.insert(traitChoices, { Value = key, Label = PetConfig.Traits[key].DisplayName })
end

local geodeChoices: { Choice } = {}
for _, key in GeodeOrder.Sorted() do
	table.insert(geodeChoices, { Value = key, Label = GeodeConfig.Geodes[key].DisplayName })
end

local rarityChoices: { Choice } = {}
for _, key in RarityConfig.Order do
	table.insert(rarityChoices, { Value = key, Label = RarityConfig.Rarities[key].DisplayName })
end

local qualityChoices: { Choice } = {}
for _, key in { "Perfect", "Great", "Good", "Mid", "Bad" } do
	table.insert(qualityChoices, { Value = key, Label = key })
end

local streakChoices: { Choice } = { { Value = "0", Label = "Off" } }
for index, tier in HotStreakConfig.Tiers do
	table.insert(streakChoices, { Value = tostring(index), Label = `Tier {index} (x{tier.Multiplier})` })
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
	Tabs = { "Presets", "Move", "Stats", "Roks", "Index", "Chop", "Weather", "Debug" },
	PresetTab = "Presets",
	WarpTab = "Move",
	Commands = {
		{
			Id = "SetWalkSpeed",
			Label = "Set Walk Speed",
			Tab = "Move",
			Kind = "Number",
			Default = "60",
			Alias = "speed",
		},
		{
			Id = "SetCash",
			Label = "Set Cash",
			Tab = "Stats",
			Kind = "Number",
			Default = "1m",
			Alias = "cash",
		},
		{
			Id = "GrantCash",
			Label = "+1,000 Cash",
			Tab = "Stats",
			Kind = "Button",
			Shortcut = Enum.KeyCode.C,
			Alias = "addcash",
		},
		{
			Id = "SetStrength",
			Label = "Set Strength",
			Tab = "Stats",
			Kind = "Number",
			Default = "100",
			Alias = "strength",
		},
		{
			Id = "SetRebirths",
			Label = "Set Rebirths",
			Tab = "Stats",
			Kind = "Number",
			Default = "1",
			Alias = "rebirths",
		},
		{
			Id = "SetAuraTier",
			Label = "Set Aura",
			Tab = "Stats",
			Kind = "Choice",
			Choices = auraChoices,
			Alias = "aura",
		},
		{
			Id = "GrantCannons",
			Label = "Grant All Cannons",
			Tab = "Stats",
			Kind = "Button",
			Alias = "cannons",
		},
		{
			Id = "ResetCannons",
			Label = "Reset Cannons",
			Tab = "Stats",
			Kind = "Button",
			Alias = "nocannons",
		},
		{
			Id = "SetTrainingTier",
			Label = "Set Training Tier",
			Tab = "Stats",
			Kind = "Number",
			Default = "1",
			Alias = "training",
		},
		{
			Id = "SetPedestalSlots",
			Label = "Set Slots",
			Tab = "Stats",
			Kind = "Number",
			Default = "8",
			Alias = "slots",
		},
		{
			Id = "SimulateOffline",
			Label = "Simulate Offline Hours",
			Tab = "Stats",
			Kind = "Number",
			Default = "2",
			Alias = "offline",
		},
		{
			Id = "GrantRok",
			Label = "Grant Rok",
			Tab = "Roks",
			Kind = "Choice",
			Choices = rokChoices,
			Alias = "rok",
		},
		{
			Id = "GrantPet",
			Label = "Grant Random Rok",
			Tab = "Roks",
			Kind = "Button",
			Shortcut = Enum.KeyCode.P,
			Alias = "randomrok",
		},
		{
			Id = "SetRokTrait",
			Label = "Rok: Set Trait",
			Tab = "Roks",
			Kind = "Choice",
			Choices = traitChoices,
			Alias = "trait",
		},
		{
			Id = "GrantGeode",
			Label = "+1 Geode",
			Tab = "Roks",
			Kind = "Button",
			Shortcut = Enum.KeyCode.G,
			Alias = "geode",
		},
		{
			Id = "GrantGeodes",
			Label = "+10 Geodes",
			Tab = "Roks",
			Kind = "Choice",
			Choices = geodeChoices,
			Alias = "geodes",
		},
		{
			Id = "ForceSecret",
			Label = "Next Hatch: Secret",
			Tab = "Roks",
			Kind = "Button",
			Shortcut = Enum.KeyCode.H,
			Alias = "secret",
		},
		{
			Id = "ForceRarity",
			Label = "Next Hatch",
			Tab = "Roks",
			Kind = "Choice",
			Choices = rarityChoices,
			Alias = "rarity",
		},
		{ Id = "FillBackpack", Label = "Fill Backpack", Tab = "Roks", Kind = "Button", Alias = "fill" },
		{ Id = "ClearBackpack", Label = "Clear Backpack", Tab = "Roks", Kind = "Button", Alias = "clear" },
		{
			Id = "FillPedestals",
			Label = "Fill All Pedestals",
			Tab = "Roks",
			Kind = "Button",
			Alias = "pedestals",
		},
		{
			Id = "IndexComplete",
			Label = "Index: Complete",
			Tab = "Index",
			Kind = "Choice",
			Choices = indexChoices,
			Alias = "index",
		},
		{
			Id = "IndexReset",
			Label = "Index: Reset",
			Tab = "Index",
			Kind = "Choice",
			Choices = indexChoices,
			Alias = "unindex",
		},
		{
			Id = "IndexClaimAll",
			Label = "Index: Claim All",
			Tab = "Index",
			Kind = "Button",
			Alias = "claimall",
		},
		{
			Id = "ForceMaster",
			Label = "Next Chop: Master",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.M,
			Alias = "master",
		},
		{
			Id = "ForceQuality",
			Label = "Next Chop",
			Tab = "Chop",
			Kind = "Choice",
			Choices = qualityChoices,
			Alias = "quality",
		},
		{
			Id = "CheatAlwaysPerfect",
			Label = "Toggle Always Perfect",
			Tab = "Chop",
			Kind = "Button",
			Alias = "perfect",
		},
		{
			Id = "CheatOneHit",
			Label = "Toggle One-Hit Break",
			Tab = "Chop",
			Kind = "Button",
			Alias = "onehit",
		},
		{
			Id = "CheatIgnoreStrength",
			Label = "Toggle Ignore Strength",
			Tab = "Chop",
			Kind = "Button",
			Alias = "strong",
		},
		{
			Id = "CheatInstantRespawn",
			Label = "Toggle Instant Respawn",
			Tab = "Chop",
			Kind = "Button",
			Alias = "respawn",
		},
		{
			Id = "SpawnRock",
			Label = "Spawn Rock",
			Tab = "Chop",
			Kind = "Choice",
			Choices = rockChoices,
			Alias = "rock",
		},
		{
			Id = "ForceRush",
			Label = "Next Rock: Rush",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.R,
			Alias = "rush",
		},
		{
			Id = "SetStreakTier",
			Label = "Set Hot Streak",
			Tab = "Chop",
			Kind = "Choice",
			Choices = streakChoices,
			Alias = "streak",
		},
		{
			Id = "FreezeStreak",
			Label = "Toggle Streak Freeze",
			Tab = "Chop",
			Kind = "Button",
			Alias = "freeze",
		},
		{
			Id = "SpawnDiamond",
			Label = "Spawn Diamond Rock",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.D,
			Alias = "diamond",
		},
		{
			Id = "DiamondTimeLeft",
			Label = "Diamond: 10s Left",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.T,
			Alias = "diamondend",
		},
		{
			Id = "SpawnSpots",
			Label = "Spawn Spots",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.K,
			Alias = "spots",
		},
		{
			Id = "WeatherStart",
			Label = "Weather: Start",
			Tab = "Weather",
			Kind = "Choice",
			Choices = weatherChoices,
			Alias = "weather",
		},
		{ Id = "WeatherEnd", Label = "Weather: End", Tab = "Weather", Kind = "Button", Alias = "weatherend" },
		{
			Id = "WeatherNext",
			Label = "Weather: Next in 10s",
			Tab = "Weather",
			Kind = "Button",
			Shortcut = Enum.KeyCode.N,
			Alias = "weathernext",
		},
		{
			Id = "GiveModifier",
			Label = "Rok: Give Modifier",
			Tab = "Weather",
			Kind = "Choice",
			Choices = modifierChoices,
			Alias = "modifier",
		},
		{
			Id = "ResetData",
			Label = "Reset My Data",
			Tab = "Debug",
			Kind = "Button",
			Shortcut = Enum.KeyCode.Backspace,
			Alias = "resetme",
		},
		{
			Id = "ResetPlayerData",
			Label = "Reset Player Data",
			Tab = "Debug",
			Kind = "Text",
			Default = "",
			Placeholder = "Name or UserId, in game or not",
			Alias = "reset",
		},
		{
			Id = "SaveSnapshot",
			Label = "Save Snapshot",
			Tab = "Debug",
			Kind = "Text",
			Default = "",
			Placeholder = "Snapshot name",
			Alias = "save",
		},
		{
			Id = "LoadSnapshot",
			Label = "Load Snapshot",
			Tab = "Debug",
			Kind = "Text",
			Default = "",
			Placeholder = "Snapshot name",
			Alias = "load",
		},
		{
			Id = "DeleteSnapshot",
			Label = "Delete Snapshot",
			Tab = "Debug",
			Kind = "Text",
			Default = "",
			Placeholder = "Snapshot name",
			Alias = "delsnap",
		},
		{
			Id = "ListSnapshots",
			Label = "List Snapshots",
			Tab = "Debug",
			Kind = "Button",
			Alias = "snapshots",
		},
	},
	Presets = {
		{ Id = "Fresh", Label = "Fresh Start" },
		{
			Id = "PreRebirth",
			Label = "Pre-Rebirth",
			Cash = 2400,
			Strength = 90,
			AuraTier = 2,
			Pets = { "Bloky", "Sprout" },
		},
		{
			Id = "RebirthReady",
			Label = "Rebirth Ready",
			Cash = 5000,
			Strength = 100,
			AuraTier = 3,
			Pets = { "Bloky", "Sprout", "Shroomy" },
		},
		{
			Id = "Desert",
			Label = "Desert",
			Cash = 20000,
			Strength = 500,
			Rebirths = 1,
			AuraTier = 3,
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
			AuraTier = 5,
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
		OfflineHours = 48,
		GeodeGrant = 1e6,
	},
	ShortcutModifiers = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },
	CashAmount = 1000,
	GeodeGrantAmount = 10,
	ResetConfirmSeconds = 5,
	IndexAllValue = "All",
	IndexSeparator = "/",
	NoTraitValue = "None",
	Snapshots = {
		StoreName = "AdminSnapshots",
		MaxPerPlayer = 20,
		MaxNameLength = 20,
	},
	CommandBar = {
		Key = Enum.KeyCode.Space,
		ScreenName = "AdminCommandBar",
		MaxHints = 6,
		Extras = {
			{ Alias = "preset", Id = "ApplyPreset" },
			{ Alias = "warp", Id = "Warp" },
		},
	},
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
