--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local RebirthConfig = require(ReplicatedStorage.Config.RebirthConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any

type TroveInstance = typeof(Trove.new())

local RebirthEffectController = {
	Name = "RebirthEffectController",
	_trove = nil :: TroveInstance?,
	_controllers = {} :: { [string]: any },
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

function RebirthEffectController.Init(self: any, controllers: { [string]: any })
	self._controllers = controllers
	self._trove = Trove.new()
end

function RebirthEffectController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local asset = AssetRegistry.get(RebirthConfig.RebirthEffectKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	local template = asset
	trove:Add(template)
	trove:Add(stopAll)

	local dataController = self._controllers.DataController
	local lastRebirths: number? = nil
	trove:Add(dataController:Observe({ "Rebirths" }, function()
		local rebirths = dataController:Get({ "Rebirths" })
		if type(rebirths) ~= "number" then
			return
		end
		if lastRebirths and rebirths == lastRebirths + 1 then
			play(template)
			LocalSound.Play(RebirthConfig.RebirthSoundKey, RebirthConfig.RebirthSoundStartSeconds)
		end
		lastRebirths = rebirths
	end))
end

function RebirthEffectController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return RebirthEffectController
