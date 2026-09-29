--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FontConfig = require(ReplicatedStorage.Config.FontConfig)

local Typography = {}

local function apply(instance: Instance)
	if instance:IsA("TextLabel") then
		instance.FontFace = FontConfig.Default
	elseif instance:IsA("TextButton") then
		instance.FontFace = FontConfig.Default
	elseif instance:IsA("TextBox") then
		instance.FontFace = FontConfig.Default
	end
end

function Typography.Apply(root: Instance)
	apply(root)
	for _, descendant in root:GetDescendants() do
		apply(descendant)
	end
end

return Typography
