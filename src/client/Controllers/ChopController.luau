--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

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
local activeRock: BasePart? = nil
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

local function spawnDamageNumber(worldPos: Vector3, payout: number, quality: number)
	local template = AssetRegistry.get("VFX_DamageNumber")
	local label = template:FindFirstChild("Amount")
	if not template:IsA("BillboardGui") or not label or not label:IsA("TextLabel") then
		template:Destroy()
		return
	end

	local anchor = Instance.new("Part")
	anchor.Name = "DamageNumber"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = worldPos + ChopConfig.DamageNumberStartOffset
	anchor.Parent = workspace

	Typography.Apply(template)
	local style = styleFor(quality)
	label.Text = `+${payout}`
	label.TextColor3 = if style.IsRainbow then Color3.new(1, 1, 1) else style.Color
	local gradient = label:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Enabled = style.IsRainbow
	end
	local labelStroke = label:FindFirstChildOfClass("UIStroke")
	template.Parent = anchor

	local duration = ChopConfig.DamageNumberRiseSeconds
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local endPos = anchor.Position + Vector3.new(0, ChopConfig.DamageNumberRiseStuds, 0)
	TweenService:Create(anchor, info, { Position = endPos }):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	if labelStroke then
		TweenService:Create(labelStroke, info, { Transparency = 1 }):Play()
	end

	task.delay(duration + 0.1, function()
		if anchor.Parent then
			anchor:Destroy()
		end
	end)
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
	activeRock = nil
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
	activeRock = rock
	activeCanBreak = canBreak

	local trove = Trove.new()
	activeTrove = trove

	local character = Players.LocalPlayer.Character

	if rock and character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			local snapPos = rock.Position + ChopConfig.PlayerSnapOffsetFromRock
			rootPart.CFrame = CFrame.lookAt(snapPos, rock.Position)
		end
	end

	local camera = workspace.CurrentCamera
	if camera and rock then
		camera.CameraType = Enum.CameraType.Scriptable
		local rockPos = rock.Position
		local cameraPos = rockPos + ChopConfig.CameraOffsetFromRock
		local lookAt = rockPos + ChopConfig.CameraLookOffset
		camera.CFrame = CFrame.new(cameraPos, lookAt)
	end

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
		local camera = workspace.CurrentCamera
		if camera and camera.CameraType == Enum.CameraType.Scriptable then
			shakeCamera(
				camera,
				camera.CFrame,
				qualityShakeIntensity(quality),
				ChopConfig.ShakeDurationSeconds
			)
		end
		local rock = activeRock
		if payout > 0 then
			task.delay(ChopConfig.MoneyEffectDelaySeconds, function()
				if rock then
					spawnDamageNumber(rock.Position, payout, quality)
				end
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
