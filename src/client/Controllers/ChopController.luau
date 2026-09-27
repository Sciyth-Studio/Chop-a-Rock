--!strict

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local ROCK_TAG = "ChopRock"
local RELEASE_ACTION = "ChopRelease"

local function qualityName(quality: number): string
	if quality == ChopQuality.Perfect then
		return "Perfect"
	elseif quality == ChopQuality.Good then
		return "Good"
	elseif quality == ChopQuality.Sloppy then
		return "Sloppy"
	elseif quality == ChopQuality.Crack then
		return "Crack"
	end
	return "Unknown"
end

local function computePosition(elapsed: number): number
	local phase = (elapsed / ChopConfig.CycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

local minigameActive = false
local activeTrove: TroveInstance? = nil

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
	barBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBackground.BorderSizePixel = 0
	barBackground.Parent = screenGui

	local goodZone = Instance.new("Frame")
	goodZone.AnchorPoint = Vector2.new(0, 0)
	goodZone.Position = UDim2.new(0, 0, 0, 0)
	goodZone.Size = UDim2.new(1, 0, 1 - ChopConfig.GoodThreshold, 0)
	goodZone.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	goodZone.BorderSizePixel = 0
	goodZone.Parent = barBackground

	local perfectZone = Instance.new("Frame")
	perfectZone.AnchorPoint = Vector2.new(0, 0)
	perfectZone.Position = UDim2.new(0, 0, 0, 0)
	perfectZone.Size = UDim2.new(1, 0, 1 - ChopConfig.PerfectThreshold, 0)
	perfectZone.BackgroundColor3 = Color3.fromRGB(240, 220, 60)
	perfectZone.BorderSizePixel = 0
	perfectZone.Parent = barBackground

	local cursor = Instance.new("Frame")
	cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	cursor.Size = UDim2.new(1.6, 0, 0, 4)
	cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cursor.BorderSizePixel = 0
	cursor.ZIndex = 5
	cursor.Position = UDim2.new(0.5, 0, 1, 0)
	cursor.Parent = barBackground

	local startTime = os.clock()

	trove:Add(RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local position = computePosition(elapsed)
		cursor.Position = UDim2.new(0.5, 0, 1 - position, 0)
	end))

	ContextActionService:BindAction(RELEASE_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
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
		endMinigame()
		print(`[ChopController] {qualityName(quality)} chop, payout={payout}`)
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
