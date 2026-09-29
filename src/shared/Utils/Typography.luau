--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FontConfig = require(ReplicatedStorage.Config.FontConfig)

local Typography = {}

local function fontFor(instance: Instance): Font
	return if instance:GetAttribute(FontConfig.ItalicAttribute) == true
		then FontConfig.Italic
		else FontConfig.Default
end

local function apply(instance: Instance)
	if instance:IsA("TextLabel") then
		instance.FontFace = fontFor(instance)
	elseif instance:IsA("TextButton") then
		instance.FontFace = fontFor(instance)
	elseif instance:IsA("TextBox") then
		instance.FontFace = fontFor(instance)
	end
end

function Typography.Apply(root: Instance)
	apply(root)
	for _, descendant in root:GetDescendants() do
		apply(descendant)
	end
end

return Typography
