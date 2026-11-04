--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Effects = require(script.Parent.Effects)
local Types = require(script.Parent.Types)

local OWNED_PROMPT_TAG = "OwnedPrompt"

local HatchPads = {}

local function newPrompt(name: string, parent: Instance, hold: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.HoldDuration = hold
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = GeodeConfig.HatchPromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Active", false)
	CollectionService:AddTag(prompt, OWNED_PROMPT_TAG)
	prompt.Parent = parent
	return prompt
end

function HatchPads.Setup(plot: Model): { Types.Pad }
	local pads: { Types.Pad } = {}
	for index = 1, GeodeConfig.HatchPadCount do
		local part = plot:FindFirstChild(`{GeodeConfig.HatchPadPrefix}{index}`, true)
		if not part or not part:IsA("BasePart") then
			warn(`[GeodeService] {plot:GetFullName()} has no {GeodeConfig.HatchPadPrefix}{index}`)
			break
		end
		local spot = Instance.new("Attachment")
		spot.Name = GeodeConfig.HatchSpotName
		spot.CFrame = CFrame.new(0, part.Size.Y / 2, 0)
		spot.Parent = part
		CollectionService:AddTag(part, GeodeConfig.HatchPadTag)
		part:SetAttribute("PadIndex", index)
		table.insert(pads, {
			Part = part,
			Spot = spot,
			Prompt = newPrompt("HatchPrompt", spot, GeodeConfig.HatchPromptHoldSeconds),
		})
	end
	return pads
end

function HatchPads.SetupPlaceAll(plot: Model): ProximityPrompt?
	local path = plot:FindFirstChild(GeodeConfig.HatchPathPartName, true)
	if not path or not path:IsA("BasePart") then
		return nil
	end
	local prompt = newPrompt("PlaceAllPrompt", path, 0)
	prompt.ActionText = GeodeConfig.PlaceAllPromptText
	prompt.KeyboardKeyCode = GeodeConfig.PickPromptKey
	prompt.GamepadKeyCode = GeodeConfig.PickPromptGamepadKey
	return prompt
end

function HatchPads.OwnedCount(data: any): number
	local total = 0
	for _, count in data.Geodes do
		total += count
	end
	return total
end

function HatchPads.IsReady(record: any): boolean
	return os.time() >= record.ReadyAt
end

local function hatchSeconds(data: any, geodeKey: string): number
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return TutorialConfig.FirstHatchSeconds
	end
	return GeodeConfig.Geodes[geodeKey].HatchSeconds
end

function HatchPads.Place(context: Types.Context, player: Player, index: number, geodeKey: string?): boolean
	local dataService = context.Services.DataService
	local data = dataService:GetData(player)
	local owned = if data and geodeKey then data.Geodes[geodeKey] or 0 else 0
	if not data or not geodeKey or owned < 1 or data.HatchPads[tostring(index)] then
		return false
	end
	dataService:Set(player, { "Geodes", geodeKey }, owned - 1)
	dataService:Set(player, { "HatchPads", tostring(index) }, {
		GeodeKey = geodeKey,
		ReadyAt = os.time() + hatchSeconds(data, geodeKey),
	})
	return true
end

function HatchPads.Clear(context: Types.Context, player: Player, index: number)
	local replica = context.Services.DataService:GetReplica(player)
	if replica then
		replica:Set({ "HatchPads", tostring(index) }, nil)
	end
end

function HatchPads.CanSkip(data: any): boolean
	return not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

function HatchPads.Render(
	pad: Types.Pad,
	owner: Player,
	record: any,
	canAct: boolean,
	nextGeode: any,
	canSkip: boolean
)
	local part, prompt = pad.Part, pad.Prompt
	part:SetAttribute("OwnerUserId", owner.UserId)
	part:SetAttribute("GeodeKey", if record then record.GeodeKey else nil)
	part:SetAttribute("ReadyAt", if record then record.ReadyAt else nil)
	prompt:SetAttribute("OwnerUserId", owner.UserId)
	if record then
		local geode = GeodeConfig.Geodes[record.GeodeKey]
		Effects.ShowOnPad(pad, if geode then geode.ModelKey else nil)
		prompt.ObjectText = if geode then geode.DisplayName else ""
		local isReady = HatchPads.IsReady(record)
		prompt.ActionText = if isReady then GeodeConfig.OpenPromptText else GeodeConfig.SkipPromptText
		prompt:SetAttribute("Active", canAct and (isReady or canSkip))
	else
		Effects.ShowOnPad(pad, nil)
		prompt.ObjectText = if nextGeode then nextGeode.DisplayName else ""
		prompt.ActionText = GeodeConfig.PlacePromptText
		prompt:SetAttribute("Active", canAct and nextGeode ~= nil)
	end
end

function HatchPads.ClearDisplay(pad: Types.Pad)
	Effects.ShowOnPad(pad, nil)
	pad.Part:SetAttribute("OwnerUserId", nil)
	pad.Part:SetAttribute("GeodeKey", nil)
	pad.Part:SetAttribute("ReadyAt", nil)
	pad.Prompt:SetAttribute("OwnerUserId", nil)
	pad.Prompt:SetAttribute("Active", false)
end

return HatchPads
