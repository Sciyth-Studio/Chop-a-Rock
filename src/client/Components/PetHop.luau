--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetMotionConfig = require(ReplicatedStorage.Config.PetMotionConfig)

export type Hop = {
	Center: Vector3,
	HalfSize: Vector3,
	From: CFrame,
	To: CFrame,
	Start: number,
	Rest: number,
	HopsLeft: number,
	Target: Vector3,
}

local random = Random.new()

local PetHop = {}

local function pickTarget(hop: Hop)
	hop.Target = hop.Center
		+ Vector3.new(
			random:NextNumber(-hop.HalfSize.X, hop.HalfSize.X),
			0,
			random:NextNumber(-hop.HalfSize.Z, hop.HalfSize.Z)
		)
	hop.HopsLeft = random:NextInteger(PetMotionConfig.HopRunMin, PetMotionConfig.HopRunMax)
end

local function beginHop(hop: Hop, now: number)
	local position = hop.To.Position
	local flat = Vector3.new(hop.Target.X, position.Y, hop.Target.Z)
	local toTarget = flat - position
	if hop.HopsLeft <= 0 or toTarget.Magnitude < PetMotionConfig.HopStuds then
		pickTarget(hop)
		hop.Start = now
		hop.Rest = random:NextNumber(PetMotionConfig.HopRestMinSeconds, PetMotionConfig.HopRestMaxSeconds)
		hop.From = hop.To
		return
	end
	local step = toTarget.Unit * PetMotionConfig.HopStuds
	hop.From = hop.To
	hop.To = CFrame.lookAt(position + step, flat)
	hop.Start = now
	hop.Rest = PetMotionConfig.HopPauseSeconds
	hop.HopsLeft -= 1
end

function PetHop.New(model: Model, base: CFrame): Hop?
	local center = model:GetAttribute(PedestalConfig.HopCenterAttribute)
	local halfSize = model:GetAttribute(PedestalConfig.HopHalfSizeAttribute)
	if typeof(center) ~= "Vector3" or typeof(halfSize) ~= "Vector3" then
		return nil
	end
	local hop: Hop = {
		Center = center,
		HalfSize = halfSize,
		From = base,
		To = base,
		Start = os.clock(),
		Rest = random:NextNumber(0, PetMotionConfig.HopRestMaxSeconds),
		HopsLeft = 0,
		Target = center,
	}
	return hop
end

function PetHop.Step(hop: Hop, now: number): (number, number, CFrame)
	local elapsed = now - hop.Start
	local isHopping = hop.From ~= hop.To
	if isHopping and elapsed < PetMotionConfig.HopSeconds then
		local progress = elapsed / PetMotionConfig.HopSeconds
		local arc = 4 * progress * (1 - progress)
		return PetMotionConfig.HopHeightStuds * arc,
			PetMotionConfig.HopStretch * arc,
			hop.From:Lerp(hop.To, progress)
	end
	local restElapsed = if isHopping then elapsed - PetMotionConfig.HopSeconds else elapsed
	if restElapsed >= hop.Rest then
		beginHop(hop, now)
	end
	local squash = if isHopping and restElapsed < PetMotionConfig.HopLandSeconds
		then -PetMotionConfig.HopLandSquash * (1 - restElapsed / PetMotionConfig.HopLandSeconds)
		else 0
	return 0,
		squash,
		if hop.From ~= hop.To and now - hop.Start < PetMotionConfig.HopSeconds then hop.From else hop.To
end

return PetHop
