--!strict

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local FontConfig = require(ReplicatedStorage.Config.FontConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local ROCK_TAG = "ChopRock"
local RELEASE_ACTION = "ChopRelease"
local RESULT_DISPLAY_SECONDS = 0.7

local COLOR_BAD = Color3.fromRGB(255, 0, 0)
local COLOR_MID = Color3.fromRGB(255, 140, 0)
local COLOR_GOOD = Color3.fromRGB(0, 255, 0)
local COLOR_GREAT = Color3.fromRGB(0, 120, 255)
local COLOR_PERFECT_PURPLE = Color3.fromRGB(170, 0, 255)

local RAINBOW_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 140, 0)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 120, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(90, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170, 0, 255)),
})

local function qualityName(quality: number): string
	if quality == ChopQuality.Perfect then
		return "Perfect"
	elseif quality == ChopQuality.Great then
		return "Great"
	elseif quality == ChopQuality.Good then
		return "Good"
	elseif quality == ChopQuality.Mid then
		return "Mid"
	elseif quality == ChopQuality.Bad then
		return "Bad"
	elseif quality == ChopQuality.Crack then
		return "Crack"
	end
	return "Unknown"
end

local function qualityDisplayText(quality: number): string
	if quality == ChopQuality.Perfect then
		return "PERFECT!"
	elseif quality == ChopQuality.Great then
		return "Great!"
	elseif quality == ChopQuality.Good then
		return "Good!"
	elseif quality == ChopQuality.Mid then
		return "Mid.."
	elseif quality == ChopQuality.Bad then
		return "Bad.."
	elseif quality == ChopQuality.Crack then
		return "Crack!"
	end
	return "?"
end

local function addTextStroke(label: TextLabel)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
end

local function addFrameStroke(frame: Frame, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = Color3.new(0, 0, 0)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = frame
end

local function qualityColor(quality: number): Color3
	if quality == ChopQuality.Perfect then
		return COLOR_PERFECT_PURPLE
	elseif quality == ChopQuality.Great then
		return COLOR_GREAT
	elseif quality == ChopQuality.Good then
		return COLOR_GOOD
	elseif quality == ChopQuality.Mid then
		return COLOR_MID
	elseif quality == ChopQuality.Bad then
		return COLOR_BAD
	end
	return COLOR_BAD
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

local function applyRainbow(label: TextLabel)
	label.TextColor3 = Color3.new(1, 1, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Color = RAINBOW_SEQUENCE
	gradient.Rotation = 0
	gradient.Parent = label
end

local function computePosition(elapsed: number): number
	local phase = (elapsed / ChopConfig.CycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

local minigameActive = false
local activeTrove: TroveInstance? = nil
local activeResultLabel: TextLabel? = nil
local frozenPosition: number? = nil

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

local function playLocalSound(key: string)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	SoundService:PlayLocalSound(asset)
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function spawnDamageNumber(worldPos: Vector3, payout: number, quality: number)
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

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 80)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	billboard.LightInfluence = 0
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.FontFace = FontConfig.Default
	label.TextScaled = true
	label.Text = `+${payout}`
	label.TextColor3 = qualityColor(quality)
	label.Parent = billboard
	addTextStroke(label)
	if quality == ChopQuality.Perfect then
		applyRainbow(label)
	end
	local labelStroke = label:FindFirstChildOfClass("UIStroke")

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
	activeResultLabel = nil
	frozenPosition = nil
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function beginMinigame()
	if minigameActive then
		return
	end
	minigameActive = true
	frozenPosition = nil

	local trove = Trove.new()
	activeTrove = trove

	local rock = CollectionService:GetTagged(ROCK_TAG)[1] :: BasePart?
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

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ChopMeter"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	local barBackground = Instance.new("Frame")
	barBackground.AnchorPoint = Vector2.new(0, 0.5)
	barBackground.Position = UDim2.new(0.72, 0, 0.5, 0)
	barBackground.Size = UDim2.new(0, 40, 0, 400)
	barBackground.BackgroundColor3 = COLOR_BAD
	barBackground.BorderSizePixel = 0
	barBackground.Parent = screenGui
	addFrameStroke(barBackground, 4)

	local midZone = Instance.new("Frame")
	midZone.AnchorPoint = Vector2.new(0, 0)
	midZone.Position = UDim2.new(0, 0, 0, 0)
	midZone.Size = UDim2.new(1, 0, 1 - ChopConfig.MidThreshold, 0)
	midZone.BackgroundColor3 = COLOR_MID
	midZone.BorderSizePixel = 0
	midZone.Parent = barBackground

	local goodZone = Instance.new("Frame")
	goodZone.AnchorPoint = Vector2.new(0, 0)
	goodZone.Position = UDim2.new(0, 0, 0, 0)
	goodZone.Size = UDim2.new(1, 0, 1 - ChopConfig.GoodThreshold, 0)
	goodZone.BackgroundColor3 = COLOR_GOOD
	goodZone.BorderSizePixel = 0
	goodZone.Parent = barBackground

	local greatZone = Instance.new("Frame")
	greatZone.AnchorPoint = Vector2.new(0, 0)
	greatZone.Position = UDim2.new(0, 0, 0, 0)
	greatZone.Size = UDim2.new(1, 0, 1 - ChopConfig.GreatThreshold, 0)
	greatZone.BackgroundColor3 = COLOR_GREAT
	greatZone.BorderSizePixel = 0
	greatZone.Parent = barBackground

	local perfectZone = Instance.new("Frame")
	perfectZone.AnchorPoint = Vector2.new(0, 0)
	perfectZone.Position = UDim2.new(0, 0, 0, 0)
	perfectZone.Size = UDim2.new(1, 0, 1 - ChopConfig.PerfectThreshold, 0)
	perfectZone.BackgroundColor3 = COLOR_PERFECT_PURPLE
	perfectZone.BorderSizePixel = 0
	perfectZone.Parent = barBackground

	local cursor = Instance.new("Frame")
	cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	cursor.Size = UDim2.new(1.6, 0, 0, 6)
	cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cursor.BorderSizePixel = 0
	cursor.ZIndex = 5
	cursor.Position = UDim2.new(0.5, 0, 1, 0)
	cursor.Parent = barBackground
	addFrameStroke(cursor, 2)

	local resultLabel = Instance.new("TextLabel")
	resultLabel.AnchorPoint = Vector2.new(0, 0.5)
	resultLabel.Position = UDim2.new(0.72, 60, 0.5, 0)
	resultLabel.Size = UDim2.new(0, 260, 0, 80)
	resultLabel.BackgroundTransparency = 1
	resultLabel.FontFace = FontConfig.Default
	resultLabel.TextScaled = true
	resultLabel.TextColor3 = Color3.new(1, 1, 1)
	resultLabel.TextXAlignment = Enum.TextXAlignment.Left
	resultLabel.Text = ""
	resultLabel.Parent = screenGui
	addTextStroke(resultLabel)
	activeResultLabel = resultLabel

	local startTime = os.clock()

	trove:Add(RunService.RenderStepped:Connect(function()
		local position: number
		if frozenPosition then
			position = frozenPosition
		else
			position = computePosition(os.clock() - startTime)
		end
		cursor.Position = UDim2.new(0.5, 0, 1 - position, 0)
	end))

	ContextActionService:BindAction(RELEASE_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			frozenPosition = computePosition(os.clock() - startTime)
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
}

function ChopController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function ChopController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.ChopMinigameStart.OnClientEvent:Connect(function()
		beginMinigame()
	end))
	trove:Add(Packets.ChopResult.OnClientEvent:Connect(function(quality: number, payout: number)
		print(`[ChopController] {qualityName(quality)} chop, payout={payout}`)
		task.wait(ChopConfig.SlowMoPreImpactSeconds)
		if not minigameActive then
			return
		end
		if activeResultLabel then
			local existingGradient = activeResultLabel:FindFirstChildOfClass("UIGradient")
			if existingGradient then
				existingGradient:Destroy()
			end
			activeResultLabel.Text = qualityDisplayText(quality)
			if quality == ChopQuality.Perfect then
				applyRainbow(activeResultLabel)
			else
				activeResultLabel.TextColor3 = qualityColor(quality)
			end
		end
		local camera = workspace.CurrentCamera
		if camera and camera.CameraType == Enum.CameraType.Scriptable then
			shakeCamera(
				camera,
				camera.CFrame,
				qualityShakeIntensity(quality),
				ChopConfig.ShakeDurationSeconds
			)
		end
		local rock = CollectionService:GetTagged(ROCK_TAG)[1] :: BasePart?
		task.delay(ChopConfig.MoneyEffectDelaySeconds, function()
			if rock then
				spawnDamageNumber(rock.Position, payout, quality)
			end
			playLocalSound("SFX_Money_Gain")
		end)
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
end

return ChopController
