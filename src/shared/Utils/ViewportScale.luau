--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScaleConfig = require(ReplicatedStorage.Config.ScaleConfig)

local ViewportScale = {}

function ViewportScale.Compute(viewport: Vector2): number
	local shortSide = math.min(viewport.X, viewport.Y)
	if shortSide <= 0 then
		return 1
	end
	if shortSide > ScaleConfig.UpscaleShortSidePixels then
		return math.min(shortSide / ScaleConfig.UpscaleShortSidePixels, ScaleConfig.MaxScale)
	end
	return math.clamp(shortSide / ScaleConfig.ReferenceShortSidePixels, ScaleConfig.MinScale, 1)
end

function ViewportScale.Fit(uiScale: UIScale, value: number, available: Vector2): number
	local parent = uiScale.Parent
	if
		not parent
		or not parent:IsA("GuiObject")
		or uiScale:GetAttribute(ScaleConfig.FitAttribute) == false
	then
		return value
	end
	local size = parent.Size
	if size.X.Scale ~= 0 or size.Y.Scale ~= 0 then
		return math.min(value, 1)
	end
	local margin = ScaleConfig.FitMarginPixels * 2
	local fitted = value
	if size.X.Offset > 0 and available.X > margin then
		fitted = math.min(fitted, (available.X - margin) / size.X.Offset)
	end
	if size.Y.Offset > 0 and available.Y > margin then
		fitted = math.min(fitted, (available.Y - margin) / size.Y.Offset)
	end
	return fitted
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

	local layer: LayerCollector? = if root:IsA("LayerCollector")
		then root
		else root:FindFirstAncestorWhichIsA("LayerCollector")

	local function refresh()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local value = ViewportScale.Compute(camera.ViewportSize)
		local available = if layer and layer.AbsoluteSize.X > 0
			then layer.AbsoluteSize
			else camera.ViewportSize
		for _, uiScale in scales do
			local fitted = ViewportScale.Fit(uiScale, value, available)
			if uiScale.Scale ~= fitted then
				uiScale.Scale = fitted
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

	for _, uiScale in scales do
		local parent = uiScale.Parent
		if parent and parent:IsA("GuiObject") then
			trove:Connect(parent:GetPropertyChangedSignal("Size"), refresh)
		end
	end
	if layer then
		trove:Connect(layer:GetPropertyChangedSignal("AbsoluteSize"), refresh)
	end
	trove:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
	watchCamera()
end

return ViewportScale
