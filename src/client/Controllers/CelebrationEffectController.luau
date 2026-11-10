--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local CelebrationConfig = require(ReplicatedStorage.Config.CelebrationConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

type TroveInstance = typeof(Trove.new())

local CelebrationEffectController = {
	Name = "CelebrationEffectController",
	_trove = nil :: TroveInstance?,
	_template = nil :: Model?,
}

local function feetCFrame(): CFrame?
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart
	if not humanoid or not rootPart then
		return nil
	end
	local feet = rootPart.Position - Vector3.new(0, rootPart.Size.Y / 2 + humanoid.HipHeight, 0)
	return CFrame.new(feet)
end

local active: { [any]: RBXScriptConnection } = {}

local function play(template: Model)
	local start = feetCFrame()
	if not start then
		return
	end
	local handle: any
	handle = VFXEmit.play(template, start, {
		onDone = function()
			local follow = active[handle]
			if follow then
				follow:Disconnect()
				active[handle] = nil
			end
		end,
	})
	if handle.finished then
		return
	end
	active[handle] = RunService.RenderStepped:Connect(function()
		local at = feetCFrame()
		if at and not handle.finished then
			handle.root:PivotTo(at)
		end
	end)
end

local function stopAll()
	for handle, follow in active do
		follow:Disconnect()
		handle:stop()
	end
	table.clear(active)
end

function CelebrationEffectController.PlayBurst(self: any)
	local template = self._template
	if template then
		play(template)
	end
	LocalSound.Play(CelebrationConfig.SoundKey, CelebrationConfig.SoundStartSeconds)
end

function CelebrationEffectController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function CelebrationEffectController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local asset = AssetRegistry.get(CelebrationConfig.EffectKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	self._template = asset
	trove:Add(asset)
	trove:Add(stopAll)
end

function CelebrationEffectController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return CelebrationEffectController
