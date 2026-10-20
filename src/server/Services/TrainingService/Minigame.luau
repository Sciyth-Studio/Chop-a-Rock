--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local TrainingMinigameConfig = require(ReplicatedStorage.Config.TrainingMinigameConfig)

export type Piece = {
	Kind: number,
	LaunchClock: number,
}

export type Session = {
	Pieces: { [number]: Piece },
	NextId: number,
	NextWaveClock: number,
	Power: number,
	Score: number,
	Random: Random,
}

local Minigame = {}

function Minigame.new(now: number): Session
	return {
		Pieces = {},
		NextId = 0,
		NextWaveClock = now + TrainingMinigameConfig.FirstWaveSeconds,
		Power = 0,
		Score = 0,
		Random = Random.new(),
	}
end

function Minigame.Multiplier(session: Session?): number
	if not session then
		return 1
	end
	return 1 + session.Power * (TrainingMinigameConfig.MaxMultiplier - 1)
end

function Minigame.SendPower(player: Player, session: Session)
	Packets.TrainingMinigamePower:FireClient(
		player,
		session.Power,
		Minigame.Multiplier(session),
		session.Score
	)
end

local function setPower(player: Player, session: Session, power: number, hasScoreChanged: boolean)
	local clamped = math.clamp(power, 0, 1)
	if clamped == session.Power and not hasScoreChanged then
		return
	end
	session.Power = clamped
	Minigame.SendPower(player, session)
end

local function nextId(session: Session): number
	session.NextId = session.NextId % TrainingMinigameConfig.MaxIdsPerSession + 1
	return session.NextId
end

local function spawnWave(player: Player, session: Session, now: number)
	local rng = session.Random
	local count =
		rng:NextInteger(TrainingMinigameConfig.MinPiecesPerWave, TrainingMinigameConfig.MaxPiecesPerWave)
	local ids: { number } = {}
	local kinds: { number } = {}
	local delays: { number } = {}
	local startXs: { number } = {}
	local drifts: { number } = {}
	local apexes: { number } = {}
	local hasBoard = false
	for index = 1, count do
		local isBomb = rng:NextNumber() < TrainingMinigameConfig.BombChance and (hasBoard or index < count)
		hasBoard = hasBoard or not isBomb
		local id = nextId(session)
		local delay = rng:NextNumber(0, TrainingMinigameConfig.MaxLaunchDelaySeconds)
		local startX = rng:NextNumber(TrainingMinigameConfig.MinStartX, TrainingMinigameConfig.MaxStartX)
		local drift = rng:NextNumber(-TrainingMinigameConfig.MaxDriftX, TrainingMinigameConfig.MaxDriftX)
		session.Pieces[id] = {
			Kind = if isBomb then TrainingMinigameConfig.BombKind else TrainingMinigameConfig.BoardKind,
			LaunchClock = now + delay,
		}
		table.insert(ids, id)
		table.insert(kinds, session.Pieces[id].Kind)
		table.insert(delays, delay)
		table.insert(startXs, startX)
		table.insert(drifts, math.clamp(startX + drift, 0.05, 0.95) - startX)
		table.insert(
			apexes,
			rng:NextNumber(TrainingMinigameConfig.MinApexHeight, TrainingMinigameConfig.MaxApexHeight)
		)
	end
	Packets.TrainingMinigameWave:FireClient(player, ids, kinds, delays, startXs, drifts, apexes)
end

function Minigame.Step(player: Player, session: Session, now: number)
	local lifetime = TrainingMinigameConfig.FlightSeconds + TrainingMinigameConfig.LatencySlackSeconds
	local missed = 0
	for id, piece in session.Pieces do
		if now - piece.LaunchClock > lifetime then
			session.Pieces[id] = nil
			if piece.Kind == TrainingMinigameConfig.BoardKind then
				missed += 1
			end
		end
	end
	if missed > 0 then
		setPower(player, session, session.Power - missed * TrainingMinigameConfig.PowerPerMiss, false)
	end
	if now >= session.NextWaveClock then
		session.NextWaveClock = now + TrainingMinigameConfig.WaveIntervalSeconds
		spawnWave(player, session, now)
	end
end

function Minigame.Slice(player: Player, session: Session, id: number, now: number): boolean
	local piece = session.Pieces[id]
	if not piece or now - piece.LaunchClock < TrainingMinigameConfig.MinSliceSeconds then
		return false
	end
	session.Pieces[id] = nil
	if piece.Kind == TrainingMinigameConfig.BombKind then
		session.Score = 0
		setPower(player, session, 0, true)
	else
		session.Score = math.min(session.Score + 1, TrainingMinigameConfig.MaxScore)
		setPower(player, session, session.Power + TrainingMinigameConfig.PowerPerSlice, true)
	end
	return true
end

return Minigame
