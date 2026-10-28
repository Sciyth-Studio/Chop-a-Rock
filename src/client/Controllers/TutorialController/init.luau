--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local AuraHint = require(ReplicatedStorage.AuraHint)
local CannonHint = require(ReplicatedStorage.CannonHint)
local RebirthHint = require(ReplicatedStorage.RebirthHint)
local RockHint = require(ReplicatedStorage.RockHint)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NotificationConfig = require(ReplicatedStorage.Config.NotificationConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local AuraHintView = require(script.AuraHint)
local CannonHintView = require(script.CannonHint)
local CameraTurn = require(script.CameraTurn)
local ChopHint = require(script.ChopHint)
local Guide = require(script.Guide)
local Layout = require(script.Layout)
local Locks = require(script.Locks)
local Spotlight = require(script.Spotlight)
local Targets = require(script.Targets)
local RebirthHintView = require(script.RebirthHint)
local RockHintView = require(script.RockHint)
local Teleports = require(script.Teleports)

type TroveInstance = typeof(Trove.new())
type Hidden = { Gui: ScreenGui, Parent: Instance }
type Session = {
	Trove: TroveInstance,
	CameraTurn: CameraTurn.State,
	Guide: Guide.Guide,
	ChopHint: ChopHint.State?,
	Layout: Layout.State,
	Spotlight: Spotlight.State?,
	Locks: Locks.State,
	LockClock: number,
}
type HintKind = {
	Shared: {
		StageOf: (data: any) -> number,
		IsActive: (stage: number) -> boolean,
		IsShown: (data: any) -> boolean,
	},
	View: (data: any, helpers: CannonHintView.Helpers) -> CannonHintView.View,
	ScreenName: string,
	IdleStages: { number },
	CloseStages: { number },
}
type HintSession = {
	Trove: TroveInstance,
	CameraTurn: CameraTurn.State,
	Kind: HintKind?,
	Guide: Guide.Guide,
	Layout: Layout.State,
	Spotlight: Spotlight.State?,
	Stage: number?,
}

local TutorialController = {
	Name = "TutorialController",
	_trove = nil :: TroveInstance?,
	_controllers = {} :: { [string]: any },
}

local controllers: { [string]: any } = {}
local session: Session? = nil
local hintSession: HintSession? = nil
local hidden: { [string]: Hidden } = {}
local shownStep: number? = nil
local lastTitle: string? = nil
local lastDetail: string? = nil
local lastActive = os.clock()
local lastPing = -math.huge
local lineSince = 0
local noticeUntil = 0
local chopSince: number? = nil

local function device(): string
	local inputType = UserInputService:GetLastInputType()
	if inputType == Enum.UserInputType.Touch then
		return "Touch"
	elseif string.find(inputType.Name, "Gamepad") then
		return "Gamepad"
	end
	return "Keyboard"
end

local function promptKey(adornee: Instance?, action: string, isHold: boolean): string
	local prompt = if adornee then adornee:FindFirstChildWhichIsA("ProximityPrompt", true) else nil
	local kind = device()
	local verb = if isHold then "Hold" else "Press"
	if kind == "Touch" then
		return `{if isHold then "Hold" else "Tap"} {action}`
	elseif kind == "Gamepad" then
		local key = if prompt then prompt.GamepadKeyCode else Enum.KeyCode.ButtonX
		return `{verb} {string.gsub(key.Name, "^Button", "")}`
	end
	local key = if prompt then prompt.KeyboardKeyCode else Enum.KeyCode.E
	return `{verb} {key.Name}`
end

local function releaseKey(): string
	local kind = device()
	if kind == "Touch" then
		return "Tap Chop"
	elseif kind == "Gamepad" then
		return "Press R2"
	end
	return "Press E"
end

local function clickVerb(): string
	return if device() == "Touch" then "Tap" else "Click"
end

local function markActive()
	lastActive = os.clock()
end

local function isMoving(): boolean
	local character = Players.LocalPlayer.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.05
end

local function checkIdle(guide: Guide.Guide, canIdle: boolean): boolean
	if not canIdle or isMoving() then
		markActive()
	end
	local now = os.clock()
	local isIdle = now - lastActive >= TutorialConfig.IdleSeconds
	Guide.SetUrgent(guide, isIdle)
	if not isIdle then
		lastPing = -math.huge
	elseif now - lastPing >= TutorialConfig.IdleSeconds then
		lastPing = now
		LocalSound.Play(TutorialConfig.IdleSoundKey)
	end
	return isIdle
end

local function isOpen(screen: string): boolean
	return controllers.UIController:IsOpen(screen) == true
end

local function isNear(target: Targets.Target?): boolean
	local from = Targets.RootPosition()
	if not target or not from then
		return false
	end
	local offset = target.Position - from
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= target.ArriveStuds
end

local function titleFor(step: number): string?
	local title = Tutorial.Titles[step]
	if not title then
		return nil
	end
	local dataController = controllers.DataController
	local strengthGoal = Tutorial.StrengthGoal(step)
	if strengthGoal then
		local strength = dataController:Get({ "Strength" })
		local current = math.min(if type(strength) == "number" then strength else 0, strengthGoal)
		return `{title} {current}/{strengthGoal}`
	end
	if Tutorial.IsChopping(step) then
		local goal = Tutorial.CashGoal(step) or 0
		local cash = dataController:Get({ "Cash" })
		if type(cash) ~= "number" or cash <= 0 then
			return title
		end
		local current = math.min(cash, goal)
		return `{title} ${NumberFormat.Commas(current)}/${NumberFormat.Commas(goal)}`
	end
	return title
end

local function detailFor(step: number, target: Targets.Target?): string?
	local chopController = controllers.ChopController
	local near = isNear(target)
	local adornee = if target then target.Adornee else nil
	if Tutorial.IsTraining(step) then
		if controllers.TrainingController:IsTraining() then
			return nil
		end
		return if near then `{promptKey(adornee, "Train", false)} to train` else nil
	elseif Tutorial.IsChopping(step) or step == Tutorial.Crack then
		if chopController:IsMinigameActive() then
			return `{releaseKey()} in glow!`
		end
		local action = if step == Tutorial.Crack then "Crack" else "Chop"
		local verb = if step == Tutorial.Crack then "crack" else "chop"
		return if near then `{promptKey(adornee, action, true)} to {verb}!` else nil
	elseif step == Tutorial.BuyGeode then
		return if isOpen("GeodeStand") then "Buy one Forest Geode!" else nil
	end
	return nil
end

local function idleDetail(detail: string?, hasButton: boolean, hasTarget: boolean): string?
	if hasButton then
		return `{clickVerb()} here!`
	end
	return if hasTarget then TutorialConfig.IdleText else detail
end

local function pin(id: string, text: string?, cached: string?, order: number): string?
	local notifications = controllers.NotificationController
	if text == cached then
		return cached
	end
	if text then
		notifications:Pin(id, TutorialConfig.NotificationKind, text, order)
	else
		notifications:Unpin(id)
	end
	return text
end

local function setText(title: string?, detail: string?)
	local isTitleTime = os.clock() - lineSince < TutorialConfig.TitleSeconds
	local line = if isTitleTime then title or detail else detail or title
	if os.clock() < noticeUntil or isOpen(TutorialConfig.CompleteScreen) then
		line = nil
		lineSince = os.clock()
	end
	lastTitle = pin(TutorialConfig.TitleId, line, lastTitle, 0)
	lastDetail = pin(TutorialConfig.DetailId, nil, lastDetail, 1)
end

local function restoreScreens()
	for name, entry in hidden do
		hidden[name] = nil
		pcall(function()
			entry.Gui.Parent = entry.Parent
		end)
	end
end

local function hideScreens()
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	for _, name in TutorialConfig.HiddenScreens do
		local gui = playerGui:FindFirstChild(name)
		if hidden[name] or not gui or not gui:IsA("ScreenGui") then
			continue
		end
		hidden[name] = { Gui = gui, Parent = playerGui }
		gui.Parent = nil
	end
end

local function isBusy(): boolean
	return controllers.HatchController:IsPlaying()
		or isOpen("HatchReveal")
		or isOpen("Letterbox")
		or controllers.IntroController:IsPlaying()
end

local function hideGuide(current: Session)
	Guide.HidePath(current.Guide)
	Guide.HideMarker(current.Guide)
	if current.Spotlight then
		Spotlight.Update(current.Spotlight, nil)
	end
	if current.ChopHint then
		ChopHint.Hide(current.ChopHint)
	end
end

local function update(dt: number)
	local current = session
	if not current then
		return
	end
	if isBusy() then
		hideGuide(current)
		setText(nil, nil)
		return
	end
	local data = controllers.DataController:Get()
	local step = Tutorial.StepOf(if type(data) == "table" then data.Tutorial else nil)
	local chopController = controllers.ChopController
	if
		shownStep
		and step > shownStep
		and Tutorial.IsChopping(shownStep)
		and chopController:IsMinigameActive()
	then
		step = shownStep
	end
	if shownStep ~= step then
		if shownStep == Tutorial.BuyGeode and step > Tutorial.BuyGeode and isOpen("GeodeStand") then
			controllers.UIController:Close("GeodeStand")
		end
		if shownStep and step > shownStep then
			LocalSound.Play(
				if step == Tutorial.Final then TutorialConfig.FinalSoundKey else TutorialConfig.StepSoundKey
			)
		end
		markActive()
		lineSince = os.clock()
		shownStep = step
	end
	local target = Targets.For(step, data)
	local isDoing = chopController:IsMinigameActive()
		or controllers.TrainingController:IsTraining()
		or (step == Tutorial.BuyGeode and isOpen("GeodeStand"))
	local isIdle = checkIdle(current.Guide, step ~= Tutorial.Final and not isDoing)
	local teleport = if isDoing then nil else Teleports.For(step, target, clickVerb(), isIdle)
	local button = if teleport then teleport.Button else Spotlight.TargetFor(step, data, chopController)
	local detail = if teleport then teleport.Text else detailFor(step, target)
	if isIdle then
		detail = idleDetail(detail, button ~= nil, target ~= nil)
	end
	local isChopHint = (Tutorial.IsChopping(step) or step == Tutorial.Crack)
		and chopController:IsMinigameActive()
	local isPanelOpen = isOpen("GeodeStand") or isOpen("Shop") or isOpen("SellShop")
	local isQuiet = isChopHint or isPanelOpen
	setText(if isQuiet then nil else titleFor(step), if isQuiet then nil else detail)

	local from = Targets.RootPosition()
	CameraTurn.Update(
		current.CameraTurn,
		target,
		target ~= nil
			and from ~= nil
			and not isDoing
			and not isNear(target)
			and teleport == nil
			and not Teleports.IsWorthUsing(Teleports.DestinationFor(step), target)
	)
	if target and from and not isDoing then
		if isNear(target) or teleport then
			Guide.HidePath(current.Guide)
		else
			Guide.DrawPath(current.Guide, { from, target.Goal }, dt, target.StopStuds)
		end
		Guide.DrawMarker(current.Guide, target.Position, target.Adornee, target.Label, dt)
	else
		Guide.HidePath(current.Guide)
		Guide.HideMarker(current.Guide)
	end

	if current.Spotlight then
		Spotlight.Update(current.Spotlight, button)
	end

	Layout.Update(current.Layout, not (isOpen("Shop") or isOpen("GeodeStand") or isOpen("SellShop")))

	if current.ChopHint then
		local isChopStep = Tutorial.IsChopping(step) or step == Tutorial.Crack
		local isChopping = isChopStep and chopController:IsMinigameActive()
		if not isChopping then
			chopSince = nil
		elseif not chopSince then
			chopSince = os.clock()
		end
		local isPinGone = chopSince ~= nil and os.clock() - chopSince >= NotificationConfig.FadeOutSeconds
		ChopHint.Update(current.ChopHint, chopController, if isPinGone then releaseKey() else nil, dt)
	end

	current.LockClock += dt
	if current.LockClock >= 0.5 then
		current.LockClock = 0
		Locks.Update(current.Locks, step)
		hideScreens()
	end
end

local function startSession()
	if session then
		return
	end
	local trove = Trove.new()
	local guide = Guide.new()
	local current: Session = {
		Trove = trove,
		CameraTurn = CameraTurn.new(),
		Guide = guide,
		ChopHint = ChopHint.new(),
		Layout = Layout.new(),
		Spotlight = Spotlight.new(),
		Locks = Locks.new(guide.Folder),
		LockClock = math.huge,
	}
	session = current
	hideScreens()
	trove:Connect(RunService.RenderStepped, update)
	trove:Add(function()
		if current.Spotlight then
			Spotlight.Destroy(current.Spotlight)
		end
		if current.ChopHint then
			ChopHint.Destroy(current.ChopHint)
		end
		Layout.Restore(current.Layout)
		Locks.Destroy(current.Locks)
		CameraTurn.Destroy(current.CameraTurn)
		Guide.Destroy(current.Guide)
	end)
end

local function stopSession()
	local current = session
	session = nil
	if current then
		current.Trove:Destroy()
	end
	restoreScreens()
	setText(nil, nil)
end

local hintHelpers: CannonHintView.Helpers = {
	ClickVerb = clickVerb,
	IsOpen = isOpen,
	IsNear = isNear,
	IsTraining = function(): boolean
		return controllers.TrainingController:IsTraining()
	end,
	PromptKey = promptKey,
}

local hintKinds: { HintKind } = {
	{ Shared = RockHint, View = RockHintView.View, ScreenName = "", IdleStages = {}, CloseStages = {} },
	{
		Shared = RebirthHint,
		View = RebirthHintView.View,
		ScreenName = TutorialConfig.RebirthHint.ScreenName,
		IdleStages = { RebirthHint.Ready },
		CloseStages = {},
	},
	{
		Shared = AuraHint,
		View = AuraHintView.View,
		ScreenName = TutorialConfig.AuraHint.ScreenName,
		IdleStages = { AuraHint.Buy },
		CloseStages = { AuraHint.Train },
	},
	{
		Shared = CannonHint,
		View = CannonHintView.View,
		ScreenName = TutorialConfig.CannonHint.ScreenName,
		IdleStages = { CannonHint.Buy },
		CloseStages = {},
	},
}

local function activeHint(data: any): HintKind?
	for _, kind in hintKinds do
		if kind.Shared.IsActive(kind.Shared.StageOf(data)) then
			return kind
		end
	end
	return nil
end

local function hideHint(current: HintSession)
	Guide.HidePath(current.Guide)
	Guide.HideMarker(current.Guide)
	if current.Spotlight then
		Spotlight.Update(current.Spotlight, nil)
	end
	setText(nil, nil)
end

local function updateHint(dt: number)
	local current = hintSession
	if not current then
		return
	end
	local data = controllers.DataController:Get()
	local kind = activeHint(data)
	if isBusy() or controllers.CannonController:IsFlying() or not kind or not kind.Shared.IsShown(data) then
		hideHint(current)
		return
	end
	if current.Kind ~= kind then
		current.Kind = kind
		current.Stage = nil
		lineSince = os.clock()
	end
	local stage = kind.Shared.StageOf(data)
	if current.Stage ~= stage then
		if current.Stage and stage > current.Stage then
			LocalSound.Play(TutorialConfig.StepSoundKey)
			if table.find(kind.CloseStages, stage) and isOpen(kind.ScreenName) then
				controllers.UIController:Close(kind.ScreenName)
			end
		end
		markActive()
		lineSince = os.clock()
		current.Stage = stage
	end
	local view = kind.View(data, hintHelpers)
	local target = view.Target
	local isBusyDoing = controllers.ChopController:IsMinigameActive()
		or controllers.TrainingController:IsTraining()
	local isDoing = view.IsDoing or isBusyDoing
	local isIdle = checkIdle(current.Guide, table.find(kind.IdleStages, stage) ~= nil and not isBusyDoing)
	local teleport = if isDoing
		then nil
		else Teleports.ForDestination(view.Teleport, target, clickVerb(), isIdle)
	local detail = if teleport then teleport.Text else view.Detail
	if isIdle then
		detail = idleDetail(detail, teleport ~= nil or view.Button ~= nil, target ~= nil)
	end
	local isPanelOpen = isOpen(kind.ScreenName) or isOpen("Shop")
	setText(if isPanelOpen then nil else view.Title, if isPanelOpen then nil else detail)

	local from = Targets.RootPosition()
	CameraTurn.Update(
		current.CameraTurn,
		target,
		target ~= nil
			and from ~= nil
			and not isDoing
			and not isNear(target)
			and teleport == nil
			and not Teleports.IsWorthUsing(view.Teleport, target)
	)
	if target and from and not isDoing then
		if isNear(target) or teleport then
			Guide.HidePath(current.Guide)
		else
			Guide.DrawPath(current.Guide, { from, target.Goal }, dt, target.StopStuds)
		end
		Guide.DrawMarker(current.Guide, target.Position, target.Adornee, target.Label, dt)
	else
		Guide.HidePath(current.Guide)
		Guide.HideMarker(current.Guide)
	end

	if current.Spotlight then
		Spotlight.Update(current.Spotlight, if teleport then teleport.Button else view.Button)
	end

	Layout.Update(current.Layout, not (isOpen(kind.ScreenName) or isOpen("Shop")))
end

local function startHint()
	if hintSession then
		return
	end
	local trove = Trove.new()
	local current: HintSession = {
		Trove = trove,
		CameraTurn = CameraTurn.new(),
		Guide = Guide.new(),
		Layout = Layout.new(),
		Spotlight = Spotlight.new(),
		Kind = nil,
		Stage = nil,
	}
	hintSession = current
	trove:Connect(RunService.RenderStepped, updateHint)
	trove:Add(function()
		if current.Spotlight then
			Spotlight.Destroy(current.Spotlight)
		end
		Layout.Restore(current.Layout)
		Guide.Destroy(current.Guide)
		CameraTurn.Destroy(current.CameraTurn)
	end)
end

local function stopHint()
	local current = hintSession
	hintSession = nil
	if current then
		current.Trove:Destroy()
		setText(nil, nil)
	end
end

local function celebrate()
	controllers.RebirthEffectController:PlayBurst()
	controllers.UIController:Open(TutorialConfig.CompleteScreen)
end

local function refresh()
	local data = controllers.DataController:Get()
	local step = Tutorial.StepOf(if type(data) == "table" then data.Tutorial else nil)
	if Tutorial.IsActive(step) then
		stopHint()
		startSession()
		return
	end
	if session then
		stopSession()
		if step == Tutorial.Done then
			celebrate()
		end
	end
	shownStep = nil
	if activeHint(data) then
		startHint()
	else
		stopHint()
	end
end

function TutorialController.IsActive(_self: any): boolean
	return session ~= nil
end

function TutorialController.Init(self: any, registry: { [string]: any })
	self._trove = Trove.new()
	self._controllers = registry
	controllers = registry
end

function TutorialController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(controllers.DataController:Observe({ "Tutorial", "Step" }, refresh))
	trove:Add(controllers.DataController:Observe({ "Hints" }, refresh))
	trove:Connect(UserInputService.InputBegan, markActive)
	trove:Add(controllers.NotificationController.Notified:Connect(function()
		noticeUntil = os.clock()
			+ NotificationConfig.FadeInSeconds
			+ NotificationConfig.HoldSeconds
			+ NotificationConfig.FadeOutSeconds
	end))
	trove:Add(stopSession)
	trove:Add(stopHint)
end

function TutorialController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return TutorialController
