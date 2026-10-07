--!strict

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local CashPopConfig = require(ReplicatedStorage.Config.CashPopConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local RELEASE_ACTION = "ChopRelease"
local LEAVE_ACTION = "ChopLeave"
local METER_SCREEN = "ChopMeter"
local LETTERBOX_SCREEN = "Letterbox"
local EXP_BAR_SCREEN = "ExpBar"
local RESULT_DISPLAY_SECONDS = 0.7

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
local minigameActive = false
local activeTrove: TroveInstance? = nil
local frozenPosition: number? = nil
local minigameStartTime = 0
local activeCanBreak = true
local masterStartClock: number? = nil
local chopCamera: CFrame? = nil
local releaseToken = 0

local function smooth(alpha: number): number
	local clamped = math.clamp(alpha, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
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
	local base = chopCamera or camera.CFrame
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
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startClock
		if elapsed >= total then
			camera.CFrame = base
			connection:Disconnect()
			return
		end
		if elapsed < sideEnd then
			camera.CFrame = base:Lerp(side, smooth(elapsed / sideEnd))
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

local function shakeCamera(camera: Camera, baseCFrame: CFrame, intensity: number, duration: number)
	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			camera.CFrame = baseCFrame
			connection:Disconnect()
			return
		end
		local decay = 1 - elapsed / duration
		local offsetX = (math.random() * 2 - 1) * intensity * decay
		local offsetY = (math.random() * 2 - 1) * intensity * decay
		local offsetZ = (math.random() * 2 - 1) * intensity * decay
		camera.CFrame = baseCFrame * CFrame.new(offsetX, offsetY, offsetZ)
	end)
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

local function endMinigame()
	if not minigameActive then
		return
	end
	minigameActive = false
	releaseToken += 1
	activeChanged:Fire(false)
	ContextActionService:UnbindAction(RELEASE_ACTION)
	ContextActionService:UnbindAction(LEAVE_ACTION)
	if activeTrove then
		activeTrove:Destroy()
		activeTrove = nil
	end
	frozenPosition = nil
	masterStartClock = nil
	chopCamera = nil
	activeRock = nil
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function bindRelease()
	releaseToken += 1
	local token = releaseToken
	task.delay(ChopConfig.RoundInputDelaySeconds, function()
		if token ~= releaseToken or not minigameActive or frozenPosition ~= nil then
			return
		end
		ContextActionService:BindAction(RELEASE_ACTION, function(_actionName, inputState)
			if inputState == Enum.UserInputState.Begin then
				frozenPosition = ChopZones.Position(os.clock() - minigameStartTime)
				Packets.ChopRelease:Fire()
				ContextActionService:UnbindAction(RELEASE_ACTION)
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, true, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.ButtonR2)
		ContextActionService:SetTitle(RELEASE_ACTION, "Chop")
	end)
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
	maxHealth: number
)
	if minigameActive then
		return
	end
	minigameActive = true
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
	local rockScale = math.max(1, rock.Size.Z / ChopConfig.ReferenceRockSize)
	local isRelative = rock:GetAttribute(ChopConfig.RelativeOffsetAttribute) == true
	local function offset(vector: Vector3): Vector3
		return if isRelative then rock.CFrame:VectorToWorldSpace(vector) else vector
	end
	local rootStart: CFrame? = if rootPart then rootPart.CFrame else nil
	local rootTarget: CFrame? = nil
	if rootPart then
		local groundY = rock.Position.Y - rock.Size.Y / 2 + rootPart.Size.Y * 1.5
		local snapPos = rock.Position + offset(ChopConfig.PlayerSnapOffsetFromRock) * rockScale
		snapPos = Vector3.new(snapPos.X, groundY, snapPos.Z)
		rootTarget = CFrame.lookAt(snapPos, rock.Position)
			* CFrame.new(-ChopConfig.PlayerSnapLeftShiftStuds, 0, 0)
	end

	local camera = workspace.CurrentCamera
	local cameraStart: CFrame? = nil
	local cameraTarget: CFrame? = nil
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		cameraStart = camera.CFrame
		local cameraPos = rock.Position + offset(ChopConfig.CameraOffsetFromRock) * rockScale
		cameraTarget = CFrame.new(cameraPos, rock.Position + offset(ChopConfig.CameraLookOffset))
		chopCamera = cameraTarget
	end

	local transitionStart = os.clock()
	local transition: RBXScriptConnection
	transition = RunService.RenderStepped:Connect(function()
		local progress = math.clamp((os.clock() - transitionStart) / ChopConfig.CameraTransitionSeconds, 0, 1)
		local eased = progress * progress * (3 - 2 * progress)
		if camera and cameraStart and cameraTarget then
			camera.CFrame = cameraStart:Lerp(cameraTarget, eased)
		end
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
		local savedWalkSpeed = humanoid.WalkSpeed
		local savedJumpPower = humanoid.JumpPower
		local savedJumpHeight = humanoid.JumpHeight
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		trove:Add(function()
			if humanoid.Parent then
				humanoid.WalkSpeed = savedWalkSpeed
				humanoid.JumpPower = savedJumpPower
				humanoid.JumpHeight = savedJumpHeight
			end
		end)
	end

	minigameStartTime = os.clock()
	uiController:Open(METER_SCREEN)
	uiController:Close(EXP_BAR_SCREEN)
	trove:Add(function()
		uiController:Close(METER_SCREEN)
		uiController:Open(EXP_BAR_SCREEN)
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
}

function ChopController.GetZoneCenter(_self: any): number
	return zoneCenter
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

function ChopController.GetMasterPhase(_self: any): string?
	local started = masterStartClock
	if not started then
		return nil
	end
	if os.clock() - started < MasterChopConfig.ImpactDelaySeconds then
		return "WindUp"
	end
	return "Strike"
end

function ChopController.IsReleased(_self: any): boolean
	return frozenPosition ~= nil
end

function ChopController.CanBreakRock(_self: any): boolean
	return activeCanBreak
end

function ChopController.GetCursorPosition(_self: any): number
	if not minigameActive then
		return 0
	end
	return frozenPosition or ChopZones.Position(os.clock() - minigameStartTime)
end

function ChopController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	self.ResultShown = Signal.new()
	self.HealthChanged = Signal.new()
	self.RoundStarted = Signal.new()
	self.ActiveChanged = Signal.new()
	activeChanged = self.ActiveChanged
	uiController = controllers.UIController
	rockController = controllers.RockController
	cashPopController = controllers.CashPopController
end

function ChopController.Start(self: any)
	local trove = self._trove :: TroveInstance
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
					beginMinigame(rock, canBreak, ratio, center, health, maxHealth)
				elseif not minigameActive then
					Packets.ChopLeave:Fire()
				end
			end
		)
	)
	trove:Add(Packets.ChopRoundStart.OnClientEvent:Connect(function(center: number)
		if not minigameActive then
			return
		end
		zoneCenter = center
		frozenPosition = nil
		minigameStartTime = os.clock()
		bindRelease()
		self.RoundStarted:Fire()
	end))
	trove:Add(
		Packets.ChopResult.OnClientEvent:Connect(
			function(quality: number, payout: number, _damage: number, health: number)
				print(`[ChopController] {styleFor(quality).Name} chop, payout={payout}`)
				local isMaster = quality == ChopQuality.Master
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
				local camera = workspace.CurrentCamera
				if camera and camera.CameraType == Enum.CameraType.Scriptable then
					shakeCamera(
						camera,
						if isMaster and chopCamera then chopCamera else camera.CFrame,
						qualityShakeIntensity(quality),
						if isMaster
							then MasterChopConfig.ShakeDurationSeconds
							elseif quality == ChopQuality.Perfect then ChopConfig.PerfectShakeDurationSeconds
							else ChopConfig.ShakeDurationSeconds
					)
				end
				if payout > 0 then
					local rock = activeRock
					local popAt = if rock then rock.Position + Vector3.new(0, rock.Size.Y / 2, 0) else nil
					task.delay(ChopConfig.MoneyEffectDelaySeconds, function()
						LocalSound.Play("SFX_Money_Gain")
						if popAt then
							cashPopController:Play(popAt, CashPopConfig.Chop)
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
end

return ChopController
