--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)

local ChatTagController = { Name = "ChatTagController" }

local controllers: { [string]: any } = {}
local vip = MonetizationConfig.Vip

local function isVip(player: Player): boolean
	return player:GetAttribute(MonetizationConfig.PassAttributePrefix .. vip.PassKey) == true
end

local function onIncomingMessage(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	local player = if source then Players:GetPlayerByUserId(source.UserId) else nil
	if not player then
		return nil
	end
	local tags: { string } = {}
	local crown = controllers.CrownController
	local crownTag = if crown then crown:ChatTag(player) else nil
	if crownTag then
		table.insert(tags, crownTag)
	end
	local name = message.PrefixText
	if isVip(player) then
		table.insert(tags, `<font color="{vip.TagColor}">{vip.ChatTag}</font>`)
		name = `<font color="{vip.NameColor}">{name}</font>`
	end
	if #tags == 0 and name == message.PrefixText then
		return nil
	end
	local properties = Instance.new("TextChatMessageProperties")
	table.insert(tags, name)
	properties.PrefixText = table.concat(tags, " ")
	return properties
end

function ChatTagController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function ChatTagController.Start(_self: any)
	TextChatService.OnIncomingMessage = onIncomingMessage
end

function ChatTagController.Destroy(_self: any)
	TextChatService.OnIncomingMessage = nil :: any
end

return ChatTagController
