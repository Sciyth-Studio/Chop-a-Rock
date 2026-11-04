--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local HeldItemConfig = require(ReplicatedStorage.Config.HeldItemConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local HeldItemController = {
	Name = "HeldItemController",
	_trove = nil :: TroveInstance?,
	_characterTrove = nil :: TroveInstance?,
}

local function bind(self: any, character: Model)
	if self._characterTrove then
		self._characterTrove:Clean()
	end
	local characterTrove = Trove.new()
	self._characterTrove = characterTrove
	local humanoid = character:WaitForChild("Humanoid", HeldItemConfig.LoadTimeoutSeconds)
	local animator = if humanoid
		then humanoid:WaitForChild("Animator", HeldItemConfig.LoadTimeoutSeconds)
		else nil
	if self._characterTrove ~= characterTrove or not animator or not animator:IsA("Animator") then
		return
	end
	local animation = AssetRegistry.get(HeldItemConfig.AnimationKey)
	if not animation:IsA("Animation") then
		animation:Destroy()
		return
	end
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	local function update()
		local isHolding = character:FindFirstChildOfClass("Tool") ~= nil
		if isHolding and not track.IsPlaying then
			track:Play(HeldItemConfig.FadeSeconds)
		elseif not isHolding and track.IsPlaying then
			track:Stop(HeldItemConfig.FadeSeconds)
		end
	end
	characterTrove:Connect(character.ChildAdded, update)
	characterTrove:Connect(character.ChildRemoved, update)
	update()
end

function HeldItemController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function HeldItemController.Start(self: any)
	local player = Players.LocalPlayer
	self._trove:Connect(player.CharacterAdded, function(character: Model)
		bind(self, character)
	end)
	if player.Character then
		task.spawn(bind, self, player.Character)
	end
end

function HeldItemController.Destroy(self: any)
	if self._characterTrove then
		self._characterTrove:Destroy()
	end
	if self._trove then
		self._trove:Destroy()
	end
end

return HeldItemController
