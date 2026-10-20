--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingMinigameConfig = require(ReplicatedStorage.Config.TrainingMinigameConfig)

export type Trail = {
	Gui: GuiObject,
	StartTransparency: number,
	Age: number,
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

function Swipe.CreateTrail(template: GuiObject, parent: GuiObject, from: Vector2, to: Vector2): Trail
	local segment = to - from
	local middle = (from + to) / 2
	local gui = template:Clone()
	gui.Name = "Trail"
	gui.AnchorPoint = Vector2.new(0.5, 0.5)
	gui.Position = UDim2.fromOffset(middle.X, middle.Y)
	gui.Size = UDim2.fromOffset(
		segment.Magnitude + TrainingMinigameConfig.TrailThicknessPixels,
		TrainingMinigameConfig.TrailThicknessPixels
	)
	gui.Rotation = math.deg(math.atan2(segment.Y, segment.X))
	gui.Visible = true
	gui.Parent = parent
	return { Gui = gui, StartTransparency = gui.BackgroundTransparency, Age = 0 }
end

function Swipe.UpdateTrail(trail: Trail, dt: number): boolean
	trail.Age += dt
	local progress = trail.Age / TrainingMinigameConfig.TrailLifetimeSeconds
	if progress >= 1 then
		return false
	end
	trail.Gui.BackgroundTransparency = trail.StartTransparency + (1 - trail.StartTransparency) * progress
	return true
end

return Swipe
