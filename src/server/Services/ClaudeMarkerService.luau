--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ClaudeMarkerService: Lifecycle.System = { Name = "ClaudeMarkerService" }

local trove = Trove.new()

function ClaudeMarkerService.Init(_self: any, _registry: { [string]: any }) end

function ClaudeMarkerService.Start(_self: any)
	local part = Instance.new("Part")
	part.Name = "ClaudeMarker"
	part.Size = Vector3.new(4, 4, 4)
	part.Position = Vector3.new(0, 3, 0)
	part.Anchored = true
	part.Color = Color3.fromRGB(46, 204, 113)
	part.Material = Enum.Material.Neon
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = workspace
	trove:Add(part)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Claude Connected"
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = billboard
end

function ClaudeMarkerService.Destroy(_self: any)
	trove:Clean()
end

return ClaudeMarkerService
