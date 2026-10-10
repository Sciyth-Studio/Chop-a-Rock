--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RebirthConfig = require(ReplicatedStorage.Config.RebirthConfig)
local WalkSpeedConfig = require(ReplicatedStorage.Config.WalkSpeedConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local Level = require(ReplicatedStorage.Utils.Level)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Arguments = require(script.Parent.Arguments)
local Presets = require(script.Parent.Presets)
local Types = require(script.Parent.Types)
local Warps = require(script.Parent.Warps)

local random = Random.new()

local function notify(context: Types.Context, player: Player, message: string)
	context.Services.NotificationService:Notify(player, "Info", `Admin: {message}`)
end

local function number(
	context: Types.Context,
	player: Player,
	argument: string,
	min: number,
	max: number
): number?
	local value = Arguments.Number(argument, min, max)
	if not value then
		notify(
			context,
			player,
			`enter a number from {NumberFormat.Compact(min)} to {NumberFormat.Compact(max)}`
		)
	end
	return value
end

local Commands: { [string]: Types.Handler } = {
	ApplyPreset = function(context: Types.Context, player: Player, argument: string)
		local preset = Presets.Find(argument)
		if preset and Presets.Apply(context, player, preset) then
			notify(context, player, `preset {preset.Label}`)
		end
	end,
	Warp = function(context: Types.Context, player: Player, argument: string)
		if not Warps.Teleport(context, player, argument) then
			notify(context, player, `no warp called {argument}`)
		end
	end,
	SetWalkSpeed = function(context: Types.Context, player: Player, argument: string)
		local speed = number(context, player, argument, 0, AdminConfig.Limits.WalkSpeed)
		if speed then
			local bonus = speed - WalkSpeedConfig.BaseWalkSpeed
			context.Services.WalkSpeedService:SetBonus(player, AdminConfig.WalkSpeedSource, bonus)
			notify(context, player, `walk speed {speed}`)
		end
	end,
	SetCash = function(context: Types.Context, player: Player, argument: string)
		local cash = number(context, player, argument, 0, AdminConfig.Limits.Cash)
		if cash and context.Services.DataService:Set(player, { "Cash" }, cash) then
			context.Services.DataService:RequestSave(player)
			notify(context, player, `cash {NumberFormat.Compact(cash)}`)
		end
	end,
	GrantCash = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.DataService:AdjustCash(player, AdminConfig.CashAmount) then
			notify(context, player, `+{AdminConfig.CashAmount} cash`)
		end
	end,
	SetLevel = function(context: Types.Context, player: Player, argument: string)
		local level = number(context, player, argument, 1, AdminConfig.Limits.Level)
		if level and context.Services.StatsService:SetStrength(player, Level.StrengthFor(level)) then
			notify(context, player, `level {level}`)
		end
	end,
	SetStrength = function(context: Types.Context, player: Player, argument: string)
		local strength = number(context, player, argument, 0, AdminConfig.Limits.Strength)
		if strength and context.Services.StatsService:SetStrength(player, strength) then
			notify(context, player, `strength {NumberFormat.Compact(strength)}`)
		end
	end,
	SetRebirths = function(context: Types.Context, player: Player, argument: string)
		local rebirths = number(context, player, argument, 0, #RebirthConfig.Rebirths)
		if rebirths and context.Services.DataService:Set(player, { "Rebirths" }, rebirths) then
			context.Services.DataService:RequestSave(player)
			notify(context, player, `rebirths {rebirths}`)
		end
	end,
	SetArmTier = function(context: Types.Context, player: Player, argument: string)
		local tier = number(context, player, argument, 1, #ArmConfig.Tiers)
		if tier and context.Services.ArmService:SetTier(player, tier) then
			notify(context, player, ArmConfig.Tiers[tier].DisplayName)
		end
	end,
	SetPedestalSlots = function(context: Types.Context, player: Player, argument: string)
		local slots = number(context, player, argument, 1, PedestalSlots.Total())
		if slots and context.Services.PedestalService:SetSlots(player, slots) then
			notify(context, player, `{slots} slots`)
		end
	end,
	GrantPet = function(context: Types.Context, player: Player, _argument: string)
		local geodeKey = next(GeodeConfig.Geodes)
		local petKey = if geodeKey then HatchOdds.Roll(random, geodeKey, 1) else nil
		local grant = if petKey then context.Services.PetService:Grant(player, petKey) else nil
		if not grant then
			notify(context, player, "no Rok granted")
			return
		end
		local pet = PetConfig.Pets[grant.PetKey]
		local trait = if grant.Trait then ` + {grant.Trait} {grant.TraitValue}` else ""
		notify(context, player, `{pet.DisplayName} ({pet.Rarity}){trait}{if grant.IsNew then " New" else ""}`)
	end,
	GrantGeode = function(context: Types.Context, player: Player, _argument: string)
		local geodeKey = next(GeodeConfig.Geodes)
		if geodeKey and context.Services.GeodeService:GrantGeodes(player, geodeKey, 1) then
			notify(context, player, `+1 {GeodeConfig.Geodes[geodeKey].DisplayName}`)
		end
	end,
	ForceSecret = function(context: Types.Context, player: Player, _argument: string)
		context.Services.GeodeService:ForceNextRarity(player, "Secret")
		notify(context, player, "next hatch is a Secret")
	end,
	ForceMaster = function(context: Types.Context, player: Player, _argument: string)
		context.Services.RockService:ForceNextMaster(player)
		notify(context, player, "next chop is a Master")
	end,
	ForceRush = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.RockService:ForceRush(player) then
			notify(context, player, "next broken rock comes back as a Rush Rock")
		else
			notify(context, player, "a Rush Rock is already out")
		end
	end,
	SpawnDiamond = function(context: Types.Context, player: Player, _argument: string)
		local _spawned, message = context.Services.DiamondRockService:Spawn(player)
		notify(context, player, message)
	end,
	DiamondTimeLeft = function(context: Types.Context, player: Player, _argument: string)
		local seconds = DiamondRockConfig.AdminCountdownSeconds
		if context.Services.DiamondRockService:SetTimeLeft(seconds) then
			notify(context, player, `Diamond Rock ends in {seconds}s`)
		else
			notify(context, player, "no Diamond Rock out")
		end
	end,
	SpawnSpots = function(context: Types.Context, player: Player, _argument: string)
		local isShown = context.Services.RockService:ToggleSpawnSpots(player)
		notify(context, player, if isShown then "spawn spots shown" else "spawn spots hidden")
	end,
	ResetData = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.DataService:ResetData(player) then
			notify(context, player, "data reset")
		end
	end,
}

return Commands
