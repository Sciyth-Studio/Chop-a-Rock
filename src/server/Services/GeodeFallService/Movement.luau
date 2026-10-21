--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local Types = require(script.Parent.Types)

local Movement = {}

local function root(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local part = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return if part and part:IsA("BasePart") then part else nil, humanoid
end

function Movement.New(): Types.Track
	return { Position = nil, SampledAt = os.clock(), AllowedUntil = 0, FlaggedUntil = 0 }
end

function Movement.Allow(track: Types.Track)
	track.AllowedUntil = os.clock() + GeodeFallConfig.OfficialMoveSeconds
	track.Position = nil
end

function Movement.Sample(track: Types.Track, player: Player, isExempt: boolean): boolean
	local now = os.clock()
	local part, humanoid = root(player)
	local previous = track.Position
	local elapsed = now - track.SampledAt
	track.SampledAt = now
	track.Position = if part then part.Position else nil
	if not part or not humanoid or not previous or isExempt or now < track.AllowedUntil then
		return false
	end
	local offset = part.Position - previous
	local moved = Vector3.new(offset.X, 0, offset.Z).Magnitude
	local limit = humanoid.WalkSpeed * GeodeFallConfig.MoveSpeedSlack * elapsed
		+ GeodeFallConfig.MoveAllowanceStuds
	if moved <= limit then
		return false
	end
	track.FlaggedUntil = now + GeodeFallConfig.FlagSeconds
	return true
end

function Movement.IsFlagged(track: Types.Track?): boolean
	return track ~= nil and os.clock() < track.FlaggedUntil
end

return Movement
