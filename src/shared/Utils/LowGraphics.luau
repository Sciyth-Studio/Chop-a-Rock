--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsConfig = require(ReplicatedStorage.Config.SettingsConfig)

local LowGraphics = {}

function LowGraphics.IsOn(): boolean
	local player = Players.LocalPlayer
	return player ~= nil and player:GetAttribute(SettingsConfig.LowGraphicsAttribute) == true
end

function LowGraphics.EmitScale(): number
	return if LowGraphics.IsOn() then SettingsConfig.LowGraphicsEmitScale else 1
end

return LowGraphics
