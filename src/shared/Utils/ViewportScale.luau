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

function ViewportScale.Bind(root: Instance, trove: any)
	local found = root:FindFirstChild(ScaleConfig.ScaleName, true)
	if not found or not found:IsA("UIScale") then
		warn(`[ViewportScale] Missing UIScale "{ScaleConfig.ScaleName}" in {root:GetFullName()}`)
		return
	end
	local uiScale = found

	local function refresh()
		local camera = workspace.CurrentCamera
		if camera then
			uiScale.Scale = ViewportScale.Compute(camera.ViewportSize)
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
