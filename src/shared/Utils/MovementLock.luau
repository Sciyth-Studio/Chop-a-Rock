--!strict

type Lock = {
	Count: number,
	WalkSpeed: number,
	JumpPower: number,
	JumpHeight: number,
}

local locks: { [Humanoid]: Lock } = {}

local MovementLock = {}

function MovementLock.Acquire(humanoid: Humanoid): () -> ()
	local lock = locks[humanoid]
	if lock then
		lock.Count += 1
	else
		lock = {
			Count = 1,
			WalkSpeed = humanoid.WalkSpeed,
			JumpPower = humanoid.JumpPower,
			JumpHeight = humanoid.JumpHeight,
		}
		locks[humanoid] = lock
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
	local held: Lock = lock
	local isReleased = false
	return function()
		if isReleased then
			return
		end
		isReleased = true
		held.Count -= 1
		if held.Count > 0 then
			return
		end
		locks[humanoid] = nil
		if humanoid.Parent then
			humanoid.WalkSpeed = held.WalkSpeed
			humanoid.JumpPower = held.JumpPower
			humanoid.JumpHeight = held.JumpHeight
		end
	end
end

return MovementLock
