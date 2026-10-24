--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local Component = require(ReplicatedStorage.Packages.Component)
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type Leaderboard = {
	Instance: Instance,
	Trove: any,
	Board: LeaderboardConfig.Board?,
	Tab: string,
	TabButtons: { [string]: GuiObject },
	Tabs: Instance?,
	Rows: { Frame },
	You: Frame?,
}

local shadowSuffix = "Shadow"

local function findBoard(key: any): LeaderboardConfig.Board?
	for _, board in LeaderboardConfig.Boards do
		if board.Key == key then
			return board
		end
	end
	return nil
end

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Leaderboard] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(root: Instance, name: string, text: string)
	local label = root:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
	local shadow = root:FindFirstChild(name .. shadowSuffix)
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

local function setVisible(root: Instance, name: string, isVisible: boolean)
	for _, childName in { name, name .. shadowSuffix } do
		local label = root:FindFirstChild(childName)
		if label and label:IsA("GuiObject") then
			label.Visible = isVisible
		end
	end
end

local function setAvatar(row: Instance, userId: number?)
	local avatar = row:FindFirstChild("Avatar", true)
	if avatar and avatar:IsA("ImageLabel") then
		avatar.Image = if userId then `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150` else ""
	end
end

local function paint(row: Frame, rank: number)
	local fill = row:FindFirstChild("Fill")
	local target: GuiObject = if fill and fill:IsA("GuiObject") then fill else row
	local medal = LeaderboardConfig.MedalColors[rank]
	local colors = LeaderboardConfig.RowColors
	target.BackgroundColor3 = medal or colors[(rank - 1) % #colors + 1]
end

local function duration(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)
	local days = math.floor(hours / 24)
	if days > 0 then
		return `{days}d {hours % 24}h`
	elseif hours > 0 then
		return `{hours}h {minutes % 60}m`
	end
	return `{minutes}m`
end

local function format(board: LeaderboardConfig.Board, value: number): string
	if board.Format == "Rate" then
		return `${NumberFormat.Rate(math.floor(value * 10 + 0.5) / 10)}/s`
	end
	local whole = math.floor(value + 0.5)
	if board.Format == "Strength" then
		return `{NumberFormat.Compact(whole)} {TrainingConfig.StrengthUnit}`
	elseif board.Format == "Duration" then
		return duration(whole)
	end
	return NumberFormat.Compact(whole)
end

local function isNear(board: Instance): boolean
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") or not board:IsA("PVInstance") then
		return false
	end
	return (board:GetPivot().Position - root.Position).Magnitude <= LeaderboardConfig.ClickDistance
end

return function(controllers: { [string]: any })
	local Board = Component.new({ Tag = LeaderboardConfig.BoardTag }) :: any

	local function render(self: Leaderboard)
		local board = self.Board
		local data = controllers.LeaderboardController:Get()
		if not board or not data then
			return
		end
		local isWeekly = self.Tab == "Weekly"
		local boards = (if isWeekly then data.WeeklyBoards else data.Boards) or {}
		local rows = boards[board.Key] or {}
		for rank, frame in self.Rows do
			local row = rows[rank]
			frame.Visible = row ~= nil
			if row then
				setText(frame, "Rank", `#{rank}`)
				setText(frame, "PlayerName", row.Name)
				setText(frame, "Value", format(board, row.Value))
				setAvatar(frame, row.UserId)
			end
		end
		local you = self.You
		if you then
			local localPlayer = Players.LocalPlayer
			local allStandings = (if isWeekly then data.WeeklyStandings else data.Standings) or {}
			local standings = allStandings[tostring(localPlayer.UserId)]
			local standing = if standings then standings[board.Key] else nil
			local rank = if standing then standing.Rank else 0
			setText(you, "Rank", if rank > 0 then `#{rank}` else LeaderboardConfig.UnrankedText)
			setText(you, "PlayerName", "You")
			setText(you, "Value", format(board, if standing then standing.Value else 0))
			setAvatar(you, localPlayer.UserId)
		end
	end

	local function renderResets(self: Leaderboard)
		local tabs = self.Tabs
		if not tabs then
			return
		end
		local isWeekly = self.Tab == "Weekly"
		setVisible(tabs, "Resets", isWeekly)
		local data = controllers.LeaderboardController:Get()
		local endsAt = if data then data.WeekEndsAt else nil
		if isWeekly and type(endsAt) == "number" then
			setText(tabs, "Resets", LeaderboardConfig.ResetsText .. duration(math.max(0, endsAt - os.time())))
		end
	end

	local function selectTab(self: Leaderboard, tab: string)
		local board = self.Board
		if not board then
			return
		end
		self.Tab = tab
		for name, button in self.TabButtons do
			local fill = button:FindFirstChild("Fill", true)
			BlockButton.Paint(fill, if name == tab then board.TabColors else LeaderboardConfig.TabIdleColors)
		end
		renderResets(self)
		render(self)
	end

	function Board.Construct(self: Leaderboard)
		self.Trove = Trove.new()
		self.Rows = {}
		self.TabButtons = {}
		self.Tab = LeaderboardConfig.DefaultTab
		self.Board = findBoard(self.Instance:GetAttribute(LeaderboardConfig.BoardAttribute))
	end

	local function setup(self: Leaderboard, board: LeaderboardConfig.Board, source: SurfaceGui)
		local face = source.Parent
		local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not face or not face:IsA("BasePart") or not playerGui then
			warn(`[Leaderboard] {source:GetFullName()} needs a BasePart parent and a PlayerGui`)
			return
		end
		local gui = self.Trove:Clone(source)
		gui.Adornee = face
		gui.ResetOnSpawn = false
		source.Enabled = false
		gui.Parent = playerGui
		Typography.Apply(gui)
		if controllers.UIController then
			controllers.UIController:BindFeel(gui)
		end
		setText(find(gui, "Header", "GuiObject") or gui, "Title", board.Title)
		setText(find(gui, "Columns", "GuiObject") or gui, "Column", board.Column)
		local template: Frame? = find(gui, LeaderboardConfig.RowTemplateName, "Frame")
		if template then
			template.Visible = false
			for rank = 1, LeaderboardConfig.Rows do
				local row = self.Trove:Clone(template)
				row.Name = `Row{rank}`
				row.LayoutOrder = rank
				row.Visible = false
				paint(row, rank)
				row.Parent = template.Parent
				table.insert(self.Rows, row)
			end
		end
		self.You = find(gui, "You", "Frame")
		local tabs = find(gui, "Tabs", "GuiObject")
		if tabs then
			self.Tabs = tabs
			for _, tab in LeaderboardConfig.Tabs do
				local button = tabs:FindFirstChild(tab)
				if button and button:IsA("GuiButton") then
					self.TabButtons[tab] = button
					self.Trove:Connect(button.Activated, function()
						if self.Tab ~= tab and isNear(self.Instance) then
							selectTab(self, tab)
						end
					end)
				else
					warn(`[Leaderboard] Missing tab button "{tab}" in {tabs:GetFullName()}`)
				end
			end
			self.Trove:Add(task.spawn(function()
				while true do
					task.wait(LeaderboardConfig.ResetsTickSeconds)
					renderResets(self)
				end
			end))
		end
		self.Trove:Connect(controllers.LeaderboardController.Changed, function()
			renderResets(self)
			render(self)
		end)
		selectTab(self, self.Tab)
	end

	function Board.Start(self: Leaderboard)
		local board = self.Board
		if not board then
			warn(`[Leaderboard] {self.Instance:GetFullName()} needs a valid Board attribute`)
			return
		end
		local gui = self.Instance:FindFirstChildWhichIsA("SurfaceGui", true)
		if gui then
			setup(self, board, gui)
			return
		end
		local connection
		connection = self.Trove:Connect(self.Instance.DescendantAdded, function(descendant: Instance)
			if descendant:IsA("SurfaceGui") then
				self.Trove:Remove(connection)
				setup(self, board, descendant)
			end
		end)
	end

	function Board.Stop(self: Leaderboard)
		self.Trove:Destroy()
	end

	return Board
end
