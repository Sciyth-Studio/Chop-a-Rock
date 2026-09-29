--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FontConfig = require(ReplicatedStorage.Config.FontConfig)
local TextStyleConfig = require(ReplicatedStorage.Config.TextStyleConfig)

local Typography = {}

local function fontFor(instance: Instance): Font
	return if instance:GetAttribute(FontConfig.ItalicAttribute) == true
		then FontConfig.Italic
		else FontConfig.Default
end

function Typography.ApplyTextStyle(label: TextLabel, styleName: string)
	local style = TextStyleConfig.Styles[styleName]
	if not style then
		warn(`[Typography] Unknown text style "{styleName}" on {label:GetFullName()}`)
		return
	end
	label.TextColor3 = Color3.new(1, 1, 1)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Enabled = true
		gradient.Rotation = style.GradientRotation
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, style.EdgeColor),
			ColorSequenceKeypoint.new(0.5, style.CenterColor),
			ColorSequenceKeypoint.new(1, style.EdgeColor),
		})
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = style.StrokeColor
		if style.StrokeThickness then
			stroke.Thickness = style.StrokeThickness
		end
	end
end

local function apply(instance: Instance)
	if instance:IsA("TextLabel") then
		instance.FontFace = fontFor(instance)
		local styleName = instance:GetAttribute(TextStyleConfig.AttributeName)
		if type(styleName) == "string" then
			Typography.ApplyTextStyle(instance, styleName)
		end
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
