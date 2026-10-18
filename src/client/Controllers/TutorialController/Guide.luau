--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GuideConfig = require(ReplicatedStorage.Config.GuideConfig)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type Guide = {
	Folder: Folder,
	Chevrons: { BasePart },
	Anchor: BasePart,
	Marker: BillboardGui,
	Label: BillboardGui?,
	NameLabel: TextLabel?,
	Highlight: Highlight,
	Params: RaycastParams,
	Scroll: number,
	Clock: number,
}

local Guide = {}

local parked = CFrame.new(0, -500, 0)

local function makePart(name: string, parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = TutorialConfig.ChevronSize
	part.CFrame = parked
	part.Parent = parent
	return part
end

local function arrowTexture(): string
	local image = AssetRegistry.get(TutorialConfig.ArrowImageKey)
	local texture = if image:IsA("Decal") then image.Texture else ""
	image:Destroy()
	if texture == "" then
		warn(`[TutorialController] {TutorialConfig.ArrowImageKey} has no texture; guide arrows are blank`)
	end
	return texture
end

local function makeLabel(): (BillboardGui?, TextLabel?)
	local template = AssetRegistry.get(GuideConfig.LabelTemplateKey)
	if not template:IsA("BillboardGui") then
		warn(
			`[TutorialController] {GuideConfig.LabelTemplateKey} is not a BillboardGui; target labels are off`
		)
		template:Destroy()
		return nil, nil
	end
	template.Name = "TutorialLabel"
	template.AlwaysOnTop = true
	template.MaxDistance = TutorialConfig.LabelMaxDistance
	template.Enabled = false
	local found = template:FindFirstChild("NameLabel")
	local requirement = template:FindFirstChild("RequirementLabel")
	if requirement and requirement:IsA("GuiObject") then
		requirement.Visible = false
	end
	template.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return template, if found and found:IsA("TextLabel") then found else nil
end

local function makeMarker(texture: string, anchor: BasePart): BillboardGui
	local marker = Instance.new("BillboardGui")
	marker.Name = "TutorialMarker"
	marker.Adornee = anchor
	marker.AlwaysOnTop = true
	marker.LightInfluence = 0
	marker.MaxDistance = TutorialConfig.LabelMaxDistance
	marker.Size = UDim2.fromScale(TutorialConfig.MarkerSize, TutorialConfig.MarkerSize)
	marker.Enabled = false
	local image = Instance.new("ImageLabel")
	image.Name = "Arrow"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = texture
	image.Rotation = 180
	image.Parent = marker
	marker.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return marker
end

function Guide.new(): Guide
	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuide"
	folder.Parent = workspace

	local texture = arrowTexture()
	local chevrons = {}
	for _ = 1, TutorialConfig.ChevronCount do
		local part = makePart("Chevron", folder)
		local decal = Instance.new("Decal")
		decal.Face = Enum.NormalId.Top
		decal.Texture = texture
		decal.Parent = part
		table.insert(chevrons, part)
	end

	local anchor = makePart("MarkerAnchor", folder)
	anchor.Size = Vector3.one
	local label, nameLabel = makeLabel()

	local highlight = Instance.new("Highlight")
	highlight.Name = "TutorialHighlight"
	highlight.FillColor = TutorialConfig.HighlightColor
	highlight.OutlineColor = TutorialConfig.HighlightColor
	highlight.OutlineTransparency = TutorialConfig.HighlightOutlineTransparency
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = folder

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true

	return {
		Folder = folder,
		Chevrons = chevrons,
		Anchor = anchor,
		Marker = makeMarker(texture, anchor),
		Label = label,
		NameLabel = nameLabel,
		Highlight = highlight,
		Params = params,
		Scroll = 0,
		Clock = 0,
	}
end

local function groundAt(guide: Guide, position: Vector3): Vector3
	local character = Players.LocalPlayer.Character
	guide.Params.FilterDescendantsInstances = if character
		then { guide.Folder, character }
		else { guide.Folder }
	local result = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), guide.Params)
	return if result then result.Position else position - Vector3.new(0, 2.5, 0)
end

local function lengthOf(points: { Vector3 }): number
	local total = 0
	for index = 1, #points - 1 do
		total += Vector3.new(points[index + 1].X - points[index].X, 0, points[index + 1].Z - points[index].Z).Magnitude
	end
	return total
end

local function sample(points: { Vector3 }, distance: number): (Vector3, Vector3)
	local walked = 0
	for index = 1, #points - 1 do
		local a = points[index]
		local b = points[index + 1]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local length = flat.Magnitude
		if length > 0 and walked + length >= distance then
			local t = (distance - walked) / length
			return a:Lerp(b, t), flat.Unit
		end
		walked += length
	end
	local last = points[#points]
	local before = points[math.max(1, #points - 1)]
	local flat = Vector3.new(last.X - before.X, 0, last.Z - before.Z)
	return last, if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis
end

local function park(part: BasePart)
	if part.CFrame ~= parked then
		part.CFrame = parked
	end
end

function Guide.DrawPath(guide: Guide, points: { Vector3 }, dt: number)
	local total = lengthOf(points)
	local spacing = TutorialConfig.ChevronSpacing
	guide.Scroll = (guide.Scroll + dt * TutorialConfig.ChevronScrollSpeed) % spacing
	local stop = total - TutorialConfig.ChevronStopDistance
	local distance = TutorialConfig.ChevronStartDistance + guide.Scroll
	local yaw = CFrame.Angles(0, math.rad(TutorialConfig.ChevronYawDegrees), 0)
	for _, chevron in guide.Chevrons do
		if distance > stop then
			park(chevron)
			continue
		end
		local position, direction = sample(points, distance)
		local ground = groundAt(guide, position) + Vector3.new(0, TutorialConfig.ChevronHeight, 0)
		local edge = math.min(distance, stop - distance)
		local scale = TutorialConfig.ChevronEndScale
			+ (1 - TutorialConfig.ChevronEndScale) * math.clamp(edge / (spacing * 2), 0, 1)
		local size = TutorialConfig.ChevronSize
		chevron.Size = Vector3.new(size.X * scale, size.Y, size.Z * scale)
		chevron.CFrame = CFrame.lookAt(ground, ground + direction) * yaw
		distance += spacing
	end
end

function Guide.HidePath(guide: Guide)
	for _, chevron in guide.Chevrons do
		park(chevron)
	end
end

function Guide.DrawMarker(guide: Guide, position: Vector3, adornee: Instance, text: string, dt: number)
	guide.Clock += dt
	local bob = math.sin(guide.Clock * TutorialConfig.MarkerBobSpeed) * TutorialConfig.MarkerBobStuds
	guide.Anchor.CFrame = CFrame.new(position + Vector3.new(0, TutorialConfig.MarkerHeight + bob, 0))
	guide.Marker.Enabled = true

	local highlight = guide.Highlight
	if highlight.Adornee ~= adornee then
		highlight.Adornee = adornee
	end
	highlight.Enabled = true
	local pulse = (math.sin(guide.Clock * TutorialConfig.HighlightPulseSpeed) + 1) / 2
	highlight.FillTransparency = TutorialConfig.HighlightFillMin
		+ (TutorialConfig.HighlightFillMax - TutorialConfig.HighlightFillMin) * pulse

	local label = guide.Label
	if label then
		if label.Adornee ~= guide.Anchor then
			label.Adornee = guide.Anchor
		end
		label.StudsOffsetWorldSpace = Vector3.new(0, TutorialConfig.MarkerSize * 0.6, 0)
		label.Enabled = true
		if guide.NameLabel and guide.NameLabel.Text ~= text then
			guide.NameLabel.Text = text
		end
	end
end

function Guide.HideMarker(guide: Guide)
	park(guide.Anchor)
	guide.Marker.Enabled = false
	guide.Highlight.Enabled = false
	guide.Highlight.Adornee = nil
	if guide.Label then
		guide.Label.Enabled = false
	end
end

function Guide.Destroy(guide: Guide)
	guide.Folder:Destroy()
	guide.Marker:Destroy()
	if guide.Label then
		guide.Label:Destroy()
	end
end

return Guide
