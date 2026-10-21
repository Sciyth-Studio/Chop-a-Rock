--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CannonHint = require(ReplicatedStorage.CannonHint)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local CannonHintView = require(script.CannonHint)
local ChopHint = require(script.ChopHint)
local Guide = require(script.Guide)
local Layout = require(script.Layout)
local Locks = require(script.Locks)
local Spotlight = require(script.Spotlight)
local Targets = require(script.Targets)
local Teleports = require(script.Teleports)

type TroveInstance = typeof(Trove.new())
type Hidden = { Gui: ScreenGui, Parent: Instance }
type Session = {
	Trove: TroveInstance,
	Guide: Guide.Guide,
	ChopHint: ChopHint.State?,
	Layout: Layout.State,
	Spotlight: Spotlight.State?,
	Locks: Locks.State,
	LockClock: number,
}
type HintSession = {
	Trove: TroveInstance,
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
		local current = math.min(if type(cash) == "number" then cash else 0, goal)
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
			return "Keep going!"
		end
		return if near then `{promptKey(adornee, "Train", false)} to train` else "Follow the arrows"
	elseif Tutorial.IsChopping(step) or step == Tutorial.Crack then
		if chopController:IsMinigameActive() then
			return `{releaseKey()} when the line is in the glowing zone!`
		end
		local action = if step == Tutorial.Crack then "Crack" else "Chop"
		local what = if step == Tutorial.Crack then "the geode" else "a Stone"
		return if near then `{promptKey(adornee, action, true)} to chop {what}` else "Follow the arrows"
	elseif step == Tutorial.BuyAura then
		return if isOpen("Shop") then "Buy Silver Aura!" else "Walk onto the red pad"
	elseif step == Tutorial.BuyGeode then
		return if isOpen("GeodeStand") then "Buy one Forest Geode!" else "Walk onto the pad"
	elseif step == Tutorial.Collect then
		return "Step on the green pad"
	end
	return nil
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
	lastTitle = pin(TutorialConfig.TitleId, title, lastTitle, 0)
	lastDetail = pin(TutorialConfig.DetailId, detail, lastDetail, 1)
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
	return controllers.HatchController:IsPlaying() or isOpen("HatchReveal") or isOpen("Letterbox")
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
	if shownStep ~= step then
		if shownStep and step > shownStep then
			LocalSound.Play(
				if step == Tutorial.Final then TutorialConfig.FinalSoundKey else TutorialConfig.StepSoundKey
			)
		end
		shownStep = step
	end
	local target = Targets.For(step, data)
	local chopController = controllers.ChopController
	local isDoing = chopController:IsMinigameActive()
		or controllers.TrainingController:IsTraining()
		or (step == Tutorial.BuyAura and isOpen("Shop"))
		or (step == Tutorial.BuyGeode and isOpen("GeodeStand"))
	local teleport = if isDoing then nil else Teleports.For(step, target, clickVerb())
	setText(titleFor(step), if teleport then teleport.Text else detailFor(step, target))

	local from = Targets.RootPosition()
	if target and from and not isDoing then
		if isNear(target) or teleport then
			Guide.HidePath(current.Guide)
		else
			Guide.DrawPath(current.Guide, { from, target.Goal }, dt)
		end
		Guide.DrawMarker(current.Guide, target.Position, target.Adornee, target.Label, dt)
	else
		Guide.HidePath(current.Guide)
		Guide.HideMarker(current.Guide)
	end

	if current.Spotlight then
		Spotlight.Update(
			current.Spotlight,
			if teleport then teleport.Button else Spotlight.TargetFor(step, data, chopController)
		)
	end

	Layout.Update(current.Layout, not (isOpen("Shop") or isOpen("GeodeStand") or isOpen("SellShop")))

	if current.ChopHint then
		local isChopStep = Tutorial.IsChopping(step) or step == Tutorial.Crack
		ChopHint.Update(
			current.ChopHint,
			chopController,
			if isChopStep and chopController:IsMinigameActive() then releaseKey() else nil,
			dt
		)
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
	PromptKey = promptKey,
	ClickVerb = clickVerb,
	IsOpen = isOpen,
	IsNear = isNear,
}

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
	if isBusy() or controllers.CannonController:IsFlying() or not CannonHint.IsShown(data) then
		hideHint(current)
		return
	end
	local stage = CannonHint.StageOf(data)
	if current.Stage ~= stage then
		if current.Stage and stage > current.Stage then
			LocalSound.Play(TutorialConfig.StepSoundKey)
		end
		current.Stage = stage
	end
	local view = CannonHintView.View(data, hintHelpers)
	local target = view.Target
	local isDoing = view.IsDoing
		or controllers.ChopController:IsMinigameActive()
		or controllers.TrainingController:IsTraining()
	local teleport = if isDoing
		then nil
		else Teleports.ForDestination(TutorialConfig.CannonHint.TeleportId, target, clickVerb())
	setText(view.Title, if teleport then teleport.Text else view.Detail)

	local from = Targets.RootPosition()
	if target and from and not isDoing then
		if isNear(target) or teleport then
			Guide.HidePath(current.Guide)
		else
			Guide.DrawPath(current.Guide, { from, target.Goal }, dt)
		end
		Guide.DrawMarker(current.Guide, target.Position, target.Adornee, target.Label, dt)
	else
		Guide.HidePath(current.Guide)
		Guide.HideMarker(current.Guide)
	end

	if current.Spotlight then
		Spotlight.Update(current.Spotlight, if teleport then teleport.Button else view.Button)
	end

	Layout.Update(current.Layout, not (isOpen(TutorialConfig.CannonHint.ScreenName) or isOpen("Shop")))
end

local function startHint()
	if hintSession then
		return
	end
	local trove = Trove.new()
	local current: HintSession = {
		Trove = trove,
		Guide = Guide.new(),
		Layout = Layout.new(),
		Spotlight = Spotlight.new(),
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
	end
	shownStep = nil
	if CannonHint.IsActive(CannonHint.StageOf(data)) then
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
