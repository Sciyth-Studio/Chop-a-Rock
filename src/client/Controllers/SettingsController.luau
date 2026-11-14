--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local SettingsConfig = require(ReplicatedStorage.Config.SettingsConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SettingsController = { Name = "SettingsController" }
local controllers: { [string]: any } = {}
local trove = Trove.new()

function SettingsController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

local function findGroup(name: string): SoundGroup?
	local group = SoundService:FindFirstChild(name)
	if not group or not group:IsA("SoundGroup") then
		warn(`[SettingsController] Missing SoundGroup SoundService.{name}; {name} setting disabled`)
		return nil
	end
	return group
end

local function level(value: any): number
	return if type(value) == "number" then math.clamp(value, 0, 1) else 1
end

function SettingsController.Start(_self: any)
	local dataController = controllers.DataController
	for setting, groupName in SettingsConfig.SoundSliders do
		local group = findGroup(groupName)
		if not group then
			continue
		end
		local volume = group.Volume
		trove:Add(dataController:Observe({ "Settings", setting }, function(value: any)
			group.Volume = volume * level(value)
		end))
	end

	local globalShadows = Lighting.GlobalShadows
	trove:Add(dataController:Observe({ "Settings", "LowGraphics" }, function(value: any)
		local isOn = value == true
		Players.LocalPlayer:SetAttribute(SettingsConfig.LowGraphicsAttribute, isOn)
		Lighting.GlobalShadows = if isOn then false else globalShadows
	end))
	trove:Add(function()
		Lighting.GlobalShadows = globalShadows
	end)
end

function SettingsController.Destroy(_self: any)
	trove:Destroy()
end

return SettingsController
