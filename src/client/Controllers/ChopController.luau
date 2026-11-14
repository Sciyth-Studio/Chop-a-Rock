--!strict

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossFxConfig = require(ReplicatedStorage.Config.BossFxConfig)
local BlockRoundConfig = require(ReplicatedStorage.Config.BlockRoundConfig)
local CashPopConfig = require(ReplicatedStorage.Config.CashPopConfig)
local ChopApproach = require(ReplicatedStorage.Utils.ChopApproach)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local HideBillboards = require(ReplicatedStorage.Utils.HideBillboards)
local Packets = require(ReplicatedStorage.Packets)
local GoldenRockConfig = require(ReplicatedStorage.Config.GoldenRockConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local RELEASE_ACTION = "ChopRelease"
local LEAVE_ACTION = "ChopLeave"
local METER_SCREEN = "ChopBar"
local LETTERBOX_SCREEN = "Letterbox"
local TELEPORT_BAR_SCREEN = "TeleportBar"
local RESULT_DISPLAY_SECONDS = 0.7
local MAX_CAMERA_RAY_HITS = 8

local function styleFor(quality: number): ChopStyleConfig.QualityStyle
	return ChopStyleConfig.Qualities[quality] or ChopStyleConfig.Fallback
end

local function qualityShakeIntensity(quality: number): number
	if quality == ChopQuality.Master then
		return MasterChopConfig.ShakeIntensity
	elseif quality == ChopQuality.Perfect then
		return ChopConfig.PerfectShakeIntensity
	elseif quality == ChopQuality.Great then
		return ChopConfig.GreatShakeIntensity
	elseif quality == ChopQuality.Good then
		return ChopConfig.GoodShakeIntensity
	elseif quality == ChopQuality.Mid then
		return ChopConfig.MidShakeIntensity
	end
	return ChopConfig.BadShakeIntensity
end

local uiController: any = nil
local rockController: any = nil
local cashPopController: any = nil
local activeChanged: any = nil
local activeRock: BasePart? = nil
local zoneCenter = 0.5
local strengthRatio = 1
local currentHealth = 0
local currentMaxHealth = 0
local deadlineClock: number? = nil
local sweepSpeed: ((round: number) -> number)? = nil
local sweepRound = 0
local minigameActive = false
local activeTrove: TroveInstance? = nil
local frozenPosition: number? = nil
local minigameStartTime = 0
local activeCanBreak = true
local masterStartClock: number? = nil
local chopCamera: CFrame? = nil
local windUpCamera: CFrame? = nil
local cameraFrom: CFrame? = nil
local cameraTo: CFrame? = nil
local cameraMoveStart = 0
local cameraMoveSeconds = 1
local cameraSettled = true
local cinematicEndClock = 0
local shakeStart = 0
local shakeIntensity = 0
local shakeDuration = 0
local cameraReturnToken = 0
local releaseToken = 0
local mouseRelease: RBXScriptConnection? = nil
local reportedTouch: boolean? = nil
local isBlockRound = false
local blockSpeed = 1
local blockStarted: any = nil
local blockResolved: any = nil
local modifierKind = BossConfig.Signatures.None
local modifierValues: { number } = { 0, 0, 0, 0 }
local releaseElapsed: number? = nil

local function clearModifier()
	modifierKind = BossConfig.Signatures.None
	modifierValues = { 0, 0, 0, 0 }
	releaseElapsed = nil
end

local function smooth(alpha: number): number
	local clamped = math.clamp(alpha, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
end

local function moveCamera(target: CFrame?, seconds: number)
	local camera = workspace.CurrentCamera
	if not (camera and target) then
		return
	end
	cameraFrom = camera.CFrame
	cameraTo = target
	cameraMoveStart = os.clock()
	cameraMoveSeconds = seconds
	cameraSettled = false
end

local function startShake(intensity: number, duration: number)
	shakeStart = os.clock()
	shakeIntensity = intensity
	shakeDuration = duration
	cameraSettled = false
end

local function stepCamera()
	local camera = workspace.CurrentCamera
	local from = cameraFrom
	local to = cameraTo
	if cameraSettled or not (camera and from and to) or camera.CameraType ~= Enum.CameraType.Scriptable then
		return
	end
	local now = os.clock()
	if now < cinematicEndClock then
		return
	end
	local alpha = (now - cameraMoveStart) / cameraMoveSeconds
	local frame = if alpha >= 1 then to else from:Lerp(to, smooth(alpha))
	local shakeElapsed = now - shakeStart
	if shakeElapsed < shakeDuration then
		local strength = shakeIntensity * (1 - shakeElapsed / shakeDuration)
		frame = frame
			* CFrame.new(
				(math.random() * 2 - 1) * strength,
				(math.random() * 2 - 1) * strength,
				(math.random() * 2 - 1) * strength
			)
	elseif alpha >= 1 then
		cameraSettled = true
	end
	camera.CFrame = frame
end

local function clearCameraDistance(origin: Vector3, target: Vector3, ignored: { Instance }): number
	local direction = target - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignored
	params.IgnoreWater = true
	for _ = 1, MAX_CAMERA_RAY_HITS do
		local hit = workspace:Raycast(origin, direction, params)
		if not hit then
			break
		end
		local part = hit.Instance
		local model = part:FindFirstAncestorOfClass("Model")
		if part.Transparency >= 1 or (model and model:FindFirstChildOfClass("Humanoid")) then
			params:AddToFilter(part)
		else
			return math.max(hit.Distance - ChopConfig.WindUpCameraWallMarginStuds, 0)
		end
	end
	return direction.Magnitude
end

local function windUpShot(rock: BasePart, rootTarget: CFrame, character: Model, fallback: CFrame): CFrame
	local rootPosition = rootTarget.Position
	local flatRoot =
		CFrame.lookAt(rootPosition, Vector3.new(rock.Position.X, rootPosition.Y, rock.Position.Z))
	local offset = ChopConfig.WindUpCameraOffset
	local origin = rootPosition + Vector3.new(0, offset.Y, 0)
	local desired = (flatRoot * CFrame.new(offset)).Position
	local clear = clearCameraDistance(origin, desired, { character, rock })
	if clear < ChopConfig.WindUpCameraMinDistanceStuds then
		return fallback
	end
	local position = origin + (desired - origin).Unit * clear
	local lookHeight = math.min(rock.Position.Y, rootPosition.Y + ChopConfig.WindUpCameraMaxLookHeightStuds)
	return CFrame.lookAt(position, Vector3.new(rock.Position.X, lookHeight, rock.Position.Z))
end

local function masterShots(): (CFrame?, CFrame?, CFrame?)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local head = if character then character:FindFirstChild("Head") else nil
	if not (root and root:IsA("BasePart") and head and head:IsA("BasePart")) then
		return nil, nil, nil
	end
	local sidePosition = (root.CFrame * CFrame.new(MasterChopConfig.CinematicSideOffset)).Position
	local halfPan = MasterChopConfig.CinematicFacePanStuds / 2
	local function faceShot(offsetX: number): CFrame
		local position = (head.CFrame * CFrame.new(
			offsetX,
			MasterChopConfig.CinematicFaceHeightStuds,
			-MasterChopConfig.CinematicFaceDistanceStuds
		)).Position
		return CFrame.lookAt(position, head.Position)
	end
	return CFrame.lookAt(sidePosition, root.Position), faceShot(-halfPan), faceShot(halfPan)
end

local function playMasterCinematic(trove: TroveInstance, camera: Camera)
	local startFrame = camera.CFrame
	local base = chopCamera or startFrame
	local side, faceStart, faceEnd = masterShots()
	if not (side and faceStart and faceEnd) then
		return
	end
	local sideEnd = MasterChopConfig.CinematicSideSeconds
	local faceSeconds = MasterChopConfig.CinematicFaceSeconds
	local faceEndTime = sideEnd + faceSeconds
	local total = MasterChopConfig.ImpactDelaySeconds
	local blend = MasterChopConfig.CinematicFaceBlendFraction
	local startClock = os.clock()
	cinematicEndClock = startClock + total
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startClock
		if elapsed >= total then
			camera.CFrame = base
			connection:Disconnect()
			return
		end
		if elapsed < sideEnd then
			camera.CFrame = startFrame:Lerp(side, smooth(elapsed / sideEnd))
		elseif elapsed < faceEndTime then
			local progress = (elapsed - sideEnd) / faceSeconds
			if progress < blend then
				camera.CFrame = side:Lerp(faceStart, smooth(progress / blend))
			else
				camera.CFrame = faceStart:Lerp(faceEnd, (progress - blend) / (1 - blend))
			end
		else
			camera.CFrame = faceEnd:Lerp(base, smooth((elapsed - faceEndTime) / (total - faceEndTime)))
		end
	end)
	trove:Add(connection)
end

local function startMasterWindUp(trove: TroveInstance)
	uiController:Open(LETTERBOX_SCREEN)
	trove:Add(function()
		uiController:Close(LETTERBOX_SCREEN)
	end)
	local info =
		TweenInfo.new(MasterChopConfig.ImpactDelaySeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "MasterWindUp"
	effect.Parent = Lighting
	trove:Add(effect)
	TweenService:Create(effect, info, {
		Brightness = MasterChopConfig.WindUpDarkenBrightness,
		Saturation = MasterChopConfig.WindUpSaturation,
	}):Play()
	local camera = workspace.CurrentCamera
	local baseFieldOfView = if camera then camera.FieldOfView else 70
	if camera then
		playMasterCinematic(trove, camera)
		trove:Add(function()
			camera.FieldOfView = baseFieldOfView
		end)
	end
	task.delay(MasterChopConfig.ImpactDelaySeconds, function()
		if effect.Parent then
			effect:Destroy()
		end
		if camera then
			camera.FieldOfView = MasterChopConfig.PunchFieldOfView
			TweenService:Create(
				camera,
				TweenInfo.new(
					MasterChopConfig.PunchOutSeconds,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{ FieldOfView = baseFieldOfView }
			):Play()
		end
	end)
end

local function flashMaster()
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "MasterFlash"
	effect.Brightness = MasterChopConfig.FlashBrightness
	effect.Contrast = MasterChopConfig.FlashContrast
	effect.Parent = Lighting
	local info = TweenInfo.new(MasterChopConfig.FlashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(effect, info, { Brightness = 0, Contrast = 0 })
	tween.Completed:Once(function()
		effect:Destroy()
	end)
	tween:Play()
end

local function flashScreen()
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "PerfectFlash"
	effect.Brightness = ChopConfig.PerfectFlashBrightness
	effect.Parent = Lighting
	local info =
		TweenInfo.new(ChopConfig.PerfectFlashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(effect, info, { Brightness = 0 })
	tween.Completed:Once(function()
		effect:Destroy()
	end)
	tween:Play()
end

local function unbindRelease()
	ContextActionService:UnbindAction(RELEASE_ACTION)
	if mouseRelease then
		mouseRelease:Disconnect()
		mouseRelease = nil
	end
end

local function endMinigame()
	if not minigameActive then
		return
	end
	minigameActive = false
	deadlineClock = nil
	isBlockRound = false
	sweepSpeed = nil
	sweepRound = 0
	clearModifier()
	releaseToken += 1
	activeChanged:Fire(false)
	unbindRelease()
	ContextActionService:UnbindAction(LEAVE_ACTION)
	if activeTrove then
		activeTrove:Destroy()
		activeTrove = nil
	end
	frozenPosition = nil
	masterStartClock = nil
	chopCamera = nil
	windUpCamera = nil
	cameraFrom = nil
	cameraTo = nil
	cameraSettled = true
	cinematicEndClock = 0
	shakeDuration = 0
	cameraReturnToken += 1
	activeRock = nil
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function currentSpeed(): number
	local speedFor = sweepSpeed
	return if speedFor then speedFor(sweepRound) else 1
end

local function release()
	local elapsed = os.clock() - minigameStartTime
	releaseElapsed = elapsed
	frozenPosition = ChopZones.Position(elapsed, ChopZones.IsTouch(Players.LocalPlayer), currentSpeed())
	Packets.ChopRelease:Fire(elapsed)
	unbindRelease()
	cameraReturnToken += 1
	moveCamera(chopCamera, ChopConfig.ImpactCameraSeconds)
end

local function bossBlockShot(): CFrame?
	local rock = activeRock
	if not rock or rock:GetAttribute(BossConfig.SpotIndexAttribute) == nil then
		return nil
	end
	local model = rock:FindFirstAncestorOfClass("Model")
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not model or not character or not root or not root:IsA("BasePart") then
		return nil
	end
	local spec = BossFxConfig.BlockCamera
	local boxCFrame, boxSize = model:GetBoundingBox()
	local height = boxSize.Y
	local bossBase = Vector3.new(boxCFrame.X, boxCFrame.Y - height / 2, boxCFrame.Z)
	local rootPosition = root.Position
	local flat = Vector3.new(rootPosition.X - bossBase.X, 0, rootPosition.Z - bossBase.Z)
	if flat.Magnitude < 1e-3 then
		return nil
	end
	local away = flat.Unit
	local side = away:Cross(Vector3.yAxis)
	local desired = rootPosition
		+ away * (spec.BackStuds + height * spec.BackPerHeight)
		+ Vector3.yAxis * (spec.UpStuds + height * spec.UpPerHeight)
		+ side * spec.SideStuds
	local origin = rootPosition + Vector3.yAxis * 2
	local clear = clearCameraDistance(origin, desired, { character, model })
	local position = origin + (desired - origin).Unit * math.max(clear, spec.MinClearStuds)
	local bossLook = Vector3.new(bossBase.X, bossBase.Y + height * spec.LookHeightRatio, bossBase.Z)
	return CFrame.lookAt(position, rootPosition:Lerp(bossLook, spec.LookBlend))
end

local function blockPosition(): number
	return ChopZones.BlockPosition(
		os.clock() - minigameStartTime,
		ChopZones.IsTouch(Players.LocalPlayer),
		blockSpeed
	)
end

local function pressBlock()
	local elapsed = os.clock() - minigameStartTime
	frozenPosition = blockPosition()
	Packets.BlockPress:Fire(elapsed)
	unbindRelease()
end

local function press()
	if isBlockRound then
		pressBlock()
	else
		release()
	end
end

local function bindRelease()
	releaseToken += 1
	local token = releaseToken
	task.delay(ChopConfig.RoundInputDelaySeconds, function()
		if token ~= releaseToken or not minigameActive or frozenPosition ~= nil then
			return
		end
		unbindRelease()
		ContextActionService:BindAction(RELEASE_ACTION, function(_actionName, inputState)
			if inputState == Enum.UserInputState.Begin then
				press()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, true, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.ButtonR2)
		ContextActionService:SetTitle(RELEASE_ACTION, if isBlockRound then "Block" else "Chop")
		mouseRelease = UserInputService.InputBegan:Connect(function(input: InputObject, isProcessed: boolean)
			if not isProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
				press()
			end
		end)
	end)
end

local function reportInput(inputType: Enum.UserInputType)
	local isTouch: boolean
	if inputType == Enum.UserInputType.Touch then
		isTouch = true
	elseif
		inputType == Enum.UserInputType.Keyboard
		or string.find(inputType.Name, "Mouse")
		or string.find(inputType.Name, "Gamepad")
	then
		isTouch = false
	else
		return
	end
	if isTouch ~= reportedTouch then
		reportedTouch = isTouch
		Packets.ChopTouch:Fire(isTouch)
	end
end

local function leaveMinigame()
	if not minigameActive then
		return
	end
	Packets.ChopLeave:Fire()
	endMinigame()
end

local function beginMinigame(
	rock: BasePart,
	canBreak: boolean,
	ratio: number,
	center: number,
	health: number,
	maxHealth: number,
	approach: CFrame?
)
	if minigameActive then
		return
	end
	minigameActive = true
	clearModifier()
	activeChanged:Fire(true)
	frozenPosition = nil
	activeRock = rock
	activeCanBreak = canBreak
	zoneCenter = center
	strengthRatio = ratio
	currentHealth = health
	currentMaxHealth = maxHealth

	local trove = Trove.new()
	activeTrove = trove

	local character = Players.LocalPlayer.Character

	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local scaleOverride = rock:GetAttribute(ChopConfig.ScaleAttribute)
	local rockScale = if type(scaleOverride) == "number"
		then scaleOverride
		else math.max(1, rock.Size.Z / ChopConfig.ReferenceRockSize)
	local isRelative = rock:GetAttribute(ChopConfig.RelativeOffsetAttribute) == true
	local slotCount = rock:GetAttribute(DiamondRockConfig.SlotsAttribute)
	local slot = Players.LocalPlayer:GetAttribute(DiamondRockConfig.PlayerSlotAttribute)
	local slotRotation = if type(slotCount) == "number" and type(slot) == "number"
		then CFrame.Angles(0, (slot - 1) / slotCount * math.pi * 2 + math.pi, 0)
		else nil
	local fanSlots = rock:GetAttribute(BossConfig.FanSlotsAttribute)
	local fanNormal = rock:GetAttribute(BossConfig.NormalAttribute)
	local fanRotation: CFrame? = nil
	if typeof(fanNormal) == "Vector3" and type(fanSlots) == "number" and fanNormal.Magnitude > 1e-3 then
		local degrees = rock:GetAttribute(BossConfig.FanDegreesAttribute)
		local spread = if type(degrees) == "number" then degrees else 0
		local step = if fanSlots > 1 then spread / (fanSlots - 1) else 0
		local index = if type(slot) == "number" then slot else 1
		fanRotation = CFrame.Angles(0, math.rad(-spread / 2 + (index - 1) * step), 0)
			* CFrame.lookAt(Vector3.zero, fanNormal.Unit)
	end
	local function offset(vector: Vector3): Vector3
		if slotRotation then
			return slotRotation:VectorToWorldSpace(vector)
		end
		if fanRotation then
			return fanRotation:VectorToWorldSpace(vector)
		end
		if approach then
			return approach:VectorToWorldSpace(vector)
		end
		return if isRelative then rock.CFrame:VectorToWorldSpace(vector) else vector
	end
	local rootStart: CFrame? = if rootPart then rootPart.CFrame else nil
	local rootTarget: CFrame? = nil
	if rootPart then
		local groundOffset = rock:GetAttribute(ChopConfig.GroundOffsetAttribute)
		local fixedGround = rock:GetAttribute(BossConfig.GroundYAttribute)
		local groundY = if type(fixedGround) == "number"
			then fixedGround + rootPart.Size.Y * 1.5
			else rock.Position.Y - rock.Size.Y / 2 + (if type(groundOffset) == "number"
				then groundOffset
				else 0) + rootPart.Size.Y * 1.5
		local snapPos = rock.Position + offset(ChopConfig.PlayerSnapOffsetFromRock) * rockScale
		snapPos = Vector3.new(snapPos.X, groundY, snapPos.Z)
		rootTarget = CFrame.lookAt(snapPos, rock.Position)
			* CFrame.new(-ChopConfig.PlayerSnapLeftShiftStuds, 0, 0)
	end

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		local cameraPos = rock.Position + offset(ChopConfig.CameraOffsetFromRock) * rockScale
		local impactShot = CFrame.new(cameraPos, rock.Position + offset(ChopConfig.CameraLookOffset))
		chopCamera = impactShot
		windUpCamera = if character and rootTarget
			then windUpShot(rock, rootTarget, character, impactShot)
			else impactShot
		if slotRotation or fanRotation then
			chopCamera = windUpCamera
		end
		moveCamera(windUpCamera, ChopConfig.CameraTransitionSeconds)
		trove:Connect(RunService.RenderStepped, stepCamera)
	end

	local transitionStart = os.clock()
	local transition: RBXScriptConnection
	transition = RunService.RenderStepped:Connect(function()
		local progress = math.clamp((os.clock() - transitionStart) / ChopConfig.CameraTransitionSeconds, 0, 1)
		local eased = progress * progress * (3 - 2 * progress)
		if rootPart and rootStart and rootTarget then
			rootPart.CFrame = rootStart:Lerp(rootTarget, eased)
			rootPart.AssemblyLinearVelocity = Vector3.zero
		end
		if progress >= 1 then
			transition:Disconnect()
		end
	end)
	trove:Add(transition)

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		trove:Add(MovementLock.Acquire(humanoid))
	end

	minigameStartTime = os.clock()
	uiController:Open(METER_SCREEN)
	uiController:Close(TELEPORT_BAR_SCREEN)
	uiController:Close(ToolbarConfig.Screen)
	if ChopConfig.HidesBillboards then
		trove:Add(HideBillboards.Hide())
	end
	trove:Add(function()
		uiController:Close(METER_SCREEN)
		uiController:Open(TELEPORT_BAR_SCREEN)
		uiController:Open(ToolbarConfig.Screen)
	end)

	bindRelease()
	ContextActionService:BindAction(LEAVE_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			leaveMinigame()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
end

local ChopController = {
	Name = "ChopController",
	_trove = nil :: TroveInstance?,
	ResultShown = nil :: any,
	HealthChanged = nil :: any,
	RoundStarted = nil :: any,
	ActiveChanged = nil :: any,
	BlockStarted = nil :: any,
	BlockResolved = nil :: any,
}

function ChopController.BeginExternal(
	_self: any,
	target: BasePart,
	ratio: number,
	center: number,
	health: number,
	maxHealth: number,
	secondsLeft: number,
	speedFor: ((round: number) -> number)?
)
	if minigameActive then
		return
	end
	beginMinigame(target, true, ratio, center, health, maxHealth, ChopApproach.Rotation(target))
	deadlineClock = if secondsLeft > 0 then os.clock() + secondsLeft else nil
	sweepSpeed = speedFor
	sweepRound = 0
end

function ChopController.GetSecondsLeft(_self: any): number?
	local deadline = deadlineClock
	if not minigameActive or not deadline then
		return nil
	end
	return math.max(deadline - os.clock(), 0)
end

function ChopController.GetZoneCenter(_self: any): number
	if modifierKind == BossConfig.Signatures.Chomp and minigameActive and not isBlockRound then
		local elapsed = releaseElapsed or (os.clock() - minigameStartTime)
		return ChopZones.ChompCenter(elapsed, ChopZones.IsTouch(Players.LocalPlayer), modifierValues)
	end
	return zoneCenter
end

function ChopController.GetModifier(_self: any): (number, { number })
	if not minigameActive or isBlockRound then
		return BossConfig.Signatures.None, modifierValues
	end
	return modifierKind, modifierValues
end

function ChopController.GetStrengthRatio(_self: any): number
	return strengthRatio
end

function ChopController.GetHealth(_self: any): number
	return currentHealth
end

function ChopController.GetMaxHealth(_self: any): number
	return currentMaxHealth
end

function ChopController.Leave(_self: any)
	leaveMinigame()
end

function ChopController.IsMinigameActive(_self: any): boolean
	return minigameActive
end

function ChopController.GetMasterSeconds(_self: any): number?
	local started = masterStartClock
	if not started then
		return nil
	end
	return os.clock() - started
end

function ChopController.IsBlockRound(_self: any): boolean
	return minigameActive and isBlockRound
end

function ChopController.IsReleased(_self: any): boolean
	return frozenPosition ~= nil
end

function ChopController.GetTarget(_self: any): BasePart?
	return if minigameActive then activeRock else nil
end

function ChopController.CanBreakRock(_self: any): boolean
	return activeCanBreak
end

function ChopController.GetCursorPosition(_self: any): number
	if not minigameActive then
		return 0
	end
	if isBlockRound and frozenPosition == nil then
		return blockPosition()
	end
	return frozenPosition
		or ChopZones.Position(
			os.clock() - minigameStartTime,
			ChopZones.IsTouch(Players.LocalPlayer),
			currentSpeed()
		)
end

function ChopController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	self.ResultShown = Signal.new()
	self.HealthChanged = Signal.new()
	self.RoundStarted = Signal.new()
	self.ActiveChanged = Signal.new()
	self.BlockStarted = Signal.new()
	self.BlockResolved = Signal.new()
	activeChanged = self.ActiveChanged
	blockStarted = self.BlockStarted
	blockResolved = self.BlockResolved
	uiController = controllers.UIController
	rockController = controllers.RockController
	cashPopController = controllers.CashPopController
end

function ChopController.Start(self: any)
	local trove = self._trove :: TroveInstance
	reportInput(UserInputService:GetLastInputType())
	trove:Connect(UserInputService.LastInputTypeChanged, reportInput)
	trove:Add(
		Packets.ChopMinigameStart.OnClientEvent:Connect(
			function(
				rock: Instance?,
				canBreak: boolean,
				ratio: number,
				center: number,
				health: number,
				maxHealth: number
			)
				if rock and rock:IsA("BasePart") then
					beginMinigame(rock, canBreak, ratio, center, health, maxHealth)
				elseif not minigameActive then
					Packets.ChopLeave:Fire()
				end
			end
		)
	)
	trove:Add(
		Packets.RockMinigameStart.OnClientEvent:Connect(
			function(
				id: number,
				canBreak: boolean,
				ratio: number,
				center: number,
				health: number,
				maxHealth: number
			)
				local rock = rockController:GetPart(id)
				if rock then
					beginMinigame(
						rock,
						canBreak,
						ratio,
						center,
						health,
						maxHealth,
						ChopApproach.Rotation(rock)
					)
				elseif not minigameActive then
					Packets.ChopLeave:Fire()
				end
			end
		)
	)
	trove:Add(Packets.ChopEnded.OnClientEvent:Connect(endMinigame))
	trove:Add(
		Packets.BlockRoundStart.OnClientEvent:Connect(
			function(center: number, speed: number, zoneScale: number)
				if not minigameActive then
					return
				end
				isBlockRound = true
				clearModifier()
				blockSpeed = speed
				zoneCenter = center
				frozenPosition = nil
				minigameStartTime = os.clock()
				LocalSound.Play(BlockRoundConfig.WarningSound)
				bindRelease()
				cameraReturnToken += 1
				local wideShot = bossBlockShot()
				if wideShot then
					moveCamera(wideShot, BossFxConfig.BlockCamera.MoveSeconds)
				elseif cameraTo ~= windUpCamera then
					moveCamera(windUpCamera, ChopConfig.WindUpCameraReturnSeconds)
				end
				blockStarted:Fire(center, zoneScale)
			end
		)
	)
	trove:Add(Packets.BlockResult.OnClientEvent:Connect(function(outcome: number)
		if not minigameActive then
			return
		end
		if frozenPosition == nil then
			frozenPosition = blockPosition()
		end
		isBlockRound = false
		unbindRelease()
		LocalSound.Play(BlockRoundConfig.OutcomeSounds[outcome] or BlockRoundConfig.WarningSound)
		if outcome == BlockRoundConfig.Outcomes.Missed then
			startShake(BlockRoundConfig.MissedShakeIntensity, BlockRoundConfig.MissedShakeSeconds)
		elseif outcome == BlockRoundConfig.Outcomes.Perfect then
			flashScreen()
		end
		blockResolved:Fire(outcome)
	end))
	trove:Add(
		Packets.ChopModifier.OnClientEvent:Connect(
			function(kind: number, first: number, second: number, third: number, fourth: number)
				if not minigameActive then
					return
				end
				modifierKind = kind
				modifierValues = { first, second, third, fourth }
			end
		)
	)
	trove:Add(Packets.ChopRoundStart.OnClientEvent:Connect(function(center: number)
		if not minigameActive then
			return
		end
		zoneCenter = center
		frozenPosition = nil
		releaseElapsed = nil
		if sweepSpeed then
			sweepRound += 1
		end
		if masterStartClock then
			masterStartClock = nil
			uiController:Close(LETTERBOX_SCREEN)
		end
		minigameStartTime = os.clock()
		bindRelease()
		cameraReturnToken += 1
		if cameraTo ~= windUpCamera then
			moveCamera(windUpCamera, ChopConfig.WindUpCameraReturnSeconds)
		end
		self.RoundStarted:Fire()
	end))
	trove:Add(
		Packets.ChopResult.OnClientEvent:Connect(
			function(quality: number, payout: number, _damage: number, health: number, multiplier: number)
				print(`[ChopController] {styleFor(quality).Name} chop, payout={payout}`)
				local isGolden = activeRock ~= nil
					and activeRock:GetAttribute(GoldenRockConfig.GoldenAttribute) ~= nil
				local isMaster = quality == ChopQuality.Master
				cameraReturnToken += 1
				if cameraTo ~= chopCamera then
					moveCamera(chopCamera, ChopConfig.ImpactCameraSeconds)
				end
				if isMaster and activeTrove then
					masterStartClock = os.clock()
					startMasterWindUp(activeTrove)
					task.wait(MasterChopConfig.ImpactDelaySeconds)
				else
					task.wait(ChopConfig.SlowMoPreImpactSeconds)
				end
				if not minigameActive then
					return
				end
				self.ResultShown:Fire(quality)
				currentHealth = math.max(health, 0)
				self.HealthChanged:Fire(currentHealth, currentMaxHealth)
				if isMaster then
					flashMaster()
				elseif quality == ChopQuality.Perfect then
					flashScreen()
				end
				startShake(
					qualityShakeIntensity(quality),
					if isMaster
						then MasterChopConfig.ShakeDurationSeconds
						elseif quality == ChopQuality.Perfect then ChopConfig.PerfectShakeDurationSeconds
						else ChopConfig.ShakeDurationSeconds
				)
				if payout > 0 then
					local rock = activeRock
					local popAt = if rock then rock.Position + Vector3.new(0, rock.Size.Y / 2, 0) else nil
					task.delay(ChopConfig.MoneyEffectDelaySeconds, function()
						LocalSound.Play("SFX_Money_Gain")
						if popAt then
							cashPopController:Play(popAt, CashPopConfig.Chop)
							if isGolden then
								local total = math.floor(
									multiplier * GoldenRockConfig.PayoutMultiplier * 100 + 0.5
								) / 100
								cashPopController:PlayText(popAt, payout, total, {
									Main = GoldenRockConfig.PopMain,
									Light = GoldenRockConfig.PopLight,
									Dark = GoldenRockConfig.PopDark,
								})
							elseif multiplier > 1 then
								cashPopController:PlayText(popAt, payout, multiplier)
							end
						end
					end)
				end
				if quality == ChopQuality.Crack or health <= 1e-6 then
					local holdSeconds = if isMaster
						then RESULT_DISPLAY_SECONDS + MasterChopConfig.StrikeHoldSeconds
						else RESULT_DISPLAY_SECONDS
					task.delay(holdSeconds, function()
						endMinigame()
					end)
				else
					local token = cameraReturnToken
					task.delay(
						if isMaster
							then MasterChopConfig.StrikeHoldSeconds + ChopConfig.ImpactCameraHoldSeconds
							else ChopConfig.ImpactCameraHoldSeconds,
						function()
							if token == cameraReturnToken then
								moveCamera(windUpCamera, ChopConfig.WindUpCameraReturnSeconds)
							end
						end
					)
				end
			end
		)
	)
end

function ChopController.Destroy(self: any)
	endMinigame()
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
	if self.ResultShown then
		self.ResultShown:Destroy()
		self.ResultShown = nil
	end
	if self.HealthChanged then
		self.HealthChanged:Destroy()
		self.HealthChanged = nil
	end
	if self.RoundStarted then
		self.RoundStarted:Destroy()
		self.RoundStarted = nil
	end
	if self.ActiveChanged then
		self.ActiveChanged:Destroy()
		self.ActiveChanged = nil
	end
	if self.BlockStarted then
		self.BlockStarted:Destroy()
		self.BlockStarted = nil
	end
	if self.BlockResolved then
		self.BlockResolved:Destroy()
		self.BlockResolved = nil
	end
end

return ChopController
