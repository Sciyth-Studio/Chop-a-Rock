--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local Types = require(script.Parent.Types)

local Themes = BossConfig.ArenaThemes

local Motion = {}

local random = Random.new()

local function bounds(parts: { BasePart }): (Vector3, Vector3)
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = -low
	for _, part in parts do
		local cf = part.CFrame
		local half = part.Size / 2
		local right, up, back = cf.RightVector, cf.UpVector, cf.LookVector
		local extent = Vector3.new(
			math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(back.X) * half.Z,
			math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(back.Y) * half.Z,
			math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(back.Z) * half.Z
		)
		low = low:Min(cf.Position - extent)
		high = high:Max(cf.Position + extent)
	end
	return low, high
end

local function makePiece(parts: { BasePart }, centre: Vector3, isProp: boolean): Types.Piece
	local low, high = bounds(parts)
	local finals = {}
	local collides = {}
	for index, part in parts do
		finals[index] = part.CFrame
		collides[index] = part.CanCollide
	end
	local base = Vector3.new((low.X + high.X) / 2, centre.Y, (low.Z + high.Z) / 2)
	local offset = base - centre
	return {
		Parts = parts,
		Finals = finals,
		Collides = collides,
		Base = base,
		Width = math.max(high.X - low.X, high.Z - low.Z),
		Depth = math.max(high.Y - centre.Y, 0) + Themes.HideMarginStuds,
		Distance = Vector2.new(offset.X, offset.Z).Magnitude,
		Angle = math.atan2(offset.X, offset.Z),
		IsProp = isProp,
		Delay = 0,
		Duration = 0,
		Started = false,
		Finished = false,
	}
end

function Motion.Collect(model: Model, centre: Vector3): { Types.Piece }
	local pieces: { Types.Piece } = {}
	local ground = model:FindFirstChild(Themes.GroundName)
	if ground then
		for _, part in ground:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(pieces, makePiece({ part }, centre, false))
			end
		end
	end
	local props = model:FindFirstChild(Themes.PropsName)
	if props then
		for _, child in props:GetChildren() do
			local parts: { BasePart } = {}
			if child:IsA("BasePart") then
				table.insert(parts, child)
			end
			for _, descendant in child:GetDescendants() do
				if descendant:IsA("BasePart") then
					table.insert(parts, descendant)
				end
			end
			if #parts > 0 then
				table.insert(pieces, makePiece(parts, centre, true))
			end
		end
	end
	return pieces
end

function Motion.Schedule(pieces: { Types.Piece }, rising: boolean): number
	local farthest = 1
	local props: { Types.Piece } = {}
	for _, piece in pieces do
		piece.Started = false
		piece.Finished = false
		if piece.IsProp then
			table.insert(props, piece)
		else
			farthest = math.max(farthest, piece.Distance)
		end
	end
	table.sort(props, function(a, b)
		return a.Angle < b.Angle
	end)
	local total = 0
	local propCount = math.max(#props, 1)
	for index, piece in props do
		local share = (index - 1) / propCount
		if rising then
			piece.Delay = Themes.PropStartSeconds + share * Themes.PropStaggerSeconds
			piece.Duration = Themes.PropRiseSeconds
		else
			piece.Delay = (1 - share) * Themes.SinkStaggerSeconds
			piece.Duration = Themes.PropSinkSeconds
		end
		total = math.max(total, piece.Delay + piece.Duration)
	end
	local groundStart = if rising then 0 else Themes.SinkStaggerSeconds * 0.5
	for _, piece in pieces do
		if not piece.IsProp then
			local share = piece.Distance / farthest
			piece.Delay = groundStart + (if rising then share else 1 - share) * Themes.GroundRippleSeconds
			piece.Duration = Themes.TileRiseSeconds
			total = math.max(total, piece.Delay + piece.Duration)
		end
	end
	return total
end

local function easeOutBack(t: number): number
	local c1 = Themes.Overshoot
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function easeInBack(t: number): number
	local c1 = Themes.Overshoot
	local c3 = c1 + 1
	return c3 * t ^ 3 - c1 * t ^ 2
end

local function setCollide(piece: Types.Piece, restore: boolean)
	if not piece.IsProp then
		return
	end
	for index, part in piece.Parts do
		part.CanCollide = restore and piece.Collides[index]
	end
end

function Motion.Hide(pieces: { Types.Piece })
	for _, piece in pieces do
		setCollide(piece, false)
		local drop = CFrame.new(0, -piece.Depth, 0)
		for index, part in piece.Parts do
			part.CFrame = drop * piece.Finals[index]
		end
	end
end

function Motion.Show(pieces: { Types.Piece })
	for _, piece in pieces do
		setCollide(piece, true)
		for index, part in piece.Parts do
			part.CFrame = piece.Finals[index]
		end
	end
end

function Motion.Run(
	pieces: { Types.Piece },
	rising: boolean,
	isAlive: () -> boolean,
	onStart: (Types.Piece) -> ()
): boolean
	local started = os.clock()
	local remaining = #pieces
	local parts: { BasePart } = {}
	local frames: { CFrame } = {}
	while remaining > 0 do
		RunService.Heartbeat:Wait()
		if not isAlive() then
			return false
		end
		local elapsed = os.clock() - started
		table.clear(parts)
		table.clear(frames)
		for _, piece in pieces do
			if piece.Finished or elapsed < piece.Delay then
				continue
			end
			if not piece.Started then
				piece.Started = true
				if not rising then
					setCollide(piece, false)
				end
				onStart(piece)
			end
			local t = math.min((elapsed - piece.Delay) / piece.Duration, 1)
			local lift = if rising then -piece.Depth * (1 - easeOutBack(t)) else -piece.Depth * easeInBack(t)
			local jitter = Vector3.zero
			if piece.IsProp and t < 0.85 then
				jitter = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
					* Themes.JitterStuds
			end
			if t >= 1 then
				piece.Finished = true
				remaining -= 1
				lift = if rising then 0 else -piece.Depth
				jitter = Vector3.zero
				if rising then
					setCollide(piece, true)
				end
			end
			local shift = CFrame.new(jitter + Vector3.new(0, lift, 0))
			for index, part in piece.Parts do
				table.insert(parts, part)
				table.insert(frames, shift * piece.Finals[index])
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
	return true
end

return Motion
