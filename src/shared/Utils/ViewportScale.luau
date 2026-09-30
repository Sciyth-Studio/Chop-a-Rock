--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScaleConfig = require(ReplicatedStorage.Config.ScaleConfig)

local ViewportScale = {}

function ViewportScale.Compute(viewport: Vector2): number
	local shortSide = math.min(viewport.X, viewport.Y)
	if shortSide <= 0 then
		return 1
	end
	return math.clamp(shortSide / ScaleConfig.ReferenceShortSidePixels, ScaleConfig.MinScale, 1)
end

function ViewportScale.ApplyToBillboard(billboard: BillboardGui)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local value = ViewportScale.Compute(camera.ViewportSize)
	for _, descendant in billboard:GetDescendants() do
		if descendant:IsA("UIScale") and descendant.Name == ScaleConfig.ScaleName then
			descendant.Scale = value
		end
	end
	local size = billboard.Size
	billboard.Size = UDim2.new(size.X.Scale, size.X.Offset * value, size.Y.Scale, size.Y.Offset * value)
end

function ViewportScale.Bind(root: Instance, trove: any)
	local scales: { UIScale } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("UIScale") and descendant.Name == ScaleConfig.ScaleName then
			table.insert(scales, descendant)
		end
	end
	if #scales == 0 then
		warn(`[ViewportScale] Missing UIScale "{ScaleConfig.ScaleName}" in {root:GetFullName()}`)
		return
	end

	local function refresh()
		local camera = workspace.CurrentCamera
		if camera then
			local value = ViewportScale.Compute(camera.ViewportSize)
			for _, uiScale in scales do
				uiScale.Scale = value
			end
		end
	end

	local function watchCamera()
		local camera = workspace.CurrentCamera
		if camera then
			trove:Connect(camera:GetPropertyChangedSignal("ViewportSize"), refresh)
		end
		refresh()
	end

	trove:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	watchCamera()
end

return ViewportScale
