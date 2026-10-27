--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type Crown = {
	Model: Model,
	Weld: Weld,
	Offset: number,
}

local CrownController = { Name = "CrownController" }

local controllers: { [string]: any } = {}
local trove = Trove.new()
local isHidden = false
local playerTroves: { [Player]: any } = {}
local crowns: { [Player]: Crown } = {}
local angle = 0

local function boardName(key: string): string
	for _, board in LeaderboardConfig.Boards do
		if board.Key == key then
			return (string.gsub(board.Title, "^Top ", ""))
		end
	end
	return key
end

local function titleKeys(player: Player): { string }
	local value = player:GetAttribute(LeaderboardConfig.TitlesAttribute)
	if type(value) ~= "string" or value == "" then
		return {}
	end
	return string.split(value, ",")
end

local function titleText(keys: { string }): string
	if #keys > LeaderboardConfig.CrownMaxNamedBoards then
		return `#1 on {#keys} boards`
	end
	local parts = {}
	for _, key in keys do
		table.insert(parts, boardName(key))
	end
	return `#1 {table.concat(parts, " & ")}`
end

local function setShown(model: Model, isShown: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isShown then 0 else 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = isShown
		end
	end
end

local function isHatching(): boolean
	local hatch = controllers.HatchController
	local ui = controllers.UIController
	return (hatch ~= nil and hatch:IsPlaying())
		or (ui ~= nil and ui:IsOpen(LeaderboardConfig.CrownHiddenScreen))
end

local function removeCrown(player: Player)
	local crown = crowns[player]
	crowns[player] = nil
	if crown then
		crown.Model:Destroy()
	end
end

local function refresh(player: Player)
	local keys = titleKeys(player)
	local character = player.Character
	local head = if character then character:FindFirstChild("Head") else nil
	if #keys == 0 or not head or not head:IsA("BasePart") then
		removeCrown(player)
		return
	end
	local crown = crowns[player]
	if not crown or crown.Weld.Part0 ~= head or not crown.Model.Parent then
		removeCrown(player)
		local asset = AssetRegistry.get(LeaderboardConfig.CrownAssetKey)
		if not asset:IsA("Model") or not asset.PrimaryPart then
			warn("[CrownController] Crown asset needs to be a Model with a PrimaryPart")
			asset:Destroy()
			return
		end
		local base = asset.PrimaryPart :: BasePart
		local weld = Instance.new("Weld")
		weld.Part0 = head
		weld.Part1 = base
		weld.Parent = base
		asset.Name = LeaderboardConfig.CrownName
		Typography.Apply(asset)
		asset.Parent = character
		local created: Crown = {
			Model = asset,
			Weld = weld,
			Offset = head.Size.Y / 2 + LeaderboardConfig.CrownHeight + base.Size.Y / 2,
		}
		crowns[player] = created
		crown = created
		setShown(asset, not isHidden)
	end
	local model = if crown then crown.Model else nil
	local label = if model then model:FindFirstChild("Title", true) else nil
	if label and label:IsA("TextLabel") then
		label.Text = titleText(keys)
	end
end

local function watch(player: Player)
	local playerTrove = trove:Extend()
	playerTroves[player] = playerTrove
	playerTrove:Connect(player:GetAttributeChangedSignal(LeaderboardConfig.TitlesAttribute), function()
		refresh(player)
	end)
	playerTrove:Connect(player.CharacterAdded, function(character: Model)
		removeCrown(player)
		character:WaitForChild("Head", 10)
		refresh(player)
	end)
	refresh(player)
end

local function unwatch(player: Player)
	removeCrown(player)
	local playerTrove = playerTroves[player]
	playerTroves[player] = nil
	if playerTrove then
		trove:Remove(playerTrove)
	end
end

function CrownController.ChatTag(_self: any, player: Player): string?
	local keys = titleKeys(player)
	if #keys == 0 then
		return nil
	end
	return `<font color="{LeaderboardConfig.ChatTagColor}">[#1 {boardName(keys[1])}]</font>`
end

function CrownController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function CrownController.Start(_self: any)
	trove:Connect(Players.PlayerAdded, watch)
	trove:Connect(Players.PlayerRemoving, unwatch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	trove:Connect(RunService.RenderStepped, function(dt: number)
		local hidden = isHatching()
		if hidden ~= isHidden then
			isHidden = hidden
			for _, crown in crowns do
				setShown(crown.Model, not hidden)
			end
		end
		angle = (angle + math.rad(LeaderboardConfig.CrownSpinDegrees) * dt) % (2 * math.pi)
		for _, crown in crowns do
			crown.Weld.C0 = CFrame.new(0, crown.Offset, 0) * CFrame.Angles(0, angle, 0)
		end
	end)
end

function CrownController.Destroy(_self: any)
	for player in crowns do
		removeCrown(player)
	end
	trove:Destroy()
	table.clear(playerTroves)
end

return CrownController
