--!strict

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

function SettingsController.Start(_self: any)
	for _, name in SettingsConfig.Toggles do
		local group = findGroup(name)
		if not group then
			continue
		end
		local volume = group.Volume
		trove:Add(controllers.DataController:Observe({ "Settings", name }, function(isOn: any)
			group.Volume = if isOn == false then 0 else volume
		end))
	end
	for _, name in SettingsConfig.Sliders do
		local group = findGroup(name)
		if not group then
			continue
		end
		local volume = group.Volume
		trove:Add(controllers.DataController:Observe({ "Settings", name }, function(level: any)
			if type(level) == "number" then
				group.Volume = volume * math.clamp(level, 0, 1)
			else
				group.Volume = if level == false then 0 else volume
			end
		end))
	end
end

function SettingsController.Destroy(_self: any)
	trove:Destroy()
end

return SettingsController
