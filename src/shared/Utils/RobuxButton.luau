--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)

local RobuxButton = {}

function RobuxButton.Show(button: GuiObject?, price: number?)
	if not button then
		return
	end
	button.Visible = price ~= nil
	if not price then
		return
	end
	local text = `{MonetizationConfig.RobuxGlyph} {price}`
	for _, name in { "Label", "Label" .. HudConfig.ShadowSuffix } do
		local label = button:FindFirstChild(name)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
	BlockButton.Paint(button:FindFirstChild("Fill", true), MonetizationConfig.RobuxButtonColors)
end

return RobuxButton
