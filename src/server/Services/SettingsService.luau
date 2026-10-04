--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local SettingsConfig = require(ReplicatedStorage.Config.SettingsConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SettingsService = { Name = "SettingsService" }
local services: { [string]: any } = {}
local trove = Trove.new()

function SettingsService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function SettingsService.Start(_self: any)
	trove:Add(Packets.SetSetting.OnServerEvent:Connect(function(player: Player, name: string, value: boolean)
		if type(value) ~= "boolean" or not table.find(SettingsConfig.Toggles, name) then
			return
		end
		services.DataService:Set(player, { "Settings", name }, value)
	end))
end

function SettingsService.Destroy(_self: any)
	trove:Destroy()
end

return SettingsService
