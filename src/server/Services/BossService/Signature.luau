--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local ChopZones = require(ReplicatedStorage.ChopZones)

local Signature = {}

local Signatures = BossConfig.Signatures
local spec = BossConfig.Signature

local function chompCenters(center: number, random: Random): { number }
	local centers = { center }
	for _ = 2, spec.ChompJumps do
		local last = centers[#centers]
		local nextCenter = ChopZones.RandomCenter(random)
		for _ = 1, 8 do
			if math.abs(nextCenter - last) >= spec.ChompMinGap then
				break
			end
			nextCenter = ChopZones.RandomCenter(random)
		end
		table.insert(centers, nextCenter)
	end
	return centers
end

local function frostPatches(center: number, random: Random): { number }
	local width = spec.FrostPatchWidth
	local first = math.clamp(center - width * random:NextNumber(0.15, 0.85), 0, 1 - width)
	local second = first
	for _ = 1, 8 do
		second = random:NextNumber(0, 1 - width)
		if math.abs(second - first) >= width then
			break
		end
	end
	return { first, second, width, 0 }
end

function Signature.Build(kind: number, center: number, random: Random): { number }
	if kind == Signatures.Chomp then
		return chompCenters(center, random)
	elseif kind == Signatures.Frost then
		return frostPatches(center, random)
	end
	return { 0, 0, 0, 0 }
end

function Signature.IsShelled(kind: number, quality: number, greatQuality: number): boolean
	return kind == Signatures.Shell and quality < greatQuality
end

return Signature
