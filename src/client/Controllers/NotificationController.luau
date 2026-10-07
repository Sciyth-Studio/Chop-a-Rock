--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationConfig = require(ReplicatedStorage.Config.NotificationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local NotificationController = {
	Name = "NotificationController",
	Notified = Signal.new(),
	_trove = nil :: TroveInstance?,
	_controllers = {} :: { [string]: any },
}

function NotificationController.Notify(self: any, kind: string, message: string)
	if self._controllers.DataController:Get({ "Settings", "Notifications" }) == false then
		return
	end
	if not NotificationConfig.Kinds[kind] then
		kind = NotificationConfig.FallbackKind
	end
	self.Notified:Fire(kind, message)
end

function NotificationController.Init(self: any, controllers: { [string]: any })
	self._controllers = controllers
	self._trove = Trove.new()
end

function NotificationController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.Notify.OnClientEvent:Connect(function(kind: string, message: string)
		self:Notify(kind, message)
	end))
end

function NotificationController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return NotificationController
