--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GuideConfig = require(ReplicatedStorage.Config.GuideConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)

type Lock = { Wall: BasePart, Label: BillboardGui?, Text: TextLabel? }

export type State = {
	Folder: Folder,
	Locks: { [BasePart]: Lock },
}

local Locks = {}

local reasons = {
	[Tutorial.Train] = "Train first!",
	[Tutorial.Chop] = "Chop first!",
	[Tutorial.BuyAura] = "Aura first!",
	[Tutorial.TrainAgain] = "Train first!",
	[Tutorial.ChopAgain] = "Chop first!",
	[Tutorial.BuyGeode] = "Geode first!",
	[Tutorial.Crack] = "Crack first!",
	[Tutorial.Collect] = "Cash first!",
	[Tutorial.Final] = "Almost!",
}

function Locks.new(parent: Instance): State
	local folder = Instance.new("Folder")
	folder.Name = "Locks"
	folder.Parent = parent
	return { Folder = folder, Locks = {} }
end

local function build(state: State, pad: BasePart): Lock
	local wall = Instance.new("Part")
	wall.Name = "Lock"
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.CastShadow = false
	wall.Material = Enum.Material.Neon
	wall.Color = TutorialConfig.LockColor
	wall.Transparency = TutorialConfig.LockTransparency
	wall.Size = Vector3.new(pad.Size.X, TutorialConfig.LockHeight, pad.Size.Z)
	wall.CFrame = pad.CFrame * CFrame.new(0, TutorialConfig.LockHeight / 2, 0)
	wall.Parent = state.Folder

	local lock: Lock = { Wall = wall, Label = nil, Text = nil }
	local template = AssetRegistry.get(GuideConfig.LabelTemplateKey)
	if template:IsA("BillboardGui") then
		template.Name = "LockLabel"
		template.Adornee = wall
		template.AlwaysOnTop = true
		template.StudsOffsetWorldSpace = Vector3.new(0, TutorialConfig.LockHeight / 2 + 1, 0)
		local text = template:FindFirstChild("NameLabel")
		local requirement = template:FindFirstChild("RequirementLabel")
		if requirement and requirement:IsA("GuiObject") then
			requirement.Visible = false
		end
		if text and text:IsA("TextLabel") then
			Typography.ApplyTextStyle(text, "Red")
			lock.Text = text
		end
		template.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		lock.Label = template
	else
		template:Destroy()
	end
	return lock
end

local function remove(state: State, pad: BasePart)
	local lock = state.Locks[pad]
	if not lock then
		return
	end
	state.Locks[pad] = nil
	lock.Wall:Destroy()
	if lock.Label then
		lock.Label:Destroy()
	end
end

function Locks.Update(state: State, step: number)
	local reason = reasons[step]
	for _, pad in CollectionService:GetTagged("ShopPad") do
		if not pad:IsA("BasePart") or not pad:IsDescendantOf(workspace) then
			continue
		end
		local screen = pad:GetAttribute("Screen")
		local isLocked = reason ~= nil and type(screen) == "string" and not Tutorial.IsPadOpen(step, screen)
		if not isLocked then
			remove(state, pad)
			continue
		end
		local lock = state.Locks[pad] or build(state, pad)
		state.Locks[pad] = lock
		if lock.Text and lock.Text.Text ~= reason then
			lock.Text.Text = reason :: string
		end
	end
	for pad in state.Locks do
		if not pad:IsDescendantOf(workspace) then
			remove(state, pad)
		end
	end
end

function Locks.Clear(state: State)
	for pad in state.Locks do
		remove(state, pad)
	end
end

function Locks.Destroy(state: State)
	Locks.Clear(state)
	state.Folder:Destroy()
end

return Locks
