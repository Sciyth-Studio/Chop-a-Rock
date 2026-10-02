--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function applyHighlight(character: Model)
	local highlight = Instance.new("Highlight")
	highlight.Parent = character
	highlight.FillTransparency = 0.8
	highlight.FillColor = Color3.fromRGB(0, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.Enabled = true
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = character
end

player.CharacterAdded:Connect(applyHighlight)

if player.Character then
	applyHighlight(player.Character)
end
