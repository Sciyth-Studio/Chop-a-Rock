--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GuideConfig = require(ReplicatedStorage.Config.GuideConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type TroveInstance = typeof(Trove.new())

local ROCK_TAG = "ChopRock"
local NAME_LABEL = "NameLabel"
local REQUIREMENT_LABEL = "RequirementLabel"

local RockLabels = {}

local labels: { [Instance]: BillboardGui } = {}

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("TextLabel") then
		return found
	end
	return nil
end

local function detach(trove: TroveInstance, part: Instance)
	local label = labels[part]
	if not label then
		return
	end
	labels[part] = nil
	trove:Remove(label)
end

local function attach(trove: TroveInstance, part: Instance)
	if not part:IsA("BasePart") or labels[part] then
		return
	end
	local key = part:GetAttribute("RockKey")
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local config = if type(key) == "string" then rocks[key] else nil
	if not config then
		return
	end

	local template = AssetRegistry.get(GuideConfig.LabelTemplateKey)
	if not template:IsA("BillboardGui") then
		template:Destroy()
		return
	end
	local nameLabel = findLabel(template, NAME_LABEL)
	local requirementLabel = findLabel(template, REQUIREMENT_LABEL)
	if not nameLabel or not requirementLabel then
		warn(`[RockLabels] {template.Name} needs TextLabels named {NAME_LABEL} and {REQUIREMENT_LABEL}`)
		template:Destroy()
		return
	end

	Typography.Apply(template)
	template.Adornee = part
	template.MaxDistance = GuideConfig.LabelMaxDistance
	template.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + GuideConfig.LabelHeightAboveRock, 0)
	nameLabel.Text = config.DisplayName
	requirementLabel.Text =
		`Strength {NumberFormat.Commas(config.StrengthRequired)} {TrainingConfig.StrengthUnit}`

	template.Parent = part
	labels[part] = template
	trove:Add(template)
end

function RockLabels.Start(trove: TroveInstance)
	for _, part in CollectionService:GetTagged(ROCK_TAG) do
		attach(trove, part)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(ROCK_TAG), function(part: Instance)
		attach(trove, part)
	end)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(ROCK_TAG), function(part: Instance)
		detach(trove, part)
	end)
	trove:Add(function()
		table.clear(labels)
	end)
end

return RockLabels
