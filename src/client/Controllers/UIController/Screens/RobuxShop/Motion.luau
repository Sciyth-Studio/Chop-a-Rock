--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)

local motion = RobuxShopConfig.Motion

export type Sparkle = { Image: ImageLabel, Phase: number, Cycle: number }

export type State = {
	Stripes: { ImageLabel },
	Sparkles: { Sparkle },
	Random: Random,
}

local Motion = {}

function Motion.New(): State
	return { Stripes = {}, Sparkles = {}, Random = Random.new() }
end

function Motion.AddCard(state: State, card: Frame, hasSparkles: boolean)
	local clip = card:FindFirstChild("ShineClip")
	local stripes = if clip then clip:FindFirstChild("Stripes") else nil
	if stripes and stripes:IsA("ImageLabel") then
		stripes.Size = UDim2.new(1, motion.StripeTilePixels, 1, motion.StripeTilePixels)
		table.insert(state.Stripes, stripes)
	end
	if hasSparkles and clip then
		for index = 1, motion.SparklesPerCard do
			local image = Instance.new("ImageLabel")
			image.Name = "Sparkle"
			image.BackgroundTransparency = 1
			image.Image = RobuxShopConfig.Textures.Sparkle
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Size = UDim2.fromOffset(motion.SparkleSizePixels, motion.SparkleSizePixels)
			image.ImageTransparency = 1
			image.ZIndex = 8
			image.Parent = clip
			table.insert(state.Sparkles, {
				Image = image,
				Phase = (index - 1) / motion.SparklesPerCard + state.Random:NextNumber() * 0.2,
				Cycle = -1,
			})
		end
	end
end

function Motion.Step(state: State, now: number)
	local isLow = LowGraphics.IsOn()
	local shift = if isLow then 0 else (now * motion.StripeScrollPixelsPerSecond) % motion.StripeTilePixels
	for _, stripes in state.Stripes do
		stripes.Position = UDim2.fromOffset(-shift, -shift)
	end
	for _, sparkle in state.Sparkles do
		if isLow then
			sparkle.Image.ImageTransparency = 1
			continue
		end
		local progress = now / motion.SparkleSeconds + sparkle.Phase
		local cycle = math.floor(progress)
		if cycle ~= sparkle.Cycle then
			sparkle.Cycle = cycle
			sparkle.Image.Position = UDim2.fromScale(
				0.08 + state.Random:NextNumber() * 0.84,
				0.1 + state.Random:NextNumber() * 0.8
			)
			sparkle.Image.Rotation = state.Random:NextNumber() * 45
		end
		local wave = math.sin((progress - cycle) * math.pi)
		sparkle.Image.ImageTransparency = 1 - wave
		local size = motion.SparkleSizePixels * (0.4 + 0.6 * wave)
		sparkle.Image.Size = UDim2.fromOffset(size, size)
	end
end

return Motion
