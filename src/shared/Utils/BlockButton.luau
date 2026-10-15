--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlockButtonConfig = require(ReplicatedStorage.Config.BlockButtonConfig)

export type Colors = {
	Edge: Color3,
	Center: Color3,
	Studs: Color3,
}

export type LabelLayout = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
}

local BlockButton = {}

local white = Color3.new(1, 1, 1)
local black = Color3.new(0, 0, 0)

function BlockButton.Paint(fill: Instance?, colors: Colors)
	if not fill then
		return
	end
	local top = colors.Edge:Lerp(colors.Center, BlockButtonConfig.TopFromEdge)
	local gradient = fill:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(top, colors.Edge)
	end
	local studs = fill:FindFirstChild("StudTexture")
	if studs and studs:IsA("ImageLabel") then
		studs.ImageColor3 = colors.Studs
	end

	local track = fill.Parent
	if not track or track.Name ~= BlockButtonConfig.TrackName then
		return
	end
	local box = track.Parent
	if box and box:IsA("GuiObject") then
		box.BackgroundColor3 = colors.Studs:Lerp(black, BlockButtonConfig.OutlineDarken)
	end
	local lip = track:FindFirstChild(BlockButtonConfig.LipName)
	if lip and lip:IsA("GuiObject") then
		lip.BackgroundColor3 = colors.Studs:Lerp(colors.Edge, BlockButtonConfig.LipToEdge)
		local highlight = lip:FindFirstChild(BlockButtonConfig.HighlightName)
		if highlight and highlight:IsA("GuiObject") then
			highlight.BackgroundColor3 = top:Lerp(white, BlockButtonConfig.HighlightLighten)
		end
	end
	local bevel = track:FindFirstChild(BlockButtonConfig.BevelName)
	local bevelStroke = if bevel then bevel:FindFirstChildWhichIsA("UIStroke") else nil
	if bevelStroke then
		bevelStroke.Color = top:Lerp(white, BlockButtonConfig.BevelLighten)
	end
end

function BlockButton.SetText(label: Instance, text: string)
	(label :: any).Text = text
	local parent = label.Parent
	local shadow = if parent then parent:FindFirstChild(label.Name .. BlockButtonConfig.ShadowSuffix) else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

function BlockButton.PlaceLabel(label: TextLabel, layout: LabelLayout)
	label.AnchorPoint = layout.AnchorPoint
	label.Position = layout.Position
	label.Size = layout.Size
	local parent = label.Parent
	local shadow = if parent then parent:FindFirstChild(label.Name .. BlockButtonConfig.ShadowSuffix) else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.AnchorPoint = layout.AnchorPoint
		shadow.Position = layout.Position + BlockButtonConfig.ShadowOffset
		shadow.Size = layout.Size
	end
end

return BlockButton
