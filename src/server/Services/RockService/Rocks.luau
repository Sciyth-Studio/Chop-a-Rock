--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local Types = require(script.Parent.Types)

local Rocks = {}

local rockTag = "ChopRock"

local function findAuthored(key: string): BasePart?
	for _, tagged in CollectionService:GetTagged(rockTag) do
		if
			tagged:IsA("BasePart")
			and tagged:GetAttribute("RockKey") == key
			and tagged:IsDescendantOf(workspace)
		then
			return tagged
		end
	end
	return nil
end

function Rocks.Spawn(track: (Instance) -> (), key: string, config: RockConfig.Rock): Types.Rock
	local part = findAuthored(key)
	if not part then
		local created = Instance.new("Part")
		created.Name = `Rock_{key}`
		created.Size = config.PlaceholderSize
		created.Position = config.PlaceholderPosition
		created.Color = config.PlaceholderColor
		created.Material = Enum.Material.Slate
		created.Parent = workspace
		track(created)
		CollectionService:AddTag(created, rockTag)
		created:SetAttribute("RockKey", key)
		part = created
	end
	local rockPart = part :: BasePart
	rockPart.Anchored = true
	rockPart.CanCollide = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Chop"
	prompt.ObjectText = config.DisplayName
	prompt.HoldDuration = ChopConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = ChopConfig.PromptRangeStuds + rockPart.Size.X / 2
	prompt.RequiresLineOfSight = false
	prompt.Parent = rockPart
	track(prompt)

	return { Key = key, Config = config, Part = rockPart, Prompt = prompt }
end

return Rocks
