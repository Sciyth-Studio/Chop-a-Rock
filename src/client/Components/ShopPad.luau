--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local ShopPadConfig = require(ReplicatedStorage.Config.ShopPadConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type ShopPad = {
	Instance: Instance,
	Trove: any,
	Beams: { Beam },
	Screen: string?,
	ScreenKey: string?,
	IsInside: boolean,
	Clock: number,
	Prompt: ProximityPrompt?,
}

local function wallTransparency(phase: number): NumberSequence
	local bottom = ShopPadConfig.WallBottomTransparency
	local halfWidth = ShopPadConfig.BandWidth / 2
	local centers: { number } = {}
	for index = 0, ShopPadConfig.BandCount - 1 do
		table.insert(centers, (phase + index / ShopPadConfig.BandCount) % 1)
	end

	local function valueAt(height: number): number
		local value = bottom + (1 - bottom) * height
		for _, center in centers do
			local distance = math.abs(height - center)
			if distance < halfWidth then
				local peak = ShopPadConfig.BandTransparency + (1 - ShopPadConfig.BandTransparency) * center
				local band = peak + (value - peak) * (distance / halfWidth)
				value = math.min(value, band)
			end
		end
		return math.clamp(value, 0, 1)
	end

	local times = { 0, 1 }
	for _, center in centers do
		for _, time in { center - halfWidth, center, center + halfWidth } do
			if time > 0.001 and time < 0.999 then
				table.insert(times, time)
			end
		end
	end
	table.sort(times)

	local keypoints: { NumberSequenceKeypoint } = {}
	local previous = -1
	for _, time in times do
		if time - previous >= 0.001 then
			table.insert(keypoints, NumberSequenceKeypoint.new(time, valueAt(time)))
			previous = time
		end
	end
	return NumberSequence.new(keypoints)
end

local function buildWall(self: ShopPad, part: BasePart)
	local halfX = part.Size.X / 2
	local halfZ = part.Size.Z / 2
	local top = Vector3.new(0, ShopPadConfig.WallHeight, 0)
	local sides = {
		{ Outward = Vector3.xAxis, Distance = halfX, Width = part.Size.Z },
		{ Outward = -Vector3.xAxis, Distance = halfX, Width = part.Size.Z },
		{ Outward = Vector3.zAxis, Distance = halfZ, Width = part.Size.X },
		{ Outward = -Vector3.zAxis, Distance = halfZ, Width = part.Size.X },
	}
	for _, side in sides do
		local outward = part.CFrame:VectorToWorldSpace(side.Outward)
		local tangent = Vector3.yAxis:Cross(outward)
		local position = part.Position + outward * side.Distance
		local bottomAttachment = self.Trove:Add(Instance.new("Attachment"))
		bottomAttachment.Parent = part
		bottomAttachment.WorldCFrame = CFrame.fromMatrix(position, outward, tangent)
		local topAttachment = self.Trove:Add(Instance.new("Attachment"))
		topAttachment.Parent = part
		topAttachment.WorldCFrame = CFrame.fromMatrix(position + top, outward, tangent)
		local width = side.Width
		local beam = self.Trove:Add(Instance.new("Beam"))
		beam.Attachment0 = bottomAttachment
		beam.Attachment1 = topAttachment
		beam.FaceCamera = false
		beam.Segments = 1
		beam.Texture = ""
		beam.Width0 = width
		beam.Width1 = width
		beam.Color = ColorSequence.new(part.Color)
		beam.LightEmission = ShopPadConfig.WallLightEmission
		beam.Transparency = wallTransparency(0)
		beam.Parent = part
		table.insert(self.Beams, beam)
	end
end

local function buildPrompt(self: ShopPad, part: BasePart, onTriggered: () -> ())
	local anchor = self.Trove:Add(Instance.new("Attachment"))
	anchor.Parent = part
	anchor.WorldPosition = part.Position + Vector3.new(0, ShopPadConfig.PromptHeightStuds, 0)
	local shopName = part:GetAttribute("ShopName")
	local prompt = self.Trove:Add(Instance.new("ProximityPrompt"))
	prompt.ActionText = "Open"
	prompt.ObjectText = if type(shopName) == "string" then shopName else ""
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = ShopPadConfig.PromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = anchor
	self.Trove:Connect(prompt.Triggered, onTriggered)
	self.Prompt = prompt
end

local function isCharacterInside(self: ShopPad, part: BasePart): boolean
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local offset = part.CFrame:PointToObjectSpace(root.Position)
	if offset.Y < 0 or offset.Y > ShopPadConfig.EnterHeightStuds then
		return false
	end
	local padding = if self.IsInside then ShopPadConfig.ExitPaddingStuds else 0
	return math.abs(offset.X) <= part.Size.X / 2 + padding and math.abs(offset.Z) <= part.Size.Z / 2 + padding
end

return function(controllers: { [string]: any })
	local ShopPad = Component.new({ Tag = "ShopPad" }) :: any

	function ShopPad.Construct(self: ShopPad)
		local screen = self.Instance:GetAttribute("Screen")
		local screenKey = self.Instance:GetAttribute("ScreenKey")
		self.Trove = Trove.new()
		self.Beams = {}
		self.Screen = if type(screen) == "string" then screen else nil
		self.ScreenKey = if type(screenKey) == "string" then screenKey else nil
		self.IsInside = false
		self.Clock = 0
		self.Prompt = nil
	end

	function ShopPad.Start(self: ShopPad)
		local part = self.Instance
		if not part:IsA("BasePart") or not self.Screen then
			warn(`[ShopPad] Needs a BasePart with a Screen attribute: {part:GetFullName()}`)
			return
		end
		buildWall(self, part)
		buildPrompt(self, part, function()
			if self.Screen then
				controllers.UIController:Open(self.Screen, self.ScreenKey)
			end
		end)
	end

	function ShopPad.RenderSteppedUpdate(self: ShopPad, dt: number)
		local part = self.Instance
		local screen = self.Screen
		if not part:IsA("BasePart") or not screen or #self.Beams == 0 then
			return
		end
		self.Clock += dt
		local transparency = wallTransparency((self.Clock / ShopPadConfig.BandSeconds) % 1)
		for _, beam in self.Beams do
			beam.Transparency = transparency
		end

		local uiController = controllers.UIController
		local isInside = isCharacterInside(self, part)
		if isInside ~= self.IsInside then
			self.IsInside = isInside
			if isInside then
				uiController:Open(screen, self.ScreenKey)
			elseif uiController:IsOpen(screen) then
				uiController:Close(screen)
			end
		end

		local prompt = self.Prompt
		if prompt then
			local shouldShow = isInside and not uiController:IsOpen(screen)
			if prompt.Enabled ~= shouldShow then
				prompt.Enabled = shouldShow
			end
		end
	end

	function ShopPad.Stop(self: ShopPad)
		self.Trove:Destroy()
		table.clear(self.Beams)
	end

	return ShopPad
end
