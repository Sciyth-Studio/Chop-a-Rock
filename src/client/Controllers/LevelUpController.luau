--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local LevelConfig = require(ReplicatedStorage.Config.LevelConfig)
local Level = require(ReplicatedStorage.Utils.Level)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any

type TroveInstance = typeof(Trove.new())

local LevelUpController = {
	Name = "LevelUpController",
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

function LevelUpController.Init(self: any, controllers: { [string]: any })
	self._controllers = controllers
	self._trove = Trove.new()
end

function LevelUpController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local asset = AssetRegistry.get(LevelConfig.LevelUpEffectKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	local template = asset
	trove:Add(template)
	trove:Add(stopAll)

	local lastLevel: number? = nil
	trove:Add(self._controllers.DataController:Observe({ "Strength" }, function(value: any)
		local level = Level.FromStrength(if type(value) == "number" then value else 0).Level
		if lastLevel and level > lastLevel then
			play(template)
		end
		lastLevel = level
	end))
end

function LevelUpController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return LevelUpController
