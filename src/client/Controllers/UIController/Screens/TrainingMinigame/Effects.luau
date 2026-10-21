--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingMinigameConfig = require(ReplicatedStorage.Config.TrainingMinigameConfig)

export type Effect = {
	Gui: GuiObject,
	Age: number,
	Lifetime: number,
	Position: Vector2,
	Velocity: Vector2,
	Gravity: number,
	StartSize: Vector2,
	EndSize: Vector2,
	SpinDegreesPerSecond: number,
}

local Effects = {}

local function make(
	template: GuiObject,
	parent: GuiObject,
	position: Vector2,
	lifetime: number,
	startSize: Vector2,
	endSize: Vector2
): Effect
	local gui = template:Clone()
	gui.AnchorPoint = Vector2.new(0.5, 0.5)
	gui.Position = UDim2.fromOffset(position.X, position.Y)
	gui.Size = UDim2.fromOffset(startSize.X, startSize.Y)
	gui.Visible = true
	gui.Parent = parent
	return {
		Gui = gui,
		Age = 0,
		Lifetime = lifetime,
		Position = position,
		Velocity = Vector2.zero,
		Gravity = 0,
		StartSize = startSize,
		EndSize = endSize,
		SpinDegreesPerSecond = 0,
	}
end

local function tint(gui: GuiObject, color: Color3)
	gui.BackgroundColor3 = color
	for _, child in gui:GetDescendants() do
		if child:IsA("GuiObject") and child:GetAttribute("Tinted") == true then
			child.BackgroundColor3 = color
		end
	end
end

function Effects.Slash(
	template: GuiObject,
	parent: GuiObject,
	center: Vector2,
	direction: Vector2,
	color: Color3
): Effect
	local length = TrainingMinigameConfig.SlashLengthPixels
	local thickness = TrainingMinigameConfig.SlashThicknessPixels
	local effect = make(
		template,
		parent,
		center,
		TrainingMinigameConfig.SlashSeconds,
		Vector2.new(length * 0.35, thickness),
		Vector2.new(length, thickness * 0.15)
	)
	tint(effect.Gui, color)
	effect.Gui.Rotation = if direction.Magnitude > 0
		then math.deg(math.atan2(direction.Y, direction.X))
		else 0
	return effect
end

function Effects.Shards(template: GuiObject, parent: GuiObject, center: Vector2, color: Color3): { Effect }
	local shards: { Effect } = {}
	local size = TrainingMinigameConfig.ShardSizePixels
	for index = 1, TrainingMinigameConfig.ShardCount do
		local angle = (index / TrainingMinigameConfig.ShardCount) * math.pi * 2 + math.random() * 0.6
		local speed = TrainingMinigameConfig.ShardSpeedPixelsPerSecond * (0.6 + math.random() * 0.6)
		local effect = make(
			template,
			parent,
			center,
			TrainingMinigameConfig.ShardSeconds,
			Vector2.new(size, size),
			Vector2.new(size * 0.3, size * 0.3)
		)
		tint(effect.Gui, color)
		effect.Velocity = Vector2.new(math.cos(angle), math.sin(angle)) * speed
		effect.Gravity = TrainingMinigameConfig.HalfGravityPixelsPerSecond * 0.5
		effect.SpinDegreesPerSecond = (math.random() - 0.5) * 720
		table.insert(shards, effect)
	end
	return shards
end

function Effects.Gain(template: GuiObject, parent: GuiObject, center: Vector2, text: string): Effect
	local size = template.AbsoluteSize
	local startSize = if size.Magnitude > 0 then size else Vector2.new(220, 56)
	local effect =
		make(template, parent, center, TrainingMinigameConfig.GainSeconds, startSize * 0.7, startSize)
	if effect.Gui:IsA("TextLabel") then
		effect.Gui.Text = text
	end
	effect.Velocity =
		Vector2.new(0, -TrainingMinigameConfig.GainRisePixels / TrainingMinigameConfig.GainSeconds)
	return effect
end

local function fade(gui: GuiObject, alpha: number)
	if gui:IsA("TextLabel") then
		gui.TextTransparency = alpha
		for _, child in gui:GetChildren() do
			if child:IsA("UIStroke") then
				child.Transparency = alpha
			end
		end
	else
		gui.BackgroundTransparency = alpha
		for _, child in gui:GetDescendants() do
			if child:IsA("GuiObject") then
				child.BackgroundTransparency = math.max(child.BackgroundTransparency, alpha)
			end
		end
	end
end

function Effects.Update(effect: Effect, dt: number): boolean
	effect.Age += dt
	local progress = effect.Age / effect.Lifetime
	if progress >= 1 then
		return false
	end
	effect.Velocity += Vector2.new(0, effect.Gravity * dt)
	effect.Position += effect.Velocity * dt
	local size = effect.StartSize:Lerp(effect.EndSize, progress)
	effect.Gui.Position = UDim2.fromOffset(effect.Position.X, effect.Position.Y)
	effect.Gui.Size = UDim2.fromOffset(size.X, size.Y)
	effect.Gui.Rotation += effect.SpinDegreesPerSecond * dt
	fade(effect.Gui, progress * progress)
	return true
end

return Effects
