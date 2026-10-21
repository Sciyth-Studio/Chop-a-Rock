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
	Score: number,
	Random: Random,
}

local Minigame = {}

function Minigame.new(now: number): Session
	return {
		Pieces = {},
		NextId = 0,
		NextWaveClock = now + TrainingMinigameConfig.FirstWaveSeconds,
		Score = 0,
		Random = Random.new(),
	}
end

function Minigame.SendScore(player: Player, session: Session, gain: number)
	Packets.TrainingMinigameScore:FireClient(player, session.Score, gain)
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
	for id, piece in session.Pieces do
		if now - piece.LaunchClock > lifetime then
			session.Pieces[id] = nil
		end
	end
	if now >= session.NextWaveClock then
		session.NextWaveClock = now + TrainingMinigameConfig.WaveIntervalSeconds
		spawnWave(player, session, now)
	end
end

function Minigame.Slice(session: Session, id: number, now: number): number?
	local piece = session.Pieces[id]
	if not piece or now - piece.LaunchClock < TrainingMinigameConfig.MinSliceSeconds then
		return nil
	end
	session.Pieces[id] = nil
	if piece.Kind == TrainingMinigameConfig.BombKind then
		session.Score = 0
	else
		session.Score = math.min(session.Score + 1, TrainingMinigameConfig.MaxScore)
	end
	return piece.Kind
end

return Minigame
