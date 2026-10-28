--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

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

local function geodePit(): Target?
	local plot = Targets.OwnPlot()
	local spot = if plot then plot:FindFirstChild("GeodeSpot", true) else nil
	if not spot or not spot:IsA("Attachment") then
		return nil
	end
	local adornee = spot.Parent or spot
	return {
		Position = spot.WorldPosition,
		Goal = standOff(spot.WorldPosition, rootPosition()),
		Adornee = adornee :: Instance,
		Label = "Pit",
		ArriveStuds = 10,
	}
end

local function earningsPad(data: any): Target?
	local plot = Targets.OwnPlot()
	if not plot or type(data) ~= "table" or type(data.Pets) ~= "table" then
		return nil
	end
	for _, pet in data.Pets do
		if type(pet.Slot) == "number" then
			local pedestal = plot:FindFirstChild(`Pedestal{pet.Slot}`, true)
			local pad = if pedestal then pedestal:FindFirstChild("EarningsPad", true) else nil
			if pad and pad:IsA("BasePart") then
				return {
					Position = pad.Position,
					Goal = pad.Position,
					Adornee = pad :: Instance,
					Label = "Cash",
					ArriveStuds = math.max(pad.Size.X, pad.Size.Z) / 2,
					StopStuds = TutorialConfig.PadStopStuds,
				}
			end
		end
	end
	return nil
end

function Targets.For(step: number, data: any): Target?
	if Tutorial.IsTraining(step) then
		return trainingStand()
	elseif Tutorial.IsChopping(step) then
		return nearestRock(TutorialConfig.FirstChopRockKey)
	elseif step == Tutorial.BuyGeode then
		return shopPad("GeodeStand", "Geode")
	elseif step == Tutorial.Crack then
		return geodePit()
	elseif step == Tutorial.Collect then
		return earningsPad(data)
	end
	return nil
end

Targets.ShopPad = shopPad
Targets.TrainingStand = trainingStand
Targets.NearestRock = nearestRock
Targets.RootPosition = rootPosition

return Targets
