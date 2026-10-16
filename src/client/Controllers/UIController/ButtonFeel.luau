--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local UIFeelConfig = require(ReplicatedStorage.Config.UIFeelConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

type Tint = {
	Target: GuiObject,
	Property: string,
	Base: Color3,
}

type Tilt = {
	Target: GuiObject,
	Base: number,
}

export type ButtonFeel = {
	Bind: (gui: LayerCollector) -> (),
	Feedback: (button: GuiButton?, isSuccess: boolean) -> (),
}

local ButtonFeel = {}

local black = Color3.new(0, 0, 0)
local hoverInfo = TweenInfo.new(UIFeelConfig.HoverSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pressInfo = TweenInfo.new(UIFeelConfig.PressSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local releaseInfo =
	TweenInfo.new(UIFeelConfig.ReleaseSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tiltInfo = TweenInfo.new(UIFeelConfig.TiltSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local successUpInfo =
	TweenInfo.new(UIFeelConfig.SuccessUpSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local successSettleInfo =
	TweenInfo.new(UIFeelConfig.SuccessSettleSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local shakeInfo =
	TweenInfo.new(UIFeelConfig.ShakeStepSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local shimmerInfo = TweenInfo.new(
	UIFeelConfig.ShimmerSweepSeconds,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,
	false,
	UIFeelConfig.ShimmerGapSeconds
)

local function isCovering(button: GuiButton): boolean
	return button.BackgroundTransparency >= 1
		and button.Size == UDim2.fromScale(1, 1)
		and button.Position == UDim2.new()
end

local function findVisual(button: GuiButton): GuiObject?
	if not isCovering(button) then
		return button
	end
	local parent = button.Parent
	return if parent and parent:IsA("GuiObject") then parent else nil
end

local function isOff(instance: Instance?): boolean
	return instance ~= nil and instance:GetAttribute(UIFeelConfig.FeelAttribute) == UIFeelConfig.FeelOff
end

local function findTilts(visual: GuiObject): { Tilt }
	local tilts: { Tilt } = {}
	if visual:GetAttribute(UIFeelConfig.TiltAttribute) ~= true then
		return tilts
	end
	for _, child in visual:GetChildren() do
		if
			child:IsA("GuiObject")
			and string.sub(child.Name, 1, #UIFeelConfig.TiltPrefix) == UIFeelConfig.TiltPrefix
		then
			table.insert(tilts, { Target = child, Base = child.Rotation })
		end
	end
	return tilts
end

local function findTint(visual: GuiObject): Tint?
	local track = visual:FindFirstChild(UIFeelConfig.TrackName)
	local fill = if track then track:FindFirstChild(UIFeelConfig.FillName) else nil
	if fill and fill:IsA("GuiObject") then
		return { Target = fill, Property = "BackgroundColor3", Base = fill.BackgroundColor3 }
	end
	if visual.BackgroundTransparency < 1 then
		return { Target = visual, Property = "BackgroundColor3", Base = visual.BackgroundColor3 }
	end
	if visual:IsA("ImageButton") or visual:IsA("ImageLabel") then
		return { Target = visual :: GuiObject, Property = "ImageColor3", Base = visual.ImageColor3 }
	end
	return nil
end

local function findShine(visual: GuiObject): (GuiObject?, UIGradient?)
	local shine = visual:FindFirstChild(UIFeelConfig.ShineName, true)
	if not shine or not shine:IsA("GuiObject") then
		return nil, nil
	end
	return shine, shine:FindFirstChildWhichIsA("UIGradient")
end

local function centerAnchor(visual: GuiObject)
	local shift = Vector2.new(0.5, 0.5) - visual.AnchorPoint
	if shift.Magnitude == 0 then
		return
	end
	local size = visual.Size
	visual.AnchorPoint = Vector2.new(0.5, 0.5)
	visual.Position = visual.Position
		+ UDim2.new(
			size.X.Scale * shift.X,
			size.X.Offset * shift.X,
			size.Y.Scale * shift.Y,
			size.Y.Offset * shift.Y
		)
end

local function prepareScale(visual: GuiObject): UIScale?
	local existing = visual:FindFirstChildWhichIsA("UIScale")
	if existing then
		if existing.Name ~= UIFeelConfig.ScaleName then
			return nil
		end
		existing.Scale = 1
		return existing
	end
	local parent = visual.Parent
	local layout = if parent then parent:FindFirstChildWhichIsA("UIGridStyleLayout") else nil
	if layout and not layout:IsA("UIGridLayout") then
		return nil
	end
	if not layout then
		centerAnchor(visual)
	end
	local scale = Instance.new("UIScale")
	scale.Name = UIFeelConfig.ScaleName
	scale.Parent = visual
	return scale
end

function ButtonFeel.new(trove: TroveInstance): ButtonFeel
	local isTouch = false
	local lastHoverSound = -math.huge
	local resets: { [GuiButton]: () -> () } = {}
	local feedbacks: { [GuiButton]: (isSuccess: boolean) -> () } = {}

	trove:Add(Input.PreferredInput.observe(function(preferred: Enum.PreferredInput)
		isTouch = preferred == Enum.PreferredInput.Touch
		return nil
	end))

	local function playHover()
		local now = os.clock()
		if now - lastHoverSound < UIFeelConfig.HoverSoundGapSeconds then
			return
		end
		lastHoverSound = now
		LocalSound.Play(UIFeelConfig.HoverSound)
	end

	local function bindButton(gui: LayerCollector, button: GuiButton)
		if resets[button] then
			return
		end
		local visual = findVisual(button)
		if isOff(button) or isOff(visual) then
			return
		end

		local buttonTrove = trove:Extend()
		local scale = if visual then prepareScale(visual) else nil
		local tint = if visual then findTint(visual) else nil
		local tilts: { Tilt } = if visual then findTilts(visual) else {}
		local isHovered = false
		local isPressed = false
		local releaseConnection: RBXScriptConnection? = nil

		local function apply(info: TweenInfo)
			if scale then
				local target = if isPressed
					then UIFeelConfig.PressScale
					elseif isHovered then UIFeelConfig.HoverScale
					else 1
				TweenService:Create(scale, info, { Scale = target }):Play()
			end
			if tint then
				local darken = if isPressed
					then UIFeelConfig.PressDarken
					elseif isHovered then UIFeelConfig.HoverDarken
					else 0
				TweenService:Create(tint.Target, info, { [tint.Property] = tint.Base:Lerp(black, darken) })
					:Play()
			end
			local angle = if isHovered or isPressed then UIFeelConfig.TiltDegrees else 0
			for _, tilt in tilts do
				TweenService:Create(tilt.Target, tiltInfo, { Rotation = tilt.Base + angle }):Play()
			end
		end

		local function stopRelease()
			if releaseConnection then
				releaseConnection:Disconnect()
				releaseConnection = nil
			end
		end

		local function reset()
			stopRelease()
			isHovered = false
			isPressed = false
			if scale then
				scale.Scale = 1
			end
			if tint then
				(tint.Target :: any)[tint.Property] = tint.Base
			end
			for _, tilt in tilts do
				tilt.Target.Rotation = tilt.Base
			end
		end

		local function hover()
			if isTouch or not visual or isHovered or not button.Interactable then
				return
			end
			isHovered = true
			apply(hoverInfo)
			playHover()
		end

		local function unhover()
			if not isHovered and not isPressed then
				return
			end
			isHovered = false
			isPressed = false
			stopRelease()
			apply(hoverInfo)
		end

		local function release()
			stopRelease()
			if not isPressed then
				return
			end
			isPressed = false
			apply(releaseInfo)
		end

		local function press()
			if not visual or not button.Interactable then
				return
			end
			isPressed = true
			apply(pressInfo)
			stopRelease()
			releaseConnection = UserInputService.InputEnded:Connect(function(input: InputObject)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					release()
				end
			end)
		end

		local shakeToken = 0
		local baseRotation = if visual then visual.Rotation else 0

		local function bounce()
			if not scale then
				return
			end
			local tween = TweenService:Create(scale, successUpInfo, { Scale = UIFeelConfig.SuccessScale })
			tween.Completed:Connect(function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed then
					apply(successSettleInfo)
				end
			end)
			tween:Play()
		end

		local function shake()
			local target = visual
			if not target then
				return
			end
			shakeToken += 1
			local token = shakeToken
			task.spawn(function()
				for _, degrees in UIFeelConfig.ShakeDegrees do
					if token ~= shakeToken or not target.Parent then
						return
					end
					local tween =
						TweenService:Create(target, shakeInfo, { Rotation = baseRotation + degrees })
					tween:Play()
					tween.Completed:Wait()
				end
			end)
		end

		feedbacks[button] = function(isSuccess: boolean)
			if isSuccess then
				bounce()
			else
				shake()
			end
		end
		buttonTrove:Add(function()
			feedbacks[button] = nil
			shakeToken += 1
		end)

		local shine: GuiObject?, shineGradient: UIGradient? = nil, nil
		if visual then
			shine, shineGradient = findShine(visual)
		end
		local shimmerTween: Tween? = nil

		local function refreshShimmer()
			if not shine then
				return
			end
			local isOn = button:GetAttribute(UIFeelConfig.ShimmerAttribute) == true
			if isOn == (shimmerTween ~= nil) then
				return
			end
			if shimmerTween then
				shimmerTween:Cancel()
				shimmerTween = nil
			end
			shine.Visible = isOn
			if isOn and shineGradient then
				shineGradient.Offset = Vector2.new(-1, 0)
				local tween = TweenService:Create(shineGradient, shimmerInfo, { Offset = Vector2.new(1, 0) })
				shimmerTween = tween
				tween:Play()
			end
		end

		if shine then
			refreshShimmer()
			buttonTrove:Connect(
				button:GetAttributeChangedSignal(UIFeelConfig.ShimmerAttribute),
				refreshShimmer
			)
			buttonTrove:Add(function()
				if shimmerTween then
					shimmerTween:Cancel()
					shimmerTween = nil
				end
			end)
		end

		buttonTrove:Connect(button.MouseEnter, hover)
		buttonTrove:Connect(button.MouseLeave, unhover)
		buttonTrove:Connect(button.SelectionGained, hover)
		buttonTrove:Connect(button.SelectionLost, unhover)
		buttonTrove:Connect(button.MouseButton1Down, press)
		buttonTrove:Connect(button.Activated, function()
			local key = button:GetAttribute(UIFeelConfig.ClickSoundAttribute)
			LocalSound.Play(if type(key) == "string" then key else UIFeelConfig.ClickSound)
		end)
		buttonTrove:Add(stopRelease)

		resets[button] = reset
		buttonTrove:Add(function()
			resets[button] = nil
		end)
		buttonTrove:Connect(button.AncestryChanged, function()
			if not button:IsDescendantOf(gui) then
				buttonTrove:Destroy()
			end
		end)
	end

	local function bind(gui: LayerCollector)
		for _, descendant in gui:GetDescendants() do
			if descendant:IsA("GuiButton") then
				bindButton(gui, descendant)
			end
		end
		trove:Connect(gui.DescendantAdded, function(descendant: Instance)
			if descendant:IsA("GuiButton") then
				bindButton(gui, descendant)
			end
		end)
		trove:Connect(gui:GetPropertyChangedSignal("Enabled"), function()
			if gui.Enabled then
				return
			end
			for button, reset in resets do
				if button:IsDescendantOf(gui) then
					reset()
				end
			end
		end)
	end

	local function feedback(button: GuiButton?, isSuccess: boolean)
		if not isSuccess then
			LocalSound.Play(UIFeelConfig.ErrorSound)
		end
		local play = if button then feedbacks[button] else nil
		if play then
			play(isSuccess)
		end
	end

	return {
		Bind = bind,
		Feedback = feedback,
	}
end

return ButtonFeel
