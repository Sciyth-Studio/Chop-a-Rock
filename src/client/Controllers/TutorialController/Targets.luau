--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local ZoneGeodeConfig = require(ReplicatedStorage.Config.ZoneGeodeConfig)

export type Target = {
	Position: Vector3,
	Goal: Vector3,
	Adornee: Instance,
	Label: string?,
	ArriveStuds: number,
	StopStuds: number?,
}

local Targets = {}

local function rootPosition(): Vector3?
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

function Targets.OwnPlot(): Model?
	local plots = workspace:FindFirstChild("BasePlots")
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
			return plot
		end
	end
	return nil
end

local function standOff(position: Vector3, from: Vector3?): Vector3
	if not from then
		return position
	end
	local flat = Vector3.new(from.X - position.X, 0, from.Z - position.Z)
	if flat.Magnitude < 0.01 then
		return position
	end
	return position + flat.Unit * TutorialConfig.PathStandOffStuds
end

local function trainingStand(): Target?
	local plot = Targets.OwnPlot()
	local stand = if plot then plot:FindFirstChild("TrainingStand", true) else nil
	if not stand then
		return nil
	end
	local board: BasePart? = nil
	for _, tagged in CollectionService:GetTagged("TrainingBoard") do
		if tagged:IsA("BasePart") and tagged:IsDescendantOf(stand) then
			board = tagged
			break
		end
	end
	local anchor = board or (if stand:IsA("Model") then stand.PrimaryPart else nil)
	if not anchor then
		return nil
	end
	local goal = anchor.Position + anchor.CFrame.LookVector * TrainingConfig.SnapDistanceStuds
	return {
		Position = anchor.Position,
		Goal = goal,
		Adornee = stand,
		Label = "Stand",
		ArriveStuds = TrainingConfig.SnapDistanceStuds + 4,
	}
end

local function nearestRock(key: string): Target?
	local folder = workspace:FindFirstChild("Rocks")
	local from = rootPosition()
	if not folder or not from then
		return nil
	end
	local best: BasePart? = nil
	local bestDistance = math.huge
	local name = `Rock_{key}`
	for _, child in folder:GetChildren() do
		if child.Name == name and child:IsA("BasePart") and CollectionService:HasTag(child, "ChopRock") then
			local distance = (child.Position - from).Magnitude
			if distance < bestDistance then
				best = child
				bestDistance = distance
			end
		end
	end
	if not best then
		return nil
	end
	return {
		Position = best.Position,
		Goal = standOff(best.Position, from),
		Adornee = best :: Instance,
		Label = nil,
		ArriveStuds = best.Size.X / 2 + 8,
	}
end

local function shopPad(screen: string, label: string): Target?
	for _, pad in CollectionService:GetTagged("ShopPad") do
		if pad:IsA("BasePart") and pad:GetAttribute("Screen") == screen then
			local adornee = pad.Parent and pad.Parent:IsA("Model") and pad.Parent or pad
			return {
				Position = pad.Position,
				Goal = pad.Position,
				Adornee = adornee,
				Label = label,
				ArriveStuds = math.max(pad.Size.X, pad.Size.Z) / 2,
				StopStuds = TutorialConfig.PadStopStuds,
			}
		end
	end
	return nil
end

local function cannonEntry(label: string): Target?
	local folder = workspace:FindFirstChild(CannonConfig.Trigger.FolderName)
	local entry = if folder then folder:FindFirstChild(CannonConfig.Trigger.EntryName) else nil
	if not entry or not entry:IsA("BasePart") then
		return nil
	end
	local floor = entry.Position - Vector3.new(0, entry.Size.Y / 2, 0)
	local goal = Vector3.new(floor.X, math.max(floor.Y, 0), floor.Z)
	return {
		Position = goal,
		Goal = goal,
		Adornee = entry :: Instance,
		Label = label,
		ArriveStuds = entry.Size.Z / 2,
	}
end

local function nearestZoneGeode(): Target?
	local folder = workspace:FindFirstChild(ZoneGeodeConfig.FolderName)
	local from = rootPosition()
	if not folder or not from then
		return nil
	end
	local nearest: Model? = nil
	local nearestDistance = math.huge
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			local distance = (child:GetPivot().Position - from).Magnitude
			if distance < nearestDistance then
				nearest, nearestDistance = child, distance
			end
		end
	end
	if not nearest then
		return nil
	end
	local position = nearest:GetPivot().Position
	return {
		Position = position,
		Goal = standOff(position, from),
		Adornee = nearest :: Instance,
		Label = "Geode",
		ArriveStuds = ZoneGeodeConfig.PromptRangeStuds,
	}
end

local function hatchPad(data: any): Target?
	local plot = Targets.OwnPlot()
	if not plot then
		return nil
	end
	local pads = if type(data) == "table" then data.HatchPads else nil
	local index = 1
	if type(pads) == "table" then
		for key in pads do
			index = tonumber(key) or index
			break
		end
	end
	local pad = plot:FindFirstChild(`{GeodeConfig.HatchPadPrefix}{index}`, true)
	if not pad or not pad:IsA("BasePart") then
		return nil
	end
	return {
		Position = pad.Position,
		Goal = standOff(pad.Position, rootPosition()),
		Adornee = pad :: Instance,
		Label = "Pad",
		ArriveStuds = 10,
	}
end

function Targets.For(step: number, data: any): Target?
	if Tutorial.IsTraining(step) then
		return trainingStand()
	elseif Tutorial.IsChopping(step) then
		return nearestRock(TutorialConfig.FirstChopRockKey)
	elseif step == Tutorial.GetGeode then
		return nearestZoneGeode()
	elseif step == Tutorial.Place or step == Tutorial.Open then
		return hatchPad(data)
	end
	return nil
end

Targets.ShopPad = shopPad
Targets.CannonEntry = cannonEntry
Targets.TrainingStand = trainingStand
Targets.NearestRock = nearestRock
Targets.RootPosition = rootPosition

return Targets
