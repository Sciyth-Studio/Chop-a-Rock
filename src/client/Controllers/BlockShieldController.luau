--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BlockRoundConfig = require(ReplicatedStorage.Config.BlockRoundConfig)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossFxConfig = require(ReplicatedStorage.Config.BossFxConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

type TroveInstance = typeof(Trove.new())
type Shield = {
	Model: Model,
	Parts: { [BasePart]: Vector3 },
	Colors: { [BasePart]: Color3 },
	Burst: Attachment?,
	Trove: TroveInstance,
	Scale: number,
	Shudder: number,
}

local spec = BossFxConfig.Shield
local Outcomes = BlockRoundConfig.Outcomes

local BlockShieldController = {
	Name = "BlockShieldController",
	_trove = nil :: TroveInstance?,
}

local chopController: any = nil
local active: Shield? = nil

local function rootPart(): BasePart?
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end

local function placement(): CFrame?
	local root = rootPart()
	local target = if chopController then chopController:GetTarget() else nil
	if not root or not target then
		return nil
	end
	local flat = Vector3.new(target.Position.X - root.Position.X, 0, target.Position.Z - root.Position.Z)
	local forward = if flat.Magnitude > 1e-3 then flat.Unit else root.CFrame.LookVector
	local position = root.Position + forward * spec.DistanceStuds + Vector3.yAxis * spec.HeightStuds
	return CFrame.lookAt(position, position + forward) * CFrame.Angles(0, math.pi / 2, 0)
end

local function setScale(shield: Shield, scale: number)
	for part, size in shield.Parts do
		part.Size = Vector3.new(size.X, size.Y * scale, size.Z * scale)
	end
end

local function tint(shield: Shield, color: Color3?, seconds: number)
	for part, base in shield.Colors do
		part.Color = color or base
		if color then
			TweenService:Create(part, TweenInfo.new(seconds), { Color = base }):Play()
		end
	end
end

local function emit(shield: Shield, counts: { [string]: number })
	local burst = shield.Burst
	if not burst or LowGraphics.IsOn() then
		return
	end
	for name, count in counts do
		local emitter = burst:FindFirstChild(name)
		if emitter and emitter:IsA("ParticleEmitter") then
			emitter:Emit(count)
		end
	end
end

local function removeShield(shield: Shield, delaySeconds: number)
	if active == shield then
		active = nil
	end
	task.delay(delaySeconds, function()
		shield.Trove:Destroy()
	end)
end

local function hide(shield: Shield)
	for part in shield.Parts do
		part.Transparency = 1
	end
end

local function popTo(shield: Shield, peak: number)
	local start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local alpha = math.clamp((os.clock() - start) / spec.PopSeconds, 0, 1)
		shield.Scale = 1 + (peak - 1) * math.sin(alpha * math.pi)
		if alpha >= 1 then
			connection:Disconnect()
		end
	end)
	shield.Trove:Add(connection)
end

local function flashInstance(instance: Instance, color: Color3, transparency: number, seconds: number)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = transparency
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = instance
	highlight.Parent = instance
	local tween = TweenService:Create(highlight, TweenInfo.new(seconds), { FillTransparency = 1 })
	tween.Completed:Once(function()
		highlight:Destroy()
	end)
	tween:Play()
end

local function counterHit()
	local target = if chopController then chopController:GetTarget() else nil
	if not target or target:GetAttribute(BossConfig.SpotIndexAttribute) == nil then
		return
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if model then
		flashInstance(model, spec.CounterFlashColor, spec.CounterFlashTransparency, spec.CounterFlashSeconds)
	end
	if LowGraphics.IsOn() then
		return
	end
	local template = AssetRegistry.get(spec.CounterBurstKey)
	VFXEmit.play(template, CFrame.new(target.Position))
	task.delay(5, function()
		template:Destroy()
	end)
end

local function showShield()
	if active then
		removeShield(active, 0)
	end
	local start = placement()
	if not start then
		return
	end
	local template = AssetRegistry.get("VFX_Block_Shield")
	if not template:IsA("Model") then
		template:Destroy()
		return
	end
	local model = template
	local trove = Trove.new()
	trove:Add(model)
	local parts: { [BasePart]: Vector3 } = {}
	local colors: { [BasePart]: Color3 } = {}
	local primary = model.PrimaryPart
	local offsets: { [BasePart]: CFrame } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			parts[part] = part.Size
			colors[part] = part.Color
			if primary then
				offsets[part] = primary.CFrame:ToObjectSpace(part.CFrame)
			end
		end
	end
	local burstInstance = if primary then primary:FindFirstChild("Burst") else nil
	local shield: Shield = {
		Model = model,
		Parts = parts,
		Colors = colors,
		Burst = if burstInstance and burstInstance:IsA("Attachment") then burstInstance else nil,
		Trove = trove,
		Scale = 0,
		Shudder = 0,
	}
	active = shield
	model.Parent = workspace
	local appearStart = os.clock()
	trove:Connect(RunService.RenderStepped, function()
		local base = placement()
		if not base then
			return
		end
		local now = os.clock()
		local appear = math.clamp((now - appearStart) / spec.AppearSeconds, 0, 1)
		local eased = 1 - (1 - appear) ^ 3
		local breath = 1 + math.sin(now * spec.BreathSpeed) * spec.BreathScale
		setScale(shield, eased * breath * shield.Scale)
		local frame = base
		if now < shield.Shudder then
			local studs = spec.ShudderStuds
			frame = frame * CFrame.new(0, (math.random() * 2 - 1) * studs, (math.random() * 2 - 1) * studs)
		end
		for part, offset in offsets do
			part.CFrame = frame * offset
		end
	end)
	shield.Scale = 1
end

local function resolve(outcome: number)
	local shield = active
	if not shield then
		return
	end
	local counts = if outcome == Outcomes.Perfect
		then spec.Emits.Perfect
		elseif outcome == Outcomes.Blocked then spec.Emits.Blocked
		else spec.Emits.Missed
	emit(shield, counts)
	if outcome == Outcomes.Missed then
		task.delay(spec.ShatterSeconds, hide, shield)
		removeShield(shield, spec.HoldAfterResultSeconds + 1)
		local character = Players.LocalPlayer.Character
		if character then
			flashInstance(character, spec.HitFlashColor, spec.HitFlashTransparency, spec.HitFlashSeconds)
		end
		return
	end
	local isPerfect = outcome == Outcomes.Perfect
	tint(shield, if isPerfect then spec.PerfectColor else spec.FlashColor, spec.PopSeconds)
	popTo(shield, if isPerfect then spec.PerfectPop else spec.BlockedPop)
	shield.Shudder = os.clock() + spec.ShudderSeconds
	if isPerfect then
		counterHit()
	end
	task.delay(spec.HoldAfterResultSeconds, hide, shield)
	removeShield(shield, spec.HoldAfterResultSeconds + 1)
end

function BlockShieldController.Init(self: any, registry: { [string]: any })
	self._trove = Trove.new()
	chopController = registry.ChopController
end

function BlockShieldController.Start(self: any)
	local trove = self._trove :: TroveInstance
	if not chopController then
		warn("[BlockShieldController] ChopController is not registered; no block shield")
		return
	end
	trove:Add(chopController.BlockStarted:Connect(function()
		showShield()
	end))
	trove:Add(chopController.BlockResolved:Connect(resolve))
	trove:Add(chopController.RoundStarted:Connect(function()
		local shield = active
		if shield then
			removeShield(shield, 0)
		end
	end))
	trove:Add(chopController.ActiveChanged:Connect(function(isActive: boolean)
		local shield = active
		if not isActive and shield then
			removeShield(shield, 0)
		end
	end))
	trove:Add(function()
		local shield = active
		if shield then
			removeShield(shield, 0)
		end
	end)
end

function BlockShieldController.Destroy(self: any)
	local trove = self._trove :: TroveInstance?
	if trove then
		trove:Destroy()
	end
end

local _lifecycleCheck: Lifecycle.System = BlockShieldController

return BlockShieldController
