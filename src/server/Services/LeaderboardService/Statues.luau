--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)

local Statues = {}

local statueName = "Statue"

local function build(userId: number): Model?
	local ok, result = pcall(function()
		local description = Players:GetHumanoidDescriptionFromUserIdAsync(userId)
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not result then
		warn(`[LeaderboardService] Statue for {userId} failed: {result}`)
		return nil
	end
	local model = result :: Model
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	model:ScaleTo(LeaderboardConfig.StatueScale)
	return model
end

local function place(model: Model, spot: BasePart)
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = true
	end
	model:PivotTo(spot.CFrame)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	local top = spot.Position.Y + spot.Size.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, top - bottom, 0))
end

function Statues.Boards(key: string): { Instance }
	local boards = {}
	for _, board in CollectionService:GetTagged(LeaderboardConfig.BoardTag) do
		if
			board:IsDescendantOf(workspace)
			and board:GetAttribute(LeaderboardConfig.BoardAttribute) == key
		then
			table.insert(boards, board)
		end
	end
	return boards
end

function Statues.Show(board: Instance, userId: number?)
	local current = board:FindFirstChild(statueName)
	if current and current:GetAttribute("UserId") == userId then
		return
	end
	local spot = board:FindFirstChild(LeaderboardConfig.StatueSpotName, true)
	if not spot or not spot:IsA("BasePart") then
		return
	end
	if not userId then
		if current then
			current:Destroy()
		end
		return
	end
	local model = build(userId)
	if not model or not board.Parent then
		return
	end
	current = board:FindFirstChild(statueName)
	if current then
		current:Destroy()
	end
	model.Name = statueName
	model:SetAttribute("UserId", userId)
	place(model, spot)
	model.Parent = board
	CollectionService:AddTag(model, LeaderboardConfig.StatueTag)
end

return Statues
