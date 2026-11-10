--!strict

local Players = game:GetService("Players")

local HideBillboards = {}

local function hideIn(root: Instance, hidden: { BillboardGui })
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BillboardGui") and descendant.Enabled then
			descendant.Enabled = false
			table.insert(hidden, descendant)
		end
	end
end

function HideBillboards.Hide(): () -> ()
	local hidden: { BillboardGui } = {}
	hideIn(workspace, hidden)
	local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		hideIn(playerGui, hidden)
	end
	return function()
		for _, billboard in hidden do
			if billboard.Parent then
				billboard.Enabled = true
			end
		end
		table.clear(hidden)
	end
end

return HideBillboards
