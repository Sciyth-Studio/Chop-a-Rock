--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)

export type State =
	"Home"
	| "Wander"
	| "Charge"
	| "Fight"
	| "Hold"
	| "Return"
	| "Flee"
	| "Defeat"
	| "Gone"
	| "Out"
	| "Rise"

export type Enemy = {
	Zone: string,
	Model: Model,
	Home: Vector3,
	Scale: number,
	Height: number,
	Radius: number,
	Position: Vector3,
	Facing: Vector3,
	State: State,
	StateAt: number,
	From: Vector3,
	StaggerAt: number,
	SlamAt: number,
	Away: Vector3,
	AreaMin: Vector3,
	AreaMax: Vector3,
	FleeTo: Vector3,
	WanderTo: Vector3,
	WanderAt: number,
	FrozenUntil: number,
	IsKnockedOut: boolean,
	OutLeft: number,
	TwitchAt: number,
}

local Motion = {}

local function flat(vector: Vector3, fallback: Vector3): Vector3
	local level = Vector3.new(vector.X, 0, vector.Z)
	return if level.Magnitude > 1e-3 then level.Unit else fallback
end

local function hop(alpha: number, height: number): number
	return 4 * height * alpha * (1 - alpha)
end

local function pose(enemy: Enemy, lift: number, now: number)
	local staggered = math.clamp((now - enemy.StaggerAt) / EnemyConfig.StaggerSeconds, 0, 1)
	local tilt = math.rad(EnemyConfig.StaggerDegrees) * (1 - staggered)
	local position = enemy.Position + Vector3.new(0, lift, 0)
	enemy.Model:PivotTo(CFrame.lookAt(position, position + enemy.Facing) * CFrame.Angles(tilt, 0, 0))
end

local function standPoint(enemy: Enemy, feet: Vector3): Vector3
	local standOff = EnemyConfig.StandOffStuds * enemy.Scale / EnemyConfig.ModelScale
	return feet + flat(enemy.Position - feet, enemy.Facing) * (enemy.Radius + standOff)
end

function Motion.Set(enemy: Enemy, state: State, now: number)
	enemy.State = state
	enemy.StateAt = now
	enemy.From = enemy.Position
	if state == "Fight" then
		enemy.SlamAt = now + EnemyConfig.SlamEverySeconds
	elseif state == "Out" then
		enemy.Position = Vector3.new(enemy.Position.X, enemy.Home.Y, enemy.Position.Z)
	elseif state == "Rise" then
		enemy.Position = enemy.Home
		enemy.Facing = EnemyConfig.HomeFacing
	elseif state == "Home" then
		local pause = EnemyConfig.WanderPauseMaxSeconds - EnemyConfig.WanderPauseMinSeconds
		enemy.WanderAt = now + EnemyConfig.WanderPauseMinSeconds + math.random() * pause
	end
end

function Motion.Stagger(enemy: Enemy, now: number)
	enemy.StaggerAt = now
end

function Motion.Hitstop(enemy: Enemy, now: number, seconds: number)
	enemy.StaggerAt = now + seconds
	enemy.FrozenUntil = now + seconds
end

function Motion.Knock(enemy: Enemy, from: Vector3, now: number)
	enemy.Away = flat(enemy.Position - from, enemy.Facing)
	Motion.Set(enemy, "Defeat", now)
end

function Motion.FurthestPoint(enemy: Enemy, from: Vector3): Vector3
	local margin = enemy.Radius + EnemyConfig.FleeWallMarginStuds * enemy.Scale / EnemyConfig.ModelScale
	local low, high = enemy.AreaMin, enemy.AreaMax
	local function farSide(position: number, lowEdge: number, highEdge: number): number
		local middle = (lowEdge + highEdge) / 2
		local inset = math.min(margin, (highEdge - lowEdge) / 2)
		return if position < middle then highEdge - inset else lowEdge + inset
	end
	return Vector3.new(farSide(from.X, low.X, high.X), enemy.Home.Y, farSide(from.Z, low.Z, high.Z))
end

function Motion.Wander(enemy: Enemy, to: Vector3, now: number)
	enemy.WanderTo = to
	Motion.Set(enemy, "Wander", now)
end

function Motion.Flee(enemy: Enemy, from: Vector3, now: number)
	enemy.FleeTo = Motion.FurthestPoint(enemy, from)
	Motion.Set(enemy, "Flee", now)
end

function Motion.Step(enemy: Enemy, dt: number, now: number, feet: Vector3?): boolean
	local elapsed = now - enemy.StateAt
	local zoneScale = enemy.Scale / EnemyConfig.ModelScale
	if now < enemy.FrozenUntil then
		pose(enemy, 0, now)
		return false
	end
	if enemy.State == "Home" then
		local wave = (math.sin(now * 2 * math.pi / EnemyConfig.IdleBobSeconds) + 1) / 2
		pose(enemy, wave * EnemyConfig.IdleBobStuds * zoneScale, now)
	elseif enemy.State == "Wander" then
		local offset = enemy.WanderTo - enemy.Position
		local step = EnemyConfig.WanderSpeedStuds * zoneScale * dt
		enemy.Facing = flat(offset, enemy.Facing)
		if offset.Magnitude > step then
			enemy.Position += offset.Unit * step
			local wave = math.abs(math.sin(elapsed * math.pi * EnemyConfig.WanderHopsPerSecond))
			pose(enemy, wave * EnemyConfig.WanderHopStuds * zoneScale, now)
		else
			enemy.Position = enemy.WanderTo
			pose(enemy, 0, now)
			Motion.Set(enemy, "Home", now)
		end
	elseif enemy.State == "Charge" and feet then
		local alpha = math.min(elapsed / EnemyConfig.ChargeSeconds, 1)
		enemy.Position = enemy.From:Lerp(standPoint(enemy, feet), alpha)
		enemy.Facing = flat(feet - enemy.Position, enemy.Facing)
		pose(enemy, hop(alpha, EnemyConfig.ChargeHopStuds * zoneScale), now)
		if alpha >= 1 then
			Motion.Set(enemy, "Fight", now)
		end
	elseif enemy.State == "Fight" and feet then
		local offset = standPoint(enemy, feet) - enemy.Position
		local step = EnemyConfig.ChaseSpeedStuds * zoneScale * dt
		enemy.Position += if offset.Magnitude > step then offset.Unit * step else offset
		enemy.Facing = flat(feet - enemy.Position, enemy.Facing)
		local slamming = (now - enemy.SlamAt) / EnemyConfig.SlamSeconds
		if slamming >= 1 then
			enemy.SlamAt = now + EnemyConfig.SlamEverySeconds
			pose(enemy, 0, now)
			return true
		end
		pose(enemy, if slamming >= 0 then hop(slamming, EnemyConfig.SlamHopStuds * zoneScale) else 0, now)
	elseif enemy.State == "Hold" then
		pose(enemy, 0, now)
	elseif enemy.State == "Return" then
		local alpha = math.min(elapsed / EnemyConfig.ReturnSeconds, 1)
		enemy.Position = enemy.From:Lerp(enemy.Home, alpha)
		enemy.Facing = flat(enemy.Home - enemy.From, enemy.Facing)
		pose(enemy, hop(alpha, EnemyConfig.ReturnHopStuds * zoneScale), now)
		if alpha >= 1 then
			enemy.Facing = EnemyConfig.HomeFacing
			Motion.Set(enemy, "Home", now)
		end
	elseif enemy.State == "Flee" then
		local offset = enemy.FleeTo - enemy.Position
		local step = EnemyConfig.FleeSpeedStuds * zoneScale * dt
		enemy.Facing = flat(offset, enemy.Facing)
		if offset.Magnitude > step then
			enemy.Position += offset.Unit * step
			pose(
				enemy,
				math.abs(math.sin(elapsed * math.pi * 5)) * EnemyConfig.ReturnHopStuds * zoneScale,
				now
			)
		else
			enemy.Position = enemy.FleeTo
			pose(enemy, 0, now)
			Motion.Set(enemy, "Home", now)
		end
	elseif enemy.State == "Defeat" then
		enemy.Position += enemy.Away * EnemyConfig.KnockSpeedStuds * zoneScale * dt
		local lift = EnemyConfig.KnockUpStuds * zoneScale * elapsed
			- EnemyConfig.KnockGravity * zoneScale * elapsed * elapsed / 2
		local position = enemy.Position + Vector3.new(0, lift, 0)
		enemy.Model:PivotTo(
			CFrame.lookAt(position, position + enemy.Facing)
				* CFrame.Angles(EnemyConfig.KnockSpinRadians * elapsed, 0, 0)
		)
		if elapsed >= EnemyConfig.DefeatSeconds then
			Motion.Set(enemy, if enemy.IsKnockedOut then "Out" else "Gone", now)
		end
	elseif enemy.State == "Out" then
		local lift = enemy.Radius
		local position = enemy.Position + Vector3.new(0, lift, 0)
		local breathe = math.sin(now * EnemyConfig.OutBreatheSpeed) * EnemyConfig.OutBreatheRadians
		local pitch = math.pi / 2 + breathe
		local roll = 0
		if enemy.OutLeft <= EnemyConfig.SitSeconds then
			pitch -= EnemyConfig.SitRadians
		elseif enemy.OutLeft <= EnemyConfig.RollSeconds then
			roll = EnemyConfig.RollRadians
		end
		local twitch = (now - enemy.TwitchAt) / EnemyConfig.TwitchSeconds
		if twitch >= 0 and twitch < 1 then
			pitch -= math.sin(twitch * math.pi) * EnemyConfig.TwitchRadians
		end
		enemy.Model:PivotTo(
			CFrame.lookAt(position, position + enemy.Facing)
				* CFrame.Angles(0, 0, roll)
				* CFrame.Angles(pitch, 0, 0)
		)
	elseif enemy.State == "Rise" then
		local alpha = math.min(elapsed / EnemyConfig.RiseSeconds, 1)
		pose(enemy, (alpha - 1) * enemy.Height, now)
		if alpha >= 1 then
			Motion.Set(enemy, "Home", now)
		end
	end
	return false
end

return Motion
