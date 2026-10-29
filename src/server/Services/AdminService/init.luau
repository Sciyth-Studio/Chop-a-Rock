--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Commands = require(script.Commands)
local Presets = require(script.Presets)
local Types = require(script.Types)

local AdminService = { Name = "AdminService" }

local trove = Trove.new()
local context: Types.Context = { Services = {}, PendingResets = {} }
local autoPresetApplied: { [Player]: boolean } = {}

local function applyAutoPreset(player: Player)
	if autoPresetApplied[player] or not RunService:IsStudio() then
		return
	end
	autoPresetApplied[player] = true
	local presetId = workspace:GetAttribute(AdminConfig.AutoPresetAttribute)
	if type(presetId) ~= "string" or #presetId == 0 then
		return
	end
	local preset = Presets.Find(presetId)
	if not preset then
		warn(`[AdminService] {AdminConfig.AutoPresetAttribute} names unknown preset {presetId}`)
		return
	end
	task.defer(function()
		if player.Parent == Players and Presets.Apply(context, player, preset) then
			print(`[AdminService] auto preset {preset.Id} applied to {player.Name}`)
		end
	end)
end

function AdminService.IsAdmin(_self: any, player: Player): boolean
	return RunService:IsStudio() or table.find(AdminConfig.UserIds, player.UserId) ~= nil
end

function AdminService.Init(_self: any, registry: { [string]: any })
	context.Services = registry
end

function AdminService.Start(_self: any)
	local function mark(player: Player)
		if AdminService:IsAdmin(player) then
			player:SetAttribute(AdminConfig.AttributeName, true)
		end
	end
	for _, player in Players:GetPlayers() do
		mark(player)
	end
	trove:Add(Players.PlayerAdded:Connect(mark))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		autoPresetApplied[player] = nil
		context.PendingResets[player] = nil
	end))
	trove:Add(context.Services.DataService.PlayerLoaded:Connect(applyAutoPreset))
	trove:Add(
		Packets.AdminRun.OnServerEvent:Connect(function(player: Player, commandId: string, argument: string)
			if not AdminService:IsAdmin(player) then
				return
			end
			if type(argument) ~= "string" or #argument > AdminConfig.MaxArgumentLength then
				return
			end
			local handler = Commands[commandId]
			if not handler then
				return
			end
			print(`[AdminService] {player.Name} ran {commandId} {argument}`)
			handler(context, player, argument)
		end)
	)
end

function AdminService.Destroy(_self: any)
	trove:Clean()
	table.clear(autoPresetApplied)
	table.clear(context.PendingResets)
end

return AdminService
