--!strict

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local RELEASE_ACTION = "ChopRelease"
local METER_SCREEN = "ChopMeter"
local RESULT_DISPLAY_SECONDS = 0.7

local function styleFor(quality: number): ChopStyleConfig.QualityStyle
	return ChopStyleConfig.Qualities[quality] or ChopStyleConfig.Fallback
end

local function qualityShakeIntensity(quality: number): number
	if quality == ChopQuality.Perfect then
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

local function computePosition(elapsed: number): number
	local phase = (elapsed / ChopConfig.CycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

local uiController: any = nil
local minigameActive = false
local activeTrove: TroveInstance? = nil
local frozenPosition: number? = nil
local minigameStartTime = 0
local activeCanBreak = true

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
	ContextActionService:UnbindAction(RELEASE_ACTION)
	if activeTrove then
		activeTrove:Destroy()
		activeTrove = nil
	end
	frozenPosition = nil
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function beginMinigame(rock: BasePart, canBreak: boolean)
	if minigameActive then
		return
	end
	minigameActive = true
	frozenPosition = nil
	activeCanBreak = canBreak

	local trove = Trove.new()
	activeTrove = trove

	local character = Players.LocalPlayer.Character

	local rootPart = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local rockScale = math.max(1, rock.Size.Z / ChopConfig.ReferenceRockSize)
	local rootStart: CFrame? = if rootPart then rootPart.CFrame else nil
	local rootTarget: CFrame? = nil
	if rootPart then
		local groundY = rock.Position.Y - rock.Size.Y / 2 + rootPart.Size.Y * 1.5
		local snapPos = rock.Position + ChopConfig.PlayerSnapOffsetFromRock * rockScale
		snapPos = Vector3.new(snapPos.X, groundY, snapPos.Z)
		rootTarget = CFrame.lookAt(snapPos, rock.Position)
	end

	local camera = workspace.CurrentCamera
	local cameraStart: CFrame? = nil
	local cameraTarget: CFrame? = nil
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		cameraStart = camera.CFrame
		local cameraPos = rock.Position + ChopConfig.CameraOffsetFromRock * rockScale
		cameraTarget = CFrame.new(cameraPos, rock.Position + ChopConfig.CameraLookOffset)
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
	trove:Add(function()
		uiController:Close(METER_SCREEN)
	end)

	ContextActionService:BindAction(RELEASE_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			frozenPosition = computePosition(os.clock() - minigameStartTime)
			Packets.ChopRelease:Fire()
			ContextActionService:UnbindAction(RELEASE_ACTION)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.ButtonR2)
end

local ChopController = {
	Name = "ChopController",
	_trove = nil :: TroveInstance?,
	ResultShown = nil :: any,
}

function ChopController.IsMinigameActive(_self: any): boolean
	return minigameActive
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
	return frozenPosition or computePosition(os.clock() - minigameStartTime)
end

function ChopController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	self.ResultShown = Signal.new()
	uiController = controllers.UIController
end

function ChopController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.ChopMinigameStart.OnClientEvent:Connect(function(rock: Instance, canBreak: boolean)
		if rock:IsA("BasePart") then
			beginMinigame(rock, canBreak)
		end
	end))
	trove:Add(Packets.ChopResult.OnClientEvent:Connect(function(quality: number, payout: number)
		print(`[ChopController] {styleFor(quality).Name} chop, payout={payout}`)
		task.wait(ChopConfig.SlowMoPreImpactSeconds)
		if not minigameActive then
			return
		end
		self.ResultShown:Fire(quality)
		if quality == ChopQuality.Perfect then
			flashScreen()
		end
		local camera = workspace.CurrentCamera
		if camera and camera.CameraType == Enum.CameraType.Scriptable then
			shakeCamera(
				camera,
				camera.CFrame,
				qualityShakeIntensity(quality),
				if quality == ChopQuality.Perfect
					then ChopConfig.PerfectShakeDurationSeconds
					else ChopConfig.ShakeDurationSeconds
			)
		end
		if payout > 0 then
			task.delay(ChopConfig.MoneyEffectDelaySeconds, function()
				LocalSound.Play("SFX_Money_Gain")
			end)
		end
		task.delay(RESULT_DISPLAY_SECONDS, function()
			endMinigame()
		end)
	end))
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
end

return ChopController
