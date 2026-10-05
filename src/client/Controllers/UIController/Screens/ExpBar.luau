--!strict

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

function ExpBar.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
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
	local filling = false
	local target = UDim2.fromScale(0, 1)
	local tween: Tween? = nil

	local function refresh(value: any)
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
			local bar = fill
			target = UDim2.fromScale(progress.Ratio, 1)
			local function play(size: UDim2): Tween
				if tween then
					tween:Cancel()
				end
				local created =
					TweenService:Create(bar, TweenInfo.new(LevelConfig.FillTweenSeconds), { Size = size })
				tween = created
				created:Play()
				return created
			end
			if lastLevel == 0 or progress.Level < lastLevel then
				filling = false
				if tween then
					tween:Cancel()
					tween = nil
				end
				bar.Size = target
			elseif progress.Level > lastLevel then
				if not filling then
					filling = true
					play(UDim2.fromScale(1, 1)).Completed:Once(function(state: Enum.PlaybackState)
						if state ~= Enum.PlaybackState.Completed or not filling then
							return
						end
						filling = false
						bar.Size = UDim2.fromScale(0, 1)
						play(target)
					end)
				end
			elseif not filling then
				play(target)
			end
		end
		lastLevel = progress.Level
	end

	refresh(dataController:Get({ "Strength" }))
	trove:Add(dataController:Observe({ "Strength" }, refresh))

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
