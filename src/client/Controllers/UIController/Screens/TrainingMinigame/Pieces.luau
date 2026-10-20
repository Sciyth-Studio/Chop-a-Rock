--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingMinigameConfig = require(ReplicatedStorage.Config.TrainingMinigameConfig)

export type Piece = {
	Id: number,
	Kind: number,
	Gui: GuiObject,
	LaunchClock: number,
	StartX: number,
	Drift: number,
	Apex: number,
	SpinDirection: number,
	Center: Vector2,
	Radius: number,
	IsFlying: boolean,
}

export type Half = {
	Gui: GuiObject,
	Position: Vector2,
	Velocity: Vector2,
	SpinDegreesPerSecond: number,
	Age: number,
}

local Pieces = {}

function Pieces.Create(
	template: GuiObject,
	parent: GuiObject,
	id: number,
	kind: number,
	color: Color3,
	launchClock: number,
	startX: number,
	drift: number,
	apex: number
): Piece
	local shortSide = math.min(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
	local isBomb = kind == TrainingMinigameConfig.BombKind
	local width = shortSide
		* (
			if isBomb
				then TrainingMinigameConfig.BombSizeShortSide
				else TrainingMinigameConfig.PieceSizeShortSide
		)
	local height = if isBomb then width else width * TrainingMinigameConfig.PieceAspect
	local gui = template:Clone()
	gui.Name = `Piece{id}`
	gui.AnchorPoint = Vector2.new(0.5, 0.5)
	gui.Size = UDim2.fromOffset(width, height)
	gui.Visible = false
	if not isBomb then
		for _, child in gui:GetChildren() do
			if child:IsA("GuiObject") and child:GetAttribute("Tinted") == true then
				child.BackgroundColor3 = color
			end
		end
	end
	gui.Parent = parent
	return {
		Id = id,
		Kind = kind,
		Gui = gui,
		LaunchClock = launchClock,
		StartX = startX,
		Drift = drift,
		Apex = apex,
		SpinDirection = if math.random() < 0.5 then -1 else 1,
		Center = Vector2.zero,
		Radius = math.max(width, height) * 0.5 * TrainingMinigameConfig.HitRadiusScale,
		IsFlying = false,
	}
end

function Pieces.Update(piece: Piece, now: number, area: Vector2): boolean
	local elapsed = now - piece.LaunchClock
	local progress = elapsed / TrainingMinigameConfig.FlightSeconds
	if progress < 0 then
		piece.IsFlying = false
		piece.Gui.Visible = false
		return true
	end
	if progress > 1 then
		return false
	end
	local margin = piece.Gui.AbsoluteSize.Y
	local x = (piece.StartX + piece.Drift * progress) * area.X
	local rise = (piece.Apex * area.Y + margin) * 4 * progress * (1 - progress)
	local y = area.Y + margin - rise
	piece.Center = Vector2.new(x, y)
	piece.IsFlying = true
	piece.Gui.Visible = true
	piece.Gui.Position = UDim2.fromOffset(x, y)
	piece.Gui.Rotation = elapsed * TrainingMinigameConfig.SpinDegreesPerSecond * piece.SpinDirection
	return true
end

function Pieces.Split(piece: Piece, parent: GuiObject): { Half }
	local halves: { Half } = {}
	local angle = math.rad(piece.Gui.Rotation)
	local along = Vector2.new(math.cos(angle), math.sin(angle))
	for index, keep in { "HalfLeft", "HalfRight" } do
		local gui = piece.Gui:Clone()
		for _, child in gui:GetChildren() do
			if child:IsA("GuiObject") and (child.Name == "HalfLeft" or child.Name == "HalfRight") then
				child.Visible = child.Name == keep
			end
		end
		gui.Name = `{piece.Gui.Name}{keep}`
		gui.Parent = parent
		local side = if index == 1 then -1 else 1
		table.insert(halves, {
			Gui = gui,
			Position = piece.Center,
			Velocity = along * side * TrainingMinigameConfig.HalfSpreadPixelsPerSecond
				- Vector2.new(0, TrainingMinigameConfig.HalfSpreadPixelsPerSecond),
			SpinDegreesPerSecond = TrainingMinigameConfig.SpinDegreesPerSecond * side * 2,
			Age = 0,
		})
	end
	return halves
end

function Pieces.UpdateHalf(half: Half, dt: number): boolean
	half.Age += dt
	if half.Age > TrainingMinigameConfig.HalfLifetimeSeconds then
		return false
	end
	half.Velocity += Vector2.new(0, TrainingMinigameConfig.HalfGravityPixelsPerSecond * dt)
	half.Position += half.Velocity * dt
	half.Gui.Position = UDim2.fromOffset(half.Position.X, half.Position.Y)
	half.Gui.Rotation += half.SpinDegreesPerSecond * dt
	return true
end

return Pieces
