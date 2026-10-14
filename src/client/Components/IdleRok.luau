--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local RokMotionConfig = require(ReplicatedStorage.Config.RokMotionConfig)

type PartState = {
	Part: BasePart,
	Offset: CFrame,
	Size: Vector3,
	IsEye: boolean,
}

type IdleRok = {
	Instance: Instance,
	Base: CFrame,
	Parts: { PartState },
	Phase: number,
	BlinkStart: number,
	NextBlink: number,
	LandStart: number?,
	IsResting: boolean,
}

local random = Random.new()

local function isEye(name: string): boolean
	for _, suffix in RokMotionConfig.EyePartSuffixes do
		if string.sub(name, -#suffix) == suffix then
			return true
		end
	end
	return false
end

local function blinkInterval(): number
	return random:NextNumber(RokMotionConfig.BlinkIntervalMinSeconds, RokMotionConfig.BlinkIntervalMaxSeconds)
end

local function apply(self: IdleRok, lift: number, scaleY: number, blink: number)
	local scaleXZ = 1 / math.sqrt(scaleY)
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	for index, state in self.Parts do
		local offset = state.Offset.Position
		local sizeY = state.Size.Y * scaleY * (if state.IsEye then blink else 1)
		local size = Vector3.new(state.Size.X * scaleXZ, sizeY, state.Size.Z * scaleXZ)
		if state.Part.Size ~= size then
			state.Part.Size = size
		end
		parts[index] = state.Part
		cframes[index] = self.Base
			* CFrame.new(offset.X * scaleXZ, offset.Y * scaleY + lift, offset.Z * scaleXZ)
			* state.Offset.Rotation
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	self.IsResting = lift == 0 and scaleY == 1 and blink == 1
end

local function blinkScale(self: IdleRok, now: number): number
	local progress = (now - self.BlinkStart) / RokMotionConfig.BlinkSeconds
	if progress >= 1 then
		if now < self.NextBlink then
			return 1
		end
		self.BlinkStart = now
		self.NextBlink = now + RokMotionConfig.BlinkSeconds + blinkInterval()
		progress = 0
	end
	return 1 - (1 - RokMotionConfig.BlinkClosedScale) * math.sin(math.pi * progress)
end

local function landing(self: IdleRok, now: number): (number, number)
	local landStart = self.LandStart
	if not landStart then
		return 0, 0
	end
	local elapsed = now - landStart
	if elapsed < RokMotionConfig.DropSeconds then
		local progress = elapsed / RokMotionConfig.DropSeconds
		return RokMotionConfig.DropHeightStuds * (1 - progress * progress), RokMotionConfig.DropStretch
	end
	local progress = (elapsed - RokMotionConfig.DropSeconds) / RokMotionConfig.LandSeconds
	if progress >= 1 then
		self.LandStart = nil
		return 0, 0
	end
	local envelope = (1 - progress) * (1 - progress)
	return 0,
		-RokMotionConfig.LandSquash * envelope * math.cos(
			2 * math.pi * RokMotionConfig.LandBounces * progress
		)
end

return function(_controllers: { [string]: any })
	local IdleRok = Component.new({ Tag = RokMotionConfig.Tag }) :: any

	function IdleRok.Construct(self: IdleRok)
		self.Parts = {}
		self.Phase = random:NextNumber(0, 2 * math.pi)
		self.BlinkStart = -math.huge
		self.NextBlink = os.clock() + blinkInterval()
		self.IsResting = true
	end

	function IdleRok.Start(self: IdleRok)
		local model = self.Instance
		if not model:IsA("Model") then
			return
		end
		self.Base = model:GetPivot()
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(self.Parts, {
					Part = descendant,
					Offset = self.Base:ToObjectSpace(descendant.CFrame),
					Size = descendant.Size,
					IsEye = isEye(descendant.Name),
				})
			end
		end
		local placedAt = model:GetAttribute(RokMotionConfig.PlacedAtAttribute)
		if type(placedAt) == "number" then
			local age = workspace:GetServerTimeNow() - placedAt
			if age >= 0 and age < RokMotionConfig.LandWindowSeconds then
				self.LandStart = os.clock() - age
			end
		end
	end

	function IdleRok.RenderSteppedUpdate(self: IdleRok, _dt: number)
		if #self.Parts == 0 then
			return
		end
		local camera = workspace.CurrentCamera
		if
			not camera
			or (camera.CFrame.Position - self.Base.Position).Magnitude > RokMotionConfig.CullDistanceStuds
		then
			if not self.IsResting then
				apply(self, 0, 1, 1)
			end
			return
		end
		local now = os.clock()
		local lift, stretch = landing(self, now)
		if not LowGraphics.IsOn() then
			stretch += RokMotionConfig.BreatheAmount * math.sin(
				2 * math.pi * now / RokMotionConfig.BreathePeriodSeconds + self.Phase
			)
		end
		apply(self, lift, 1 + stretch, blinkScale(self, now))
	end

	return IdleRok
end
