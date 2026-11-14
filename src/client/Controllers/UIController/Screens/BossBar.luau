--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local BossBarConfig = require(ReplicatedStorage.Config.BossBarConfig)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local BossHearts = require(script.Parent.Parent.BossHearts)
local Types = require(script.Parent.Parent.Types)

local Phases = BossConfig.Phases

type Subject = {
	Model: Model,
	Holder: Instance,
	IsDiamond: boolean,
}

local BossBar = {}

local function find(root: Instance, name: string, class: string): Instance?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(class) then
		return found
	end
	warn(`[BossBar] Missing {class} "{name}" in {root:GetFullName()}`)
	return nil
end

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function paintLabel(label: TextLabel?, colors: BossBarConfig.TitleColors)
	if not label then
		return
	end
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = colors.Color
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = colors.Stroke
	end
end

local function textWidth(label: TextLabel): number
	local designHeight = label.Size.Y.Offset
	local shownHeight = label.AbsoluteSize.Y
	return if designHeight > 0 and shownHeight > 0 then label.TextBounds.X * designHeight / shownHeight else 0
end

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function BossBar.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local chopController = context.Controllers.ChopController
	local player = Players.LocalPlayer

	local root = find(gui, "Root", "Frame") :: Frame?
	local body = find(gui, "Body", "Frame") :: Frame?
	if not root or not body then
		return {
			Modal = false,
			StartsOpen = false,
			Open = function(_self: Types.Screen) end,
			Close = function(_self: Types.Screen) end,
			Destroy = function(_self: Types.Screen)
				trove:Destroy()
			end,
		}
	end
	local screenScale = root:FindFirstChild("ScreenScale")
	local popScale = body:FindFirstChild("PopScale")
	local title = find(body, "Title", "TextLabel") :: TextLabel?
	local titleShadow = find(body, "TitleShadow", "TextLabel") :: TextLabel?
	local enraged = find(body, BossBarConfig.EnragedLabelName, "TextLabel") :: TextLabel?
	local enragedShadow = find(body, BossBarConfig.EnragedShadowName, "TextLabel") :: TextLabel?
	local basePositions: { [TextLabel]: UDim2 } = {}
	for _, label in { title, titleShadow, enraged, enragedShadow } :: { TextLabel? } do
		if label then
			basePositions[label] = label.Position
		end
	end
	paintLabel(enraged, BossBarConfig.EnragedTitle)
	for _, label in { enraged, enragedShadow } :: { TextLabel? } do
		if label then
			label.Text = BossBarConfig.EnragedText
			label.Visible = false
		end
	end
	local fill = find(body, "Fill", "Frame") :: Frame?
	local ghost = find(body, "Ghost", "Frame") :: Frame?
	local flash = find(body, "Flash", "Frame") :: Frame?
	local fillGradient = if fill then fill:FindFirstChildWhichIsA("UIGradient") else nil
	local divider = find(body, "Divider", "Frame") :: Frame?
	local timer = find(body, "Timer", "TextLabel") :: TextLabel?
	local timerShadow = find(body, "TimerShadow", "TextLabel") :: TextLabel?
	local timerPulse = if timer then timer:FindFirstChild("PulseScale") else nil
	local timerColor = if timer then timer.TextColor3 else Color3.new(1, 1, 1)
	local heartsFrame = find(body, "Hearts", "Frame") :: Frame?
	local hearts = if heartsFrame then BossHearts.new(heartsFrame) else nil
	if hearts then
		trove:Add(hearts.Destroy)
	end

	local subject: Subject? = nil
	local shown = false
	local exiting = false
	local enterStart = 0
	local shownRatio = 1
	local ghostRatio = 1
	local ghostHoldUntil = 0
	local flashUntil = 0
	local shakeUntil = 0
	local shakePixels = 0
	local wasMad: boolean? = nil
	local paintedKey = ""
	local timerText = ""
	local wasWarning = false
	local wasChopping: boolean? = nil
	local lastRemaining = 0

	local function scale(): number
		return if screenScale and screenScale:IsA("UIScale") then screenScale.Scale else 1
	end

	local function pop(
		target: number,
		seconds: number,
		style: Enum.EasingStyle,
		direction: Enum.EasingDirection
	)
		if popScale and popScale:IsA("UIScale") then
			TweenService:Create(popScale, TweenInfo.new(seconds, style, direction), { Scale = target }):Play()
		end
	end

	local function pulseTimer()
		if timerPulse and timerPulse:IsA("UIScale") then
			timerPulse.Scale = BossBarConfig.TimerPulseScale
			TweenService:Create(timerPulse, TweenInfo.new(BossBarConfig.TimerPulseSeconds), { Scale = 1 })
				:Play()
		end
	end

	local function shake(pixels: number)
		shakePixels = math.max(pixels, if os.clock() < shakeUntil then shakePixels else 0)
		shakeUntil = os.clock() + BossBarConfig.ShakeSeconds
	end

	local function setTimer(text: string, isWarning: boolean)
		if text == timerText and isWarning == wasWarning then
			return
		end
		if isWarning and text ~= timerText and text ~= "" then
			pulseTimer()
		end
		timerText = text
		wasWarning = isWarning
		for _, label in { timer, timerShadow } :: { TextLabel? } do
			if label then
				label.Text = text
				label.Visible = text ~= ""
			end
		end
		if timer then
			timer.TextColor3 = if isWarning then BossBarConfig.TimerWarnColor else timerColor
		end
	end

	local function placeTitle(isMad: boolean)
		local nameShift = 0
		local enragedShift = 0
		if isMad and title and enraged then
			local gap = BossBarConfig.EnragedGapPixels
			nameShift = (textWidth(enraged) + gap) / 2
			enragedShift = -(textWidth(title) + gap) / 2
		end
		local shifts: { { Label: TextLabel?, Shift: number } } = {
			{ Label = title, Shift = nameShift },
			{ Label = titleShadow, Shift = nameShift },
			{ Label = enraged, Shift = enragedShift },
			{ Label = enragedShadow, Shift = enragedShift },
		}
		for _, entry in shifts do
			local label = entry.Label
			local base = if label then basePositions[label] else nil
			if label and base then
				label.Position = base + UDim2.fromOffset(entry.Shift, 0)
			end
		end
		for _, label in { enraged, enragedShadow } :: { TextLabel? } do
			if label then
				label.Visible = isMad
			end
		end
	end

	local function paint(current: Subject, isMad: boolean)
		local key = current.Model:GetAttribute(BossConfig.BossAttribute)
		local bossKey = if current.IsDiamond
			then DiamondRockConfig.ModelName
			elseif type(key) == "string" then key
			else ""
		local paintKey = `{bossKey}{isMad}`
		if paintKey == paintedKey then
			return
		end
		paintedKey = paintKey
		paintLabel(
			title,
			if current.IsDiamond
				then BossBarConfig.DiamondTitle
				else BossBarConfig.Titles[bossKey] or BossBarConfig.DefaultTitle
		)
		local data = BossConfig.Bosses[bossKey]
		local text = if current.IsDiamond
			then DiamondRockConfig.DisplayName
			elseif data then data.DisplayName
			else "Boss"
		for _, label in { title, titleShadow } :: { TextLabel? } do
			if label then
				label.Text = text
			end
		end
	end

	local function healthRatio(holder: Instance): number
		local maxHealth = numberAttribute(holder, BossConfig.MaxHealthAttribute)
		return if maxHealth > 0
			then math.clamp(numberAttribute(holder, BossConfig.HealthAttribute) / maxHealth, 0, 1)
			else 1
	end

	local function isInArena(): boolean
		local character = player.Character
		local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local arena = workspace:FindFirstChild(BossConfig.ArenaName)
		local floor = if arena then arena:FindFirstChild(BossBarConfig.FloorName) else nil
		if not rootPart or not rootPart:IsA("BasePart") or not floor or not floor:IsA("BasePart") then
			return false
		end
		local offset = floor.CFrame:PointToObjectSpace(rootPart.Position)
		local margin = BossBarConfig.ArenaMarginStuds
		return math.abs(offset.X) <= floor.Size.X / 2 + margin
			and math.abs(offset.Z) <= floor.Size.Z / 2 + margin
	end

	local function isChoppingBoss(model: Model): boolean
		local target = if chopController then chopController:GetTarget() else nil
		return target ~= nil and target:IsDescendantOf(model)
	end

	local function refreshHearts()
		if hearts then
			local health = player:GetAttribute(BossConfig.PlayerHealthAttribute)
			hearts.Set(if type(health) == "number" then health else nil)
		end
	end
	trove:Connect(player:GetAttributeChangedSignal(BossConfig.PlayerHealthAttribute), refreshHearts)
	refreshHearts()

	local function show(current: Subject)
		shown = true
		exiting = false
		root.Visible = true
		enterStart = os.clock()
		shownRatio = 0
		ghostRatio = 0
		wasMad = nil
		paintedKey = ""
		timerText = "-"
		if popScale and popScale:IsA("UIScale") then
			popScale.Scale = 0
		end
		pop(
			BossBarConfig.BarScale,
			BossBarConfig.EnterPopSeconds,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)
		paint(current, current.Model:GetAttribute(BossConfig.MadAttribute) == true)
		if divider then
			divider.Visible = not current.IsDiamond
		end
	end

	local function setBottom(value: number?)
		if gui:GetAttribute(BossBarConfig.BottomAttribute) ~= value then
			gui:SetAttribute(BossBarConfig.BottomAttribute, value)
		end
	end

	local function updateBottom()
		local bottom = 0
		for _, item in { body:FindFirstChild("Bar"), timer, heartsFrame } :: { Instance? } do
			if item and item:IsA("GuiObject") and item.Visible then
				bottom = math.max(bottom, item.AbsolutePosition.Y + item.AbsoluteSize.Y)
			end
		end
		setBottom(if bottom > 0 then math.ceil(bottom) else nil)
	end

	local function hide()
		shown = false
		exiting = false
		root.Visible = false
		setBottom(nil)
	end

	local function exit()
		if exiting then
			return
		end
		exiting = true
		task.delay(BossBarConfig.DefeatDrainSeconds, function()
			if exiting then
				pop(0, BossBarConfig.ExitSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			end
		end)
	end

	local function step(dt: number)
		local current = subject
		if not current or not current.Model.Parent then
			if shown then
				hide()
			end
			return
		end
		local model = current.Model
		local holder = current.Holder
		local chopping = isChoppingBoss(model)
		local remaining = math.max(
			0,
			math.ceil(numberAttribute(holder, BossConfig.EndsAtAttribute) - workspace:GetServerTimeNow())
		)
		local phase = if not current.IsDiamond
			then numberAttribute(model, BossConfig.PhaseAttribute)
			elseif numberAttribute(holder, DiamondRockConfig.HealthAttribute) <= 0 then Phases.Defeated
			elseif remaining <= 0 then Phases.Leaving
			else Phases.Fighting
		local ending = phase == Phases.Defeated or phase == Phases.Leaving
		local wanted = chopping or isInArena()
		if not shown then
			if wanted and not ending then
				show(current)
			else
				return
			end
		elseif not wanted and not exiting then
			hide()
			return
		end

		if chopping ~= wasChopping then
			wasChopping = chopping
			local offset = (
				if chopping then BossBarConfig.ChopOffsetPixels else BossBarConfig.ArenaOffsetPixels
			) + root.Size.Y.Offset / 2 * (BossBarConfig.BarScale - 1)
			TweenService:Create(
				root,
				TweenInfo.new(BossBarConfig.MoveSeconds, Enum.EasingStyle.Quad),
				{ Position = UDim2.new(0.5, 0, 0, offset * scale()) }
			):Play()
		end
		if heartsFrame then
			heartsFrame.Visible = not chopping
				and not current.IsDiamond
				and type(player:GetAttribute(BossConfig.PlayerHealthAttribute)) == "number"
		end

		local isMad = model:GetAttribute(BossConfig.MadAttribute) == true and not current.IsDiamond
		paint(current, isMad)
		placeTitle(isMad)
		if isMad and wasMad == false then
			shake(BossBarConfig.MadShakePixels)
			flashUntil = os.clock() + BossBarConfig.FlashSeconds * 2
			pulseTimer()
		end
		wasMad = isMad

		local now = os.clock()
		local target = if phase == Phases.Defeated then 0 else healthRatio(holder)
		local entering = now - enterStart < BossBarConfig.EnterFillSeconds
		if phase == Phases.Defeated or phase == Phases.Leaving then
			exit()
		end
		if entering then
			local alpha = (now - enterStart) / BossBarConfig.EnterFillSeconds
			shownRatio = target * (1 - (1 - alpha) ^ 3)
			ghostRatio = shownRatio
		elseif target < shownRatio - 0.0001 then
			if shownRatio - target >= BossBarConfig.BigHitRatio then
				shake(BossBarConfig.HitShakePixels)
			end
			if not current.IsDiamond and shownRatio > 0.5 and target <= 0.5 then
				shake(BossBarConfig.MadShakePixels)
			end
			ghostRatio = math.max(ghostRatio, shownRatio)
			shownRatio = target
			ghostHoldUntil = now + BossBarConfig.GhostDelaySeconds
			flashUntil = now + BossBarConfig.FlashSeconds
		elseif target > shownRatio then
			shownRatio = target
			ghostRatio = math.max(ghostRatio, target)
		end
		if now >= ghostHoldUntil and ghostRatio > shownRatio then
			ghostRatio = ghostRatio
				+ (shownRatio - ghostRatio) * math.min(1, dt * BossBarConfig.GhostDrainSpeed)
			if ghostRatio - shownRatio < 0.001 then
				ghostRatio = shownRatio
			end
		end
		if fill then
			fill.Size = UDim2.fromScale(shownRatio, 1)
		end
		if ghost then
			ghost.Size = UDim2.fromScale(ghostRatio, 1)
		end
		if fillGradient then
			fillGradient.Color = if phase == Phases.Finish
				then BossBarConfig.FinishFill
				elseif isMad then BossBarConfig.MadFill
				elseif current.IsDiamond then BossBarConfig.DiamondFill
				else BossBarConfig.NormalFill
		end
		if flash then
			local pulse = if phase == Phases.Finish
				then BossBarConfig.FinishPulseTransparency
				elseif isMad then BossBarConfig.MadPulseTransparency
				else 1
			local wave = (math.sin(now * BossBarConfig.PulseSpeed) + 1) / 2
			flash.BackgroundTransparency = if now < flashUntil
				then BossBarConfig.FlashTransparency
				else 1 - (1 - pulse) * wave
		end

		if now < shakeUntil then
			local fade = (shakeUntil - now) / BossBarConfig.ShakeSeconds
			local amount = shakePixels * fade
			body.Position =
				UDim2.new(0.5, (math.random() * 2 - 1) * amount, 0.5, (math.random() * 2 - 1) * amount)
		else
			body.Position = UDim2.fromScale(0.5, 0.5)
		end

		if phase == Phases.Sleeping then
			setTimer(string.format(BossConfig.SleepingLabel, remaining // 60, remaining % 60), false)
		elseif phase == Phases.Waking or ending then
			setTimer("", false)
		else
			if remaining > lastRemaining + 1 then
				pulseTimer()
			end
			local warning = if current.IsDiamond
				then DiamondRockConfig.WarningSeconds
				else BossConfig.WarningSeconds
			setTimer(formatTime(remaining), remaining <= warning)
		end
		lastRemaining = remaining
		if exiting then
			setBottom(nil)
		else
			updateBottom()
		end
	end

	local function track()
		local found: Subject? = nil
		for _, instance in CollectionService:GetTagged(BossConfig.Tag) do
			if instance:IsA("Model") then
				found = { Model = instance, Holder = instance, IsDiamond = false }
				break
			end
		end
		if not found then
			for _, instance in CollectionService:GetTagged(DiamondRockConfig.Tag) do
				local rock = instance:FindFirstChild(BossBarConfig.DiamondPartName)
				if instance:IsA("Model") and rock then
					found = { Model = instance, Holder = rock, IsDiamond = true }
					break
				end
			end
		end
		local previous = subject
		local foundModel = if found then found.Model else nil
		local previousModel = if previous then previous.Model else nil
		if foundModel ~= previousModel then
			subject = found
			hide()
			wasChopping = nil
		end
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(BossConfig.Tag), track)
	trove:Connect(
		CollectionService:GetInstanceAddedSignal(DiamondRockConfig.Tag),
		function(instance: Instance)
			instance:WaitForChild(BossBarConfig.DiamondPartName, 10)
			track()
		end
	)
	for _, tag in { BossConfig.Tag, DiamondRockConfig.Tag } do
		trove:Connect(CollectionService:GetInstanceRemovedSignal(tag), function()
			task.defer(track)
		end)
	end
	track()
	root.Visible = false

	local openTrove = Trove.new()
	trove:Add(openTrove)

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			openTrove:Connect(RunService.Heartbeat, step)
		end,
		Close = function(_self: Types.Screen)
			openTrove:Clean()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return BossBar
