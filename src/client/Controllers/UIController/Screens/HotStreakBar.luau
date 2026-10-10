--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HotStreakConfig = require(ReplicatedStorage.Config.HotStreakConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local HotStreakBar = {}

local function findPair(container: Instance, name: string): (TextLabel?, TextLabel?)
	local main = container:FindFirstChild(name)
	if not main or not main:IsA("TextLabel") then
		warn(`[HotStreakBar] Missing TextLabel "{name}" in {container:GetFullName()}`)
		return nil, nil
	end
	local copy = container:FindFirstChild(name .. HudConfig.ShadowSuffix)
	return main, if copy and copy:IsA("TextLabel") then copy else nil
end

local function setPair(main: TextLabel?, copy: TextLabel?, text: string)
	if main then
		main.Text = text
	end
	if copy then
		copy.Text = text
	end
end

function HotStreakBar.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controller = context.Controllers.HotStreakController
	ViewportScale.Bind(gui, trove)

	local found = gui:FindFirstChild(HotStreakConfig.BarContainer)
	local container: CanvasGroup? = if found and found:IsA("CanvasGroup") then found else nil
	if not container then
		warn(`[HotStreakBar] Missing CanvasGroup "{HotStreakConfig.BarContainer}" in {gui:GetFullName()}`)
	end
	local fillInstance = gui:FindFirstChild("Fill", true)
	local fill: Frame? = if fillInstance and fillInstance:IsA("Frame") then fillInstance else nil
	if not fill then
		warn(`[HotStreakBar] Missing Frame "Fill" in {gui:GetFullName()}`)
	end
	local gradient = if fill then fill:FindFirstChildWhichIsA("UIGradient") else nil
	local studsInstance = if fill then fill:FindFirstChild("StudTexture") else nil
	local studs: ImageLabel? = if studsInstance and studsInstance:IsA("ImageLabel")
		then studsInstance
		else nil
	local tierLabel, tierShadow = nil, nil
	local progressLabel, progressShadow = nil, nil
	if container then
		tierLabel, tierShadow = findPair(container, "TierLabel")
		progressLabel, progressShadow = findPair(container, "ProgressLabel")
	end

	local levelGui: ScreenGui? = nil
	local levelContainer: GuiObject? = nil
	local levelScale: UIScale? = nil
	local baseY = if container then container.Position.Y.Offset else 0
	local slideTween: Tween? = nil
	local fillTween: Tween? = nil
	local expiresAt = 0
	local shakeStart: number? = nil

	local function targetY(): number
		local level = levelContainer
		if not level then
			return baseY
		end
		local scale = if levelScale then levelScale.Scale else 1
		local bottom = level.Position.Y.Offset
		if levelGui and not levelGui.Enabled then
			return bottom
		end
		return bottom - level.Size.Y.Offset * scale - HotStreakConfig.BarGapPixels * scale
	end

	local function place(animate: boolean)
		local box = container
		if not box then
			return
		end
		baseY = targetY()
		if slideTween then
			slideTween:Cancel()
			slideTween = nil
		end
		local goal = UDim2.new(box.Position.X.Scale, 0, box.Position.Y.Scale, baseY)
		if animate and box.Visible then
			local tween = TweenService:Create(
				box,
				TweenInfo.new(
					HotStreakConfig.BarSlideSeconds,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{ Position = goal }
			)
			slideTween = tween
			tween:Play()
		else
			box.Position = goal
		end
	end

	local playerGui = gui.Parent
	if playerGui then
		task.spawn(function()
			local instance = playerGui:WaitForChild(HotStreakConfig.LevelBarScreen, 15)
			if not instance or not instance:IsA("ScreenGui") then
				warn(`[HotStreakBar] Missing ScreenGui "{HotStreakConfig.LevelBarScreen}"; bar stays put`)
				return
			end
			local level = instance:FindFirstChild(HotStreakConfig.BarContainer)
			if not level or not level:IsA("GuiObject") then
				warn(`[HotStreakBar] Missing "{HotStreakConfig.BarContainer}" in {instance:GetFullName()}`)
				return
			end
			levelGui = instance
			levelContainer = level
			local scaleInstance = level:FindFirstChild(HotStreakConfig.BarScaleName)
			if scaleInstance and scaleInstance:IsA("UIScale") then
				levelScale = scaleInstance
				trove:Connect(scaleInstance:GetPropertyChangedSignal("Scale"), function()
					place(false)
				end)
			end
			trove:Connect(instance:GetPropertyChangedSignal("Enabled"), function()
				place(true)
			end)
			place(false)
		end)
	end

	local function setFill(ratio: number)
		local bar = fill
		if not bar then
			return
		end
		if fillTween then
			fillTween:Cancel()
		end
		local tween = TweenService:Create(
			bar,
			TweenInfo.new(HotStreakConfig.BarFillSeconds),
			{ Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) }
		)
		fillTween = tween
		tween:Play()
	end

	local function paint(definition: HotStreakConfig.Tier)
		if gradient then
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, definition.Main),
				ColorSequenceKeypoint.new(0.5, definition.Light),
				ColorSequenceKeypoint.new(1, definition.Main),
			})
		end
		if studs then
			studs.ImageColor3 = definition.Dark
		end
	end

	local function refresh(tier: number, count: number, newExpiresAt: number)
		expiresAt = newExpiresAt
		local box = container
		if not box then
			return
		end
		if count <= 0 then
			box.Visible = false
			return
		end
		local current = HotStreakConfig.Tiers[tier]
		local nextTier = HotStreakConfig.Tiers[tier + 1]
		paint(current or HotStreakConfig.Tiers[1])
		if not current then
			local first = HotStreakConfig.Tiers[1]
			setPair(tierLabel, tierShadow, HotStreakConfig.BarIdleText)
			setPair(progressLabel, progressShadow, `{count}/{first.Chops}`)
			setFill(count / first.Chops)
		elseif nextTier then
			local done = count - current.Chops
			local needed = nextTier.Chops - current.Chops
			setPair(tierLabel, tierShadow, `x{current.Multiplier}`)
			setPair(progressLabel, progressShadow, `{done}/{needed}`)
			setFill(done / needed)
		else
			setPair(tierLabel, tierShadow, `x{current.Multiplier}`)
			setPair(progressLabel, progressShadow, HotStreakConfig.BarMaxText)
			setFill(1)
		end
		if not box.Visible then
			place(false)
			box.GroupTransparency = 0
			box.Visible = true
		end
	end

	if controller then
		trove:Add(controller.Changed:Connect(refresh))
		trove:Add(controller.Dropped:Connect(function()
			shakeStart = os.clock()
		end))
		refresh(controller:GetTier(), controller:GetCount(), controller:GetExpiresAt())
	else
		warn("[HotStreakBar] HotStreakController missing; bar disabled")
		if container then
			container.Visible = false
		end
	end

	trove:Add(RunService.Heartbeat:Connect(function()
		local box = container
		if not box or not box.Visible then
			return
		end
		local remaining = expiresAt - workspace:GetServerTimeNow()
		if expiresAt > 0 and remaining <= HotStreakConfig.BlinkSeconds then
			local isDim = math.floor(remaining * HotStreakConfig.BlinkHertz * 2) % 2 == 1
			box.GroupTransparency = if isDim then HotStreakConfig.BlinkDimTransparency else 0
		else
			box.GroupTransparency = 0
		end
		local started = shakeStart
		if not started or slideTween and slideTween.PlaybackState == Enum.PlaybackState.Playing then
			return
		end
		local elapsed = os.clock() - started
		local offset = 0
		if elapsed >= HotStreakConfig.BarShakeSeconds then
			shakeStart = nil
		else
			local decay = 1 - elapsed / HotStreakConfig.BarShakeSeconds
			offset = math.sin(elapsed * HotStreakConfig.BarShakeHertz * 2 * math.pi)
				* HotStreakConfig.BarShakePixels
				* decay
		end
		box.Position = UDim2.new(box.Position.X.Scale, offset, box.Position.Y.Scale, baseY)
	end))

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
			if slideTween then
				slideTween:Cancel()
			end
			if fillTween then
				fillTween:Cancel()
			end
			trove:Destroy()
		end,
	}
end

return HotStreakBar
