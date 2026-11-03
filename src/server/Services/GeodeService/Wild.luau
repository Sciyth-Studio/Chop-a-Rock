--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local WildGeodeConfig = require(ReplicatedStorage.Config.WildGeodeConfig)
local Types = require(script.Parent.Types)

local Wild = {}

function Wild.NewTimer(random: Random): Types.WildTimer
	return {
		ChopSeconds = 0,
		LastChopAt = nil,
		DueSeconds = random:NextNumber(WildGeodeConfig.MinSeconds, WildGeodeConfig.MaxSeconds),
	}
end

function Wild.RecordChop(timer: Types.WildTimer, now: number)
	local last = timer.LastChopAt
	timer.LastChopAt = now
	if not last then
		return
	end
	local gap = now - last
	if gap <= WildGeodeConfig.ActiveWindowSeconds then
		timer.ChopSeconds += gap
	end
end

function Wild.IsDue(timer: Types.WildTimer): boolean
	return timer.ChopSeconds >= timer.DueSeconds
end

function Wild.Reset(timer: Types.WildTimer, random: Random)
	timer.ChopSeconds = 0
	timer.DueSeconds = random:NextNumber(WildGeodeConfig.MinSeconds, WildGeodeConfig.MaxSeconds)
end

function Wild.CanCrack(context: Types.Context, player: Player, zone: string): boolean
	local services = context.Services
	local data = services.DataService:GetData(player)
	local geode = GeodeConfig.Geodes[zone]
	if not data or not geode or geode.RobuxOnly then
		return false
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) or data.PeakStrength < geode.StrengthRequired then
		return false
	end
	return services.PetService:CanAdd(player, 1)
end

function Wild.Spot(player: Player, ground: Vector3): Attachment
	local spot = Instance.new("Attachment")
	spot.Name = WildGeodeConfig.SpotName
	spot.Parent = workspace.Terrain
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local facing = if root and root:IsA("BasePart")
		then Vector3.new(root.Position.X, ground.Y, root.Position.Z)
		else nil
	spot.WorldCFrame = if facing and (facing - ground).Magnitude > 0.1
		then CFrame.lookAt(ground, facing)
		else CFrame.new(ground)
	return spot
end

function Wild.Session(geodeKey: string, spot: Attachment): Types.Session
	return {
		GeodeKey = geodeKey,
		Spot = spot,
		Model = nil,
		Part = nil,
		StrengthRatio = GeodeConfig.ZoneStrengthRatio,
		Center = 0,
		StartTime = os.clock(),
		IsAuto = false,
		IsWild = true,
		IsCracked = false,
	}
end

return Wild
