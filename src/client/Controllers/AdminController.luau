--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local AdminController = {
	Name = "AdminController",
	_trove = nil :: TroveInstance?,
}

function AdminController.IsAdmin(_self: any): boolean
	return Players.LocalPlayer:GetAttribute(AdminConfig.AttributeName) == true
end

function AdminController.Run(_self: any, commandId: string, argument: string?)
	if AdminController:IsAdmin() then
		Packets.AdminRun:Fire(commandId, argument or "")
	end
end

function AdminController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function AdminController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Connect(UserInputService.InputBegan, function(input: InputObject, _processed: boolean)
		if not AdminController:IsAdmin() then
			return
		end
		for _, modifier in AdminConfig.ShortcutModifiers do
			if not UserInputService:IsKeyDown(modifier) then
				return
			end
		end
		for _, command in AdminConfig.Commands do
			if command.Kind == "Button" and command.Shortcut == input.KeyCode then
				AdminController:Run(command.Id)
				return
			end
		end
	end)
end

function AdminController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return AdminController
