--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)

export type State = "Home" | "Charge" | "Fight" | "Hold" | "Return" | "Flee" | "Defeat" | "Gone" | "Rise"

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
	elseif state == "Rise" then
		enemy.Position = enemy.Home
		enemy.Facing = EnemyConfig.HomeFacing
	end
end

function Motion.Stagger(enemy: Enemy, now: number)
	enemy.StaggerAt = now
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

function Motion.Flee(enemy: Enemy, from: Vector3, now: number)
	enemy.FleeTo = Motion.FurthestPoint(enemy, from)
	Motion.Set(enemy, "Flee", now)
end

function Motion.Step(enemy: Enemy, dt: number, now: number, feet: Vector3?): boolean
	local elapsed = now - enemy.StateAt
	local zoneScale = enemy.Scale / EnemyConfig.ModelScale
	if enemy.State == "Home" then
		local wave = (math.sin(now * 2 * math.pi / EnemyConfig.IdleBobSeconds) + 1) / 2
		pose(enemy, wave * EnemyConfig.IdleBobStuds * zoneScale, now)
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
			Motion.Set(enemy, "Gone", now)
		end
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
