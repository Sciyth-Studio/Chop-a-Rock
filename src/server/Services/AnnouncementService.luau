--!strict

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local AnnouncementConfig = require(ReplicatedStorage.Config.AnnouncementConfig)

local AnnouncementService = { Name = "AnnouncementService" }

local services: { [string]: any } = {}
local subscription: RBXScriptConnection? = nil
local isDestroyed = false
local lastSentAt = -math.huge

local function deliver(text: string)
	for _, player in Players:GetPlayers() do
		services.NotificationService:Notify(player, AnnouncementConfig.Kind, text)
	end
end

local function filter(text: string, fromUserId: number): string?
	local isFiltered, result = pcall(function()
		local filterResult =
			TextService:FilterStringAsync(text, fromUserId, Enum.TextFilterContext.PublicChat)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if not isFiltered then
		warn(`[AnnouncementService] Text filter failed: {result}`)
		return nil
	end
	return result
end

function AnnouncementService.Send(_self: any, sender: Player, text: string): (boolean, string)
	local trimmed = string.match(text, "^%s*(.-)%s*$") or ""
	if #trimmed == 0 then
		return false, "type a message first"
	end
	if #trimmed > AnnouncementConfig.MaxLength then
		return false, `messages are at most {AnnouncementConfig.MaxLength} characters`
	end
	local waitSeconds = lastSentAt + AnnouncementConfig.CooldownSeconds - os.clock()
	if waitSeconds > 0 then
		return false, `wait {math.ceil(waitSeconds)}s before the next message`
	end
	lastSentAt = os.clock()
	local filtered = filter(trimmed, sender.UserId)
	if not filtered then
		return false, "the text filter failed, try again"
	end
	deliver(filtered)
	local isPublished, problem = pcall(function()
		MessagingService:PublishAsync(AnnouncementConfig.Topic, { Text = filtered, JobId = game.JobId })
	end)
	if not isPublished then
		warn(`[AnnouncementService] Publish failed: {problem}`)
		return false, "shown in this server only, other servers could not be reached"
	end
	print(`[AnnouncementService] {sender.Name} announced: {filtered}`)
	return true, "message sent to every server"
end

function AnnouncementService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function AnnouncementService.Start(_self: any)
	task.spawn(function()
		local isSubscribed, result = pcall(function()
			return MessagingService:SubscribeAsync(AnnouncementConfig.Topic, function(message: any)
				local data = message.Data
				if type(data) ~= "table" or type(data.Text) ~= "string" or data.JobId == game.JobId then
					return
				end
				deliver(string.sub(data.Text, 1, AnnouncementConfig.MaxLength))
			end)
		end)
		if not isSubscribed then
			warn(
				`[AnnouncementService] Subscribe failed, this server will not receive announcements: {result}`
			)
			return
		end
		if isDestroyed then
			result:Disconnect()
			return
		end
		subscription = result
	end)
end

function AnnouncementService.Destroy(_self: any)
	isDestroyed = true
	if subscription then
		subscription:Disconnect()
		subscription = nil
	end
end

return AnnouncementService
