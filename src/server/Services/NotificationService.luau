--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationConfig = require(ReplicatedStorage.Config.NotificationConfig)
local Packets = require(ReplicatedStorage.Packets)

local NotificationService = {
	Name = "NotificationService",
}

function NotificationService.Notify(_self: any, player: Player, kind: string, message: string)
	if not NotificationConfig.Kinds[kind] then
		warn(`[NotificationService] Unknown notification kind "{kind}"`)
		kind = NotificationConfig.FallbackKind
	end
	if player.Parent then
		Packets.Notify:FireClient(player, kind, string.sub(message, 1, 200))
	end
end

function NotificationService.Init(_self: any, _services: { [string]: any }) end

function NotificationService.Start(_self: any) end

function NotificationService.Destroy(_self: any) end

return NotificationService
