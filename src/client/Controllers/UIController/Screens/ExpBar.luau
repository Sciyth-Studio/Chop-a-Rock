--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LevelConfig = require(ReplicatedStorage.Config.LevelConfig)
local Level = require(ReplicatedStorage.Utils.Level)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local ExpBar = {}

function ExpBar.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local fillInstance = gui:FindFirstChild("Fill", true)
	local fill: Frame? = if fillInstance and fillInstance:IsA("Frame") then fillInstance else nil
	if not fill then
		warn(`[ExpBar] Missing Frame "Fill" in {gui:GetFullName()}`)
	end

	local function findPair(name: string): (TextLabel?, TextLabel?)
		local instance = gui:FindFirstChild(name, true)
		if not instance or not instance:IsA("TextLabel") then
			warn(`[ExpBar] Missing TextLabel "{name}" in {gui:GetFullName()}`)
			return nil, nil
		end
		local copy = if instance.Parent
			then instance.Parent:FindFirstChild(name .. HudConfig.ShadowSuffix)
			else nil
		return instance, if copy and copy:IsA("TextLabel") then copy else nil
	end

	local function setPair(main: TextLabel?, copy: TextLabel?, text: string)
		if main then
			main.Text = text
		end
		if copy then
			copy.Text = text
		end
	end

	local levelLabel, levelShadow = findPair("LevelLabel")
	local strengthLabel, strengthShadow = findPair("StrengthLabel")

	local lastLevel = 0
	local tween: Tween? = nil

	local function refresh()
		local value = player:GetAttribute("Strength")
		local progress = Level.FromStrength(if type(value) == "number" then value else 0)
		setPair(levelLabel, levelShadow, `{LevelConfig.LevelWord} {progress.Level}`)
		setPair(
			strengthLabel,
			strengthShadow,
			`{NumberFormat.Compact(math.floor(progress.Current))}/{NumberFormat.Compact(
				math.ceil(progress.Needed)
			)}`
		)
		if fill then
			local size = UDim2.fromScale(progress.Ratio, 1)
			if tween then
				tween:Cancel()
				tween = nil
			end
			if progress.Level ~= lastLevel then
				fill.Size = size
			else
				local created =
					TweenService:Create(fill, TweenInfo.new(LevelConfig.FillTweenSeconds), { Size = size })
				tween = created
				created:Play()
			end
		end
		lastLevel = progress.Level
	end

	trove:Connect(player:GetAttributeChangedSignal("Strength"), refresh)
	refresh()

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			if tween then
				tween:Cancel()
			end
			trove:Destroy()
		end,
	}
end

return ExpBar
