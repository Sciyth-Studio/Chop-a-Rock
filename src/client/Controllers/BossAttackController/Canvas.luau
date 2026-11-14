--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossFxConfig = require(ReplicatedStorage.Config.BossFxConfig)

export type Canvas = {
	Anchor: Part,
	Gui: SurfaceGui,
	Danger: CanvasGroup,
	Overlay: Frame,
	Center: Vector3,
	Size: number,
	PixelsPerStud: number,
}

local spec = BossFxConfig.Canvas

local Canvas = {}

Canvas.Facing = CFrame.Angles(0, -math.pi / 2, 0)

local function anchorPart(name: string, size: Vector3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function surface(parent: Part, pixelsPerStud: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud
	gui.LightInfluence = 0
	gui.Brightness = spec.Brightness
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Adornee = parent
	gui.Parent = parent
	return gui
end

function Canvas.New(folder: Instance, center: Vector3, half: number, lift: number): Canvas
	local size = half * 2
	local pixelsPerStud = math.min(spec.PixelsPerStud, spec.MaxPixels / size)
	local anchor = anchorPart(
		"AttackCanvas",
		Vector3.new(size, spec.AnchorThicknessStuds, size),
		CFrame.new(center.X, center.Y + lift, center.Z) * Canvas.Facing
	)
	local gui = surface(anchor, pixelsPerStud)
	local danger = Instance.new("CanvasGroup")
	danger.Name = "Danger"
	danger.BackgroundTransparency = 1
	danger.Size = UDim2.fromScale(1, 1)
	danger.ZIndex = 1
	danger.Parent = gui
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 2
	overlay.Parent = gui
	anchor.Parent = folder
	return {
		Anchor = anchor,
		Gui = gui,
		Danger = danger,
		Overlay = overlay,
		Center = center,
		Size = size,
		PixelsPerStud = pixelsPerStud,
	}
end

function Canvas.Point(canvas: Canvas, position: Vector3): UDim2
	local x = (position.X - canvas.Center.X) / canvas.Size + 0.5
	local z = (position.Z - canvas.Center.Z) / canvas.Size
	return UDim2.fromScale(x, (if spec.FlipZ then -z else z) + 0.5)
end

function Canvas.Rotation(angle: number): number
	local degrees = math.deg(angle)
	return if spec.FlipZ then -degrees else degrees
end

local function frame(color: Color3, transparency: number, parent: Instance): Frame
	local item = Instance.new("Frame")
	item.BorderSizePixel = 0
	item.BackgroundColor3 = color
	item.BackgroundTransparency = transparency
	item.AnchorPoint = Vector2.new(0.5, 0.5)
	item.Parent = parent
	return item
end

local function image(texture: string, color: Color3, transparency: number, parent: Instance): ImageLabel
	local item = Instance.new("ImageLabel")
	item.BackgroundTransparency = 1
	item.Image = texture
	item.ImageColor3 = color
	item.ImageTransparency = transparency
	item.AnchorPoint = Vector2.new(0.5, 0.5)
	item.Parent = parent
	return item
end

function Canvas.Disc(
	canvas: Canvas,
	parent: GuiObject,
	center: Vector3,
	radius: number,
	color: Color3,
	transparency: number,
	texture: string?,
	strokeColor: Color3?,
	strokeStuds: number?
): GuiObject
	local item: GuiObject
	if texture and texture ~= "" then
		item = image(texture, color, transparency, parent)
	else
		local disc = frame(color, transparency, parent)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = disc
		if strokeColor and strokeStuds then
			local stroke = Instance.new("UIStroke")
			stroke.Color = strokeColor
			stroke.Thickness = strokeStuds * canvas.PixelsPerStud
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = disc
		end
		item = disc
	end
	item.Position = Canvas.Point(canvas, center)
	Canvas.SetRadius(canvas, item, radius)
	return item
end

function Canvas.SetRadius(canvas: Canvas, item: GuiObject, radius: number)
	local scale = radius * 2 / canvas.Size
	item.Size = UDim2.fromScale(scale, scale)
end

function Canvas.Strip(
	canvas: Canvas,
	parent: GuiObject,
	from: Vector3,
	to: Vector3,
	width: number,
	color: Color3,
	transparency: number,
	texture: string?
): GuiObject
	local item: GuiObject = if texture and texture ~= ""
		then image(texture, color, transparency, parent)
		else frame(color, transparency, parent)
	Canvas.PlaceStrip(canvas, item, from, to, width)
	return item
end

function Canvas.PlaceStrip(canvas: Canvas, item: GuiObject, from: Vector3, to: Vector3, width: number)
	local line = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	item.Position = Canvas.Point(canvas, (from + to) / 2)
	item.Size = UDim2.fromScale(line.Magnitude / canvas.Size, width / canvas.Size)
	item.Rotation = Canvas.Rotation(math.atan2(line.Z, line.X))
end

function Canvas.Square(
	_canvas: Canvas,
	parent: GuiObject,
	color: Color3,
	transparency: number,
	texture: string?
): GuiObject
	local item: GuiObject = if texture and texture ~= ""
		then image(texture, color, transparency, parent)
		else frame(color, transparency, parent)
	item.Position = UDim2.fromScale(0.5, 0.5)
	item.Size = UDim2.fromScale(1, 1)
	return item
end

function Canvas.Arc(
	canvas: Canvas,
	parent: GuiObject,
	center: Vector3,
	radius: number,
	from: number,
	to: number,
	width: number,
	color: Color3,
	transparency: number,
	segmentStuds: number
)
	local span = to - from
	local segments = math.max(1, math.ceil(math.abs(span) * radius / segmentStuds))
	local length = math.abs(span) * radius / segments * 1.08
	for index = 1, segments do
		local angle = from + (index - 0.5) / segments * span
		local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
		local item = frame(color, transparency, parent)
		item.Position = Canvas.Point(canvas, position)
		item.Size = UDim2.fromScale(width / canvas.Size, length / canvas.Size)
		item.Rotation = Canvas.Rotation(angle)
	end
end

function Canvas.Fan(
	canvas: Canvas,
	parent: GuiObject,
	origin: Vector3,
	angle: number,
	span: number,
	inner: number,
	reach: number,
	chordStuds: number,
	color: Color3,
	transparency: number,
	texture: string?
)
	if texture and texture ~= "" then
		local item = image(texture, color, transparency, parent)
		item.Position = Canvas.Point(canvas, origin)
		Canvas.SetRadius(canvas, item, reach)
		item.Rotation = Canvas.Rotation(angle)
		return
	end
	local count = math.max(1, math.ceil(span * reach / chordStuds))
	local step = span / count
	local chord = 2 * reach * math.sin(step / 2) * 1.05
	local from = angle - span / 2
	for index = 1, count do
		local sliceAngle = from + (index - 0.5) * step
		local direction = Vector3.new(math.cos(sliceAngle), 0, math.sin(sliceAngle))
		Canvas.Strip(
			canvas,
			parent,
			origin + direction * inner,
			origin + direction * reach,
			chord,
			color,
			transparency
		)
	end
end

function Canvas.Marker(folder: Instance, sizeStuds: number, color: Color3, texture: string): Part
	local anchor = anchorPart(
		"AttackArrow",
		Vector3.new(sizeStuds, spec.AnchorThicknessStuds, sizeStuds),
		CFrame.new(0, -500, 0)
	)
	local gui = surface(anchor, spec.MarkerPixelsPerStud)
	if texture ~= "" then
		local item = image(texture, color, 0, gui)
		item.Position = UDim2.fromScale(0.5, 0.5)
		item.Size = UDim2.fromScale(1, 1)
		item.Rotation = if spec.FlipZ then 180 else 0
	else
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(1, 1)
		holder.Rotation = if spec.FlipZ then 180 else 0
		holder.Parent = gui
		for _, side in { -1, 1 } do
			local bar = frame(color, 0, holder)
			bar.Size = UDim2.fromScale(0.62, 0.2)
			bar.Position = UDim2.fromScale(0.5 + side * 0.18, 0.45)
			bar.Rotation = side * 45
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = bar
		end
	end
	anchor.Parent = folder
	return anchor
end

return Canvas
