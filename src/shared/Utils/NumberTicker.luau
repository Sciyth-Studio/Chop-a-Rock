--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NumberTickerConfig = require(ReplicatedStorage.Config.NumberTickerConfig)

export type NumberTicker = {
	Set: (self: NumberTicker, value: number) -> (),
	Snap: (self: NumberTicker, value: number) -> (),
	Destroy: (self: NumberTicker) -> (),
}

local active: { [(number) -> boolean]: boolean } = {}
local connection: RBXScriptConnection? = nil

local function step()
	local now = os.clock()
	for update in active do
		if update(now) then
			active[update] = nil
		end
	end
	if next(active) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function track(update: (number) -> boolean)
	active[update] = true
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

local function durationFor(from: number, to: number): number
	local decades = math.log10(math.max(to / math.max(from, 1), 1))
	return math.clamp(
		NumberTickerConfig.MinSeconds + NumberTickerConfig.SecondsPerDecade * decades,
		NumberTickerConfig.MinSeconds,
		NumberTickerConfig.MaxSeconds
	)
end

local NumberTicker = {}

function NumberTicker.new(format: (number) -> string, apply: (string) -> (), initial: number?): NumberTicker
	local shown = initial or 0
	local from = shown
	local target = shown
	local startedAt = 0
	local duration = 0
	local text: string? = nil

	local function show(value: number)
		shown = value
		local nextText = format(value)
		if nextText ~= text then
			text = nextText
			apply(nextText)
		end
	end

	local function update(now: number): boolean
		local alpha = math.clamp((now - startedAt) / duration, 0, 1)
		if alpha >= 1 then
			show(target)
			return true
		end
		local eased = 1 - (1 - alpha) ^ NumberTickerConfig.EasePower
		show(from + (target - from) * eased)
		return false
	end

	local function snap(value: number)
		active[update] = nil
		from = value
		target = value
		show(value)
	end

	show(shown)

	return {
		Set = function(_self: NumberTicker, value: number)
			if value ~= value or value == target then
				return
			end
			if value < shown or format(value) == text then
				snap(value)
				return
			end
			from = shown
			target = value
			startedAt = os.clock()
			duration = durationFor(from, value)
			track(update)
		end,
		Snap = function(_self: NumberTicker, value: number)
			snap(value)
		end,
		Destroy = function(_self: NumberTicker)
			active[update] = nil
		end,
	}
end

return NumberTicker
