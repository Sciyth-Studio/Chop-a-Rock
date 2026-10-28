--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LoadingCoverConfig = require(ReplicatedStorage.Config.LoadingCoverConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

type Bouncer = { Image: ImageLabel, Position: UDim2 }

local LoadingCover = {}

local BOUNCE_NAMES = { "Bloky", "BlokyShadow" }

function LoadingCover.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local cover = gui:FindFirstChild("Cover")
	if not (cover and cover:IsA("CanvasGroup")) then
		warn(`[LoadingCover] Missing CanvasGroup "Cover" in {gui:GetFullName()}`)
		cover = nil
	end
	local bouncers: { Bouncer } = {}
	for _, name in BOUNCE_NAMES do
		local found = gui:FindFirstChild(name, true)
		if found and found:IsA("ImageLabel") then
			table.insert(bouncers, { Image = found, Position = found.Position })
		end
	end
	local bar = gui:FindFirstChild("ProgressBar", true)
	local fill = if bar then bar:FindFirstChild("Fill", true) else nil
	if not (fill and fill:IsA("Frame")) then
		warn(`[LoadingCover] Missing ProgressBar.Track.Fill in {gui:GetFullName()}`)
		fill = nil
	end
	local ribs = if fill then fill:FindFirstChild("Ribs") else nil
	if not (ribs and ribs:IsA("ImageLabel")) then
		ribs = nil
	end
	local statusLabels: { TextLabel } = {}
	for _, name in { "Status", "Status" .. HudConfig.ShadowSuffix } do
		local found = gui:FindFirstChild(name, true)
		if found and found:IsA("TextLabel") then
			table.insert(statusLabels, found)
		end
	end

	local runTrove = trove:Extend()
	local openedAt = os.clock()
	local closeThread: thread? = nil
	local target = 0
	local displayed = 0
	local ribOffset = 0
	local isFinishing = false

	local function cancelClose()
		local thread = closeThread
		if thread then
			closeThread = nil
			task.cancel(thread)
		end
	end

	local function setFill(value: number)
		if fill and fill:IsA("Frame") then
			fill.Size = UDim2.fromScale(value, 1)
		end
	end

	local function reach(stage: string)
		local value = LoadingCoverConfig.Milestones[stage]
		if value and value > target then
			target = value
		end
		local text = LoadingCoverConfig.StatusTexts[stage]
		if text then
			for _, label in statusLabels do
				label.Text = text
			end
		end
	end

	local function step(dt: number)
		local phase = (os.clock() % LoadingCoverConfig.BounceSeconds) / LoadingCoverConfig.BounceSeconds
		local lift = math.floor(math.sin(phase * math.pi) * LoadingCoverConfig.BounceHeightPixels)
		for _, bouncer in bouncers do
			local base = bouncer.Position
			bouncer.Image.Position =
				UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset - lift)
		end
		if not isFinishing then
			if displayed < target - 0.001 then
				displayed += (target - displayed) * (1 - math.exp(-LoadingCoverConfig.CatchUpRate * dt))
			else
				local cap = target + (1 - target) * LoadingCoverConfig.CreepShare
				displayed += math.max(cap - displayed, 0) * (1 - math.exp(-LoadingCoverConfig.CreepRate * dt))
			end
			setFill(displayed)
		end
		if ribs and ribs:IsA("ImageLabel") then
			local speed = LoadingCoverConfig.RibSpeedMin
				+ (LoadingCoverConfig.RibSpeedMax - LoadingCoverConfig.RibSpeedMin) * displayed
			ribOffset = (ribOffset + speed * dt) % LoadingCoverConfig.RibTilePixels
			ribs.Position = UDim2.fromOffset(-ribOffset, 0)
		end
	end

	local dataController = context.Controllers.DataController
	if dataController and dataController.Loaded then
		trove:Connect(dataController.Loaded, function()
			reach("DataLoaded")
		end)
	end
	local intro = context.Controllers.IntroController
	if intro and intro.LoadProgressed then
		trove:Connect(intro.LoadProgressed, reach)
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			cancelClose()
			runTrove:Clean()
			isFinishing = false
			target = 0
			reach("Joined")
			displayed = target
			if dataController and dataController:IsLoaded() then
				reach("DataLoaded")
			end
			setFill(displayed)
			gui.Enabled = true
			if cover and cover:IsA("CanvasGroup") then
				cover.GroupTransparency = 0
			end
			runTrove:Connect(RunService.RenderStepped, step)
			runTrove:Add(task.delay(LoadingCoverConfig.MaxSeconds, function()
				context.Close(LoadingCoverConfig.ScreenName)
			end))
		end,
		Close = function(_self: Types.Screen)
			cancelClose()
			local holdSeconds = math.max(LoadingCoverConfig.MinSeconds - (os.clock() - openedAt), 0)
			closeThread = task.delay(holdSeconds, function()
				if gui.Enabled then
					isFinishing = true
					if fill and fill:IsA("Frame") then
						local finish = TweenService:Create(
							fill,
							TweenInfo.new(
								LoadingCoverConfig.FinishSeconds,
								Enum.EasingStyle.Quad,
								Enum.EasingDirection.In
							),
							{ Size = UDim2.fromScale(1, 1) }
						)
						finish:Play()
						finish.Completed:Wait()
						displayed = 1
						task.wait(LoadingCoverConfig.FinishHoldSeconds)
					end
					if cover and cover:IsA("CanvasGroup") then
						local fade = TweenService:Create(
							cover,
							TweenInfo.new(
								LoadingCoverConfig.FadeSeconds,
								Enum.EasingStyle.Quad,
								Enum.EasingDirection.Out
							),
							{ GroupTransparency = 1 }
						)
						fade:Play()
						fade.Completed:Wait()
					end
				end
				closeThread = nil
				runTrove:Clean()
				gui.Enabled = false
			end)
		end,
		Destroy = function(_self: Types.Screen)
			cancelClose()
			trove:Destroy()
		end,
	}
end

return LoadingCover
