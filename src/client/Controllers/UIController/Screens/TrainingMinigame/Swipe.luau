--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingMinigameConfig = require(ReplicatedStorage.Config.TrainingMinigameConfig)

export type Point = {
	Position: Vector2,
	Clock: number,
}

export type Trail = {
	Points: { Point },
	Glow: { GuiObject },
	Core: { GuiObject },
	IsActive: boolean,
}

local Swipe = {}

function Swipe.DistanceToSegment(point: Vector2, from: Vector2, to: Vector2): number
	local segment = to - from
	local lengthSquared = segment:Dot(segment)
	if lengthSquared == 0 then
		return (point - from).Magnitude
	end
	local along = math.clamp((point - from):Dot(segment) / lengthSquared, 0, 1)
	return (point - (from + segment * along)).Magnitude
end

function Swipe.NewTrail(start: Vector2, now: number): Trail
	return { Points = { { Position = start, Clock = now } }, Glow = {}, Core = {}, IsActive = true }
end

function Swipe.AddPoint(trail: Trail, position: Vector2, now: number)
	table.insert(trail.Points, { Position = position, Clock = now })
	while #trail.Points > TrainingMinigameConfig.TrailMaxPoints do
		table.remove(trail.Points, 1)
	end
end

local function segment(
	pool: { GuiObject },
	index: number,
	template: GuiObject,
	parent: GuiObject,
	zIndex: number
): GuiObject
	local existing: GuiObject? = pool[index]
	if existing then
		return existing
	end
	local created = template:Clone()
	created.Name = "TrailSegment"
	created.AnchorPoint = Vector2.new(0.5, 0.5)
	created.ZIndex = zIndex
	created.Parent = parent
	pool[index] = created
	return created
end

local function place(gui: GuiObject, from: Vector2, to: Vector2, thickness: number, transparency: number)
	local offset = to - from
	local middle = (from + to) / 2
	gui.Visible = true
	gui.Position = UDim2.fromOffset(middle.X, middle.Y)
	gui.Size = UDim2.fromOffset(offset.Magnitude + thickness * 0.5, thickness)
	gui.Rotation = math.deg(math.atan2(offset.Y, offset.X))
	gui.BackgroundTransparency = transparency
end

function Swipe.Render(
	trail: Trail,
	template: GuiObject,
	parent: GuiObject,
	now: number,
	color: Color3
): boolean
	local lifetime = TrainingMinigameConfig.TrailLifetimeSeconds
	while #trail.Points > 0 and now - trail.Points[1].Clock > lifetime do
		table.remove(trail.Points, 1)
	end
	local used = 0
	for index = 2, #trail.Points do
		local from = trail.Points[index - 1]
		local to = trail.Points[index]
		local strength = 1 - math.clamp((now - to.Clock) / lifetime, 0, 1)
		if strength <= 0 then
			continue
		end
		used += 1
		local glow = segment(trail.Glow, used, template, parent, template.ZIndex)
		glow.BackgroundColor3 = color
		place(
			glow,
			from.Position,
			to.Position,
			TrainingMinigameConfig.TrailGlowThicknessPixels * strength,
			1 - (1 - TrainingMinigameConfig.TrailGlowTransparency) * strength
		)
		local core = segment(trail.Core, used, template, parent, template.ZIndex + 1)
		core.BackgroundColor3 = Color3.new(1, 1, 1)
		place(
			core,
			from.Position,
			to.Position,
			TrainingMinigameConfig.TrailCoreThicknessPixels * strength,
			1 - (1 - TrainingMinigameConfig.TrailCoreTransparency) * strength
		)
	end
	for _, pool in { trail.Glow, trail.Core } do
		for index = used + 1, #pool do
			pool[index].Visible = false
		end
	end
	return trail.IsActive or #trail.Points > 1
end

function Swipe.Destroy(trail: Trail)
	for _, pool in { trail.Glow, trail.Core } do
		for _, gui in pool do
			gui:Destroy()
		end
		table.clear(pool)
	end
end

return Swipe
