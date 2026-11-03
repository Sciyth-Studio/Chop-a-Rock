--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)

export type State = "Home" | "Charge" | "Fight" | "Return" | "Flee" | "Defeat" | "Gone" | "Rise"

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
	return feet + flat(enemy.Position - feet, enemy.Facing) * (enemy.Radius + EnemyConfig.StandOffStuds)
end

function Motion.Set(enemy: Enemy, state: State, now: number)
	enemy.State = state
	enemy.StateAt = now
	enemy.From = enemy.Position
	if state == "Fight" then
		enemy.SlamAt = now + EnemyConfig.SlamEverySeconds
	elseif state == "Rise" then
		enemy.Position = enemy.Home
		enemy.Model:ScaleTo(enemy.Scale)
	end
end

function Motion.Stagger(enemy: Enemy, now: number)
	enemy.StaggerAt = now
end

function Motion.Flee(enemy: Enemy, from: Vector3, now: number)
	enemy.Away = flat(enemy.Position - from, enemy.Facing)
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
	elseif enemy.State == "Return" then
		local alpha = math.min(elapsed / EnemyConfig.ReturnSeconds, 1)
		enemy.Position = enemy.From:Lerp(enemy.Home, alpha)
		enemy.Facing = flat(enemy.Home - enemy.From, enemy.Facing)
		pose(enemy, hop(alpha, EnemyConfig.ReturnHopStuds * zoneScale), now)
		if alpha >= 1 then
			Motion.Set(enemy, "Home", now)
		end
	elseif enemy.State == "Flee" then
		local alpha = math.min(elapsed / EnemyConfig.FleeSeconds, 1)
		enemy.Position += enemy.Away * EnemyConfig.FleeSpeedStuds * zoneScale * dt
		enemy.Facing = enemy.Away
		local bounce = math.abs(math.sin(elapsed * math.pi * 5)) * EnemyConfig.ReturnHopStuds * zoneScale
		pose(enemy, bounce - alpha * alpha * enemy.Height * 1.5, now)
		if alpha >= 1 then
			Motion.Set(enemy, "Gone", now)
		end
	elseif enemy.State == "Defeat" then
		local alpha = math.min(elapsed / EnemyConfig.DefeatSeconds, 1)
		enemy.Model:ScaleTo(math.max(enemy.Scale * (1 - alpha), 0.01))
		pose(enemy, 0, now)
		if alpha >= 1 then
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
