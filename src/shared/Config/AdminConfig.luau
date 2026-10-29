--!strict

local AuraConfig = require(script.Parent.AuraConfig)
local GeodeConfig = require(script.Parent.GeodeConfig)
local GeodeOrder = require(script.Parent.Parent.Utils.GeodeOrder)
local HotStreakConfig = require(script.Parent.HotStreakConfig)
local IndexConfig = require(script.Parent.IndexConfig)
local MonetizationConfig = require(script.Parent.MonetizationConfig)
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
	MaxArgumentLength: number,
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

local passChoices: { Choice } = {}
for _, pass in MonetizationConfig.Passes do
	table.insert(passChoices, { Value = pass.Key, Label = pass.DisplayName })
end

local exclusiveChoices: { Choice } = {}
for _, item in MonetizationConfig.Exclusives.Items do
	table.insert(exclusiveChoices, { Value = item.Key, Label = item.Key })
end

local giftChoices: { Choice } = {}
for _, gift in MonetizationConfig.Gifts do
	table.insert(giftChoices, { Value = gift.Key, Label = gift.Key })
end

local boostChoices: { Choice } = {}
for _, boost in MonetizationConfig.Boosts do
	table.insert(boostChoices, { Value = boost.Key, Label = boost.DisplayName })
end

local serverBoostChoices: { Choice } = {}
for _, boost in MonetizationConfig.ServerBoosts do
	table.insert(serverBoostChoices, { Value = boost.Key, Label = boost.DisplayName })
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

local pityChoices: { Choice } = {}
for _, key in GeodeConfig.PityRarities do
	table.insert(pityChoices, { Value = key, Label = RarityConfig.Rarities[key].DisplayName })
end

local qualityChoices: { Choice } = {}
for _, key in { "Perfect", "Great", "Good", "Mid", "Bad" } do
	table.insert(qualityChoices, { Value = key, Label = key })
end

local streakChoices: { Choice } = { { Value = "0", Label = "Off" } }
for index, tier in HotStreakConfig.Tiers do
	table.insert(streakChoices, { Value = tostring(index), Label = `Tier {index} (x{tier.Multiplier})` })
end

local tutorialChoices: { Choice } = {
	{ Value = "All", Label = "All" },
	{ Value = "Main", Label = "Main Tutorial" },
	{ Value = "Aura", Label = "Aura Hint" },
	{ Value = "Rock", Label = "Boulder Hint" },
	{ Value = "Rebirth", Label = "Rebirth Hint" },
	{ Value = "Cannon", Label = "Cannon Hint" },
}

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
	Tabs = { "Setup", "Move", "Player", "Roks", "Geodes", "Chop", "Events", "Shop" },
	PresetTab = "Setup",
	WarpTab = "Move",
	Commands = {
		{
			Id = "SaveSnapshot",
			Label = "Save Snapshot",
			Tab = "Setup",
			Kind = "Text",
			Default = "",
			Placeholder = "Snapshot name",
			Alias = "save",
		},
		{
			Id = "LoadSnapshot",
			Label = "Load Snapshot",
			Tab = "Setup",
			Kind = "Text",
			Default = "",
			Placeholder = "Snapshot name",
			Alias = "load",
		},
		{
			Id = "ListSnapshots",
			Label = "List Snapshots",
			Tab = "Setup",
			Kind = "Button",
			Alias = "snapshots",
		},
		{
			Id = "DeleteSnapshot",
			Label = "Delete Snapshot",
			Tab = "Setup",
			Kind = "Text",
			Default = "",
			Placeholder = "Snapshot name",
			Alias = "delsnap",
		},
		{
			Id = "ResetData",
			Label = "Reset My Data",
			Tab = "Setup",
			Kind = "Button",
			Shortcut = Enum.KeyCode.Backspace,
			Alias = "resetme",
		},
		{
			Id = "ResetTutorial",
			Label = "Reset Tutorial",
			Tab = "Setup",
			Kind = "Choice",
			Choices = tutorialChoices,
			Alias = "tutorial",
		},
		{
			Id = "ResetPlayerData",
			Label = "Reset Player Data",
			Tab = "Setup",
			Kind = "Text",
			Default = "",
			Placeholder = "Name or UserId, in game or not",
			Alias = "reset",
		},
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
			Tab = "Player",
			Kind = "Number",
			Default = "1m",
			Alias = "cash",
		},
		{
			Id = "GrantCash",
			Label = "+1,000 Cash",
			Tab = "Player",
			Kind = "Button",
			Shortcut = Enum.KeyCode.C,
			Alias = "addcash",
		},
		{
			Id = "SetStrength",
			Label = "Set Strength",
			Tab = "Player",
			Kind = "Number",
			Default = "100",
			Alias = "strength",
		},
		{
			Id = "SetRebirths",
			Label = "Set Rebirths",
			Tab = "Player",
			Kind = "Number",
			Default = "1",
			Alias = "rebirths",
		},
		{
			Id = "SetAuraTier",
			Label = "Set Aura Tier",
			Tab = "Player",
			Kind = "Choice",
			Choices = auraChoices,
			Alias = "aura",
		},
		{
			Id = "SetTrainingTier",
			Label = "Set Training Tier",
			Tab = "Player",
			Kind = "Number",
			Default = "1",
			Alias = "training",
		},
		{
			Id = "SetPedestalSlots",
			Label = "Set Pedestal Slots",
			Tab = "Player",
			Kind = "Number",
			Default = "8",
			Alias = "slots",
		},
		{
			Id = "GrantCannons",
			Label = "Grant All Cannons",
			Tab = "Player",
			Kind = "Button",
			Alias = "cannons",
		},
		{
			Id = "ResetCannons",
			Label = "Reset Cannons",
			Tab = "Player",
			Kind = "Button",
			Alias = "nocannons",
		},
		{
			Id = "SimulateOffline",
			Label = "Simulate Offline Hours",
			Tab = "Player",
			Kind = "Number",
			Default = "2",
			Alias = "offline",
		},
		{
			Id = "LeaderboardRefresh",
			Label = "Leaderboards: Refresh",
			Tab = "Player",
			Kind = "Button",
			Alias = "lbrefresh",
		},
		{
			Id = "LeaderboardWeek",
			Label = "Leaderboards: Week Offset",
			Tab = "Player",
			Kind = "Number",
			Default = "1",
			Alias = "lbweek",
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
			Label = "Held Rok: Set Trait",
			Tab = "Roks",
			Kind = "Choice",
			Choices = traitChoices,
			Alias = "trait",
		},
		{
			Id = "GiveModifier",
			Label = "Held Rok: Set Modifier",
			Tab = "Roks",
			Kind = "Choice",
			Choices = modifierChoices,
			Alias = "modifier",
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
			Tab = "Roks",
			Kind = "Choice",
			Choices = indexChoices,
			Alias = "index",
		},
		{
			Id = "IndexReset",
			Label = "Index: Reset",
			Tab = "Roks",
			Kind = "Choice",
			Choices = indexChoices,
			Alias = "unindex",
		},
		{
			Id = "IndexClaimAll",
			Label = "Index: Claim All",
			Tab = "Roks",
			Kind = "Button",
			Alias = "claimall",
		},
		{
			Id = "GrantGeode",
			Label = "+1 Geode",
			Tab = "Geodes",
			Kind = "Button",
			Shortcut = Enum.KeyCode.G,
			Alias = "geode",
		},
		{
			Id = "GrantGeodes",
			Label = "+10 Geodes",
			Tab = "Geodes",
			Kind = "Choice",
			Choices = geodeChoices,
			Alias = "geodes",
		},
		{
			Id = "GrantLuckyGeode",
			Label = "+1 Lucky Geode",
			Tab = "Geodes",
			Kind = "Button",
			Alias = "lucky",
		},
		{
			Id = "ForceRarity",
			Label = "Next Hatch Rarity",
			Tab = "Geodes",
			Kind = "Choice",
			Choices = rarityChoices,
			Alias = "rarity",
		},
		{
			Id = "ForceSecret",
			Label = "Next Hatch: Secret",
			Tab = "Geodes",
			Kind = "Button",
			Shortcut = Enum.KeyCode.H,
			Alias = "secret",
		},
		{
			Id = "PityDue",
			Label = "Pity: Next Due",
			Tab = "Geodes",
			Kind = "Choice",
			Choices = pityChoices,
			Alias = "pity",
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
			Label = "Next Chop Quality",
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
			Id = "SpawnSpots",
			Label = "Toggle Spawn Spots",
			Tab = "Chop",
			Kind = "Button",
			Shortcut = Enum.KeyCode.K,
			Alias = "spots",
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
			Id = "GlobalMessage",
			Label = "Global Message",
			Tab = "Events",
			Kind = "Text",
			Default = "",
			Placeholder = "Shown in every server",
			Alias = "announce",
		},
		{
			Id = "WeatherStart",
			Label = "Weather: Start",
			Tab = "Events",
			Kind = "Choice",
			Choices = weatherChoices,
			Alias = "weather",
		},
		{ Id = "WeatherEnd", Label = "Weather: End", Tab = "Events", Kind = "Button", Alias = "weatherend" },
		{
			Id = "WeatherNext",
			Label = "Weather: Next in 10s",
			Tab = "Events",
			Kind = "Button",
			Shortcut = Enum.KeyCode.N,
			Alias = "weathernext",
		},
		{
			Id = "SpawnDiamond",
			Label = "Spawn Diamond Rock",
			Tab = "Events",
			Kind = "Button",
			Shortcut = Enum.KeyCode.D,
			Alias = "diamond",
		},
		{
			Id = "DiamondTimeLeft",
			Label = "Diamond: 10s Left",
			Tab = "Events",
			Kind = "Button",
			Shortcut = Enum.KeyCode.T,
			Alias = "diamondend",
		},
		{
			Id = "ForceRush",
			Label = "Next Rock: Rush",
			Tab = "Events",
			Kind = "Button",
			Shortcut = Enum.KeyCode.R,
			Alias = "rush",
		},
		{
			Id = "StartGeodeFall",
			Label = "Start Geode Fall",
			Tab = "Events",
			Kind = "Button",
			Shortcut = Enum.KeyCode.F,
			Alias = "geodefall",
		},
		{
			Id = "GeodeFallTimeLeft",
			Label = "Geode Fall: 10s Left",
			Tab = "Events",
			Kind = "Button",
			Alias = "geodefallend",
		},
		{
			Id = "ToggleFakePass",
			Label = "Toggle Fake Pass (Studio)",
			Tab = "Shop",
			Kind = "Choice",
			Choices = passChoices,
			Alias = "pass",
		},
		{
			Id = "GiveBoost",
			Label = "Give Boost (+15 min)",
			Tab = "Shop",
			Kind = "Choice",
			Choices = boostChoices,
			Alias = "boost",
		},
		{
			Id = "GiveServerBoost",
			Label = "Server Boost (+15 min)",
			Tab = "Shop",
			Kind = "Choice",
			Choices = serverBoostChoices,
			Alias = "serverboost",
		},
		{
			Id = "ClearBoosts",
			Label = "Clear All Boosts",
			Tab = "Shop",
			Kind = "Button",
			Alias = "noboosts",
		},
		{
			Id = "GrantStarterPack",
			Label = "Grant Starter Pack",
			Tab = "Shop",
			Kind = "Button",
			Alias = "starter",
		},
		{
			Id = "ResetStarterPack",
			Label = "Reset Starter Pack",
			Tab = "Shop",
			Kind = "Button",
			Alias = "nostarter",
		},
		{
			Id = "GrantExclusive",
			Label = "Grant Exclusive Rok",
			Tab = "Shop",
			Kind = "Choice",
			Choices = exclusiveChoices,
			Alias = "exclusive",
		},
		{
			Id = "ResetExclusive",
			Label = "Reset Exclusive Rok",
			Tab = "Shop",
			Kind = "Choice",
			Choices = exclusiveChoices,
			Alias = "noexclusive",
		},
		{
			Id = "SimulateGift",
			Label = "Simulate Gift",
			Tab = "Shop",
			Kind = "Choice",
			Choices = giftChoices,
			Alias = "gift",
		},
		{
			Id = "GrantOfflineClaim",
			Label = "Grant Offline Claim x3",
			Tab = "Shop",
			Kind = "Button",
			Alias = "claimx3",
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
	MaxArgumentLength = 200,
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
