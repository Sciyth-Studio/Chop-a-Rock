--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Effects = require(script.Effects)
local Motion = require(script.Motion)
local Types = require(script.Types)

type TroveInstance = typeof(Trove.new())

local Themes = BossConfig.ArenaThemes
local Phases = BossConfig.Phases

local BossArenaController = {
	Name = "BossArenaController",
	_trove = nil :: TroveInstance?,
}

local sets: { Types.Active } = {}
local daisState: { Pieces: { Types.Piece }?, IsDown: boolean, Token: number } =
	{ Pieces = nil, IsDown = false, Token = 0 }
local dustTemplate: Model? = nil
local nextToken = 0

local function newToken(): number
	nextToken += 1
	return nextToken
end

local function arenaFloor(): BasePart?
	local arena = workspace:FindFirstChild(BossConfig.ArenaName)
	local floor = if arena then arena:FindFirstChild(Themes.FloorName) else nil
	return if floor and floor:IsA("BasePart") then floor else nil
end

local function setEmitters(active: Types.Active, isOn: boolean)
	for _, emitter in active.Emitters do
		emitter.Enabled = isOn
	end
end

local function puff(active: Types.Active, piece: Types.Piece)
	local template = dustTemplate
	if not template then
		return
	end
	if piece.IsProp then
		Effects.Puff(template, active.Model, piece.Base, Effects.DustScale(piece.Width), active.DustColor)
	elseif math.random() < Themes.TileDustChance then
		Effects.Puff(template, active.Model, piece.Base, Themes.TileDustScale, active.DustColor)
	end
end

local function daisPieces(): { Types.Piece }?
	if daisState.Pieces then
		return daisState.Pieces
	end
	local arena = workspace:FindFirstChild(BossConfig.ArenaName)
	local model = if arena then arena:FindFirstChild(Themes.DaisName) else nil
	local floor = arenaFloor()
	if not model or not model:IsA("Model") or not floor then
		return nil
	end
	local pieces = Motion.Collect(model, floor.Position + Vector3.new(0, floor.Size.Y / 2, 0))
	daisState.Pieces = pieces
	return pieces
end

local function moveDais(isDown: boolean, isInstant: boolean)
	local pieces = daisPieces()
	if not pieces or daisState.IsDown == isDown then
		return
	end
	daisState.IsDown = isDown
	local token = newToken()
	daisState.Token = token
	if isInstant then
		if isDown then
			Motion.Hide(pieces)
		else
			Motion.Show(pieces)
		end
		return
	end
	task.spawn(function()
		Motion.Schedule(pieces, not isDown)
		Motion.Run(pieces, not isDown, function()
			return daisState.Token == token
		end, function() end)
	end)
end

local function forget(active: Types.Active)
	local index = table.find(sets, active)
	if index then
		table.remove(sets, index)
	end
	for _, other in sets do
		if not other.Sinking then
			return
		end
	end
	moveDais(false, false)
end

local function sink(active: Types.Active)
	if active.Sinking then
		return
	end
	active.Sinking = true
	local token = newToken()
	active.Token = token
	setEmitters(active, false)
	task.spawn(function()
		local duration = Motion.Schedule(active.Pieces, false)
		Effects.Rumble(duration, active.Centre)
		Motion.Run(active.Pieces, false, function()
			return active.Token == token
		end, function(piece)
			puff(active, piece)
		end)
		if active.Token == token then
			forget(active)
			active.Model:Destroy()
		end
	end)
end

local function activeFor(boss: Model): Types.Active?
	for _, active in sets do
		if active.Boss == boss then
			return active
		end
	end
	return nil
end

local function showSet(boss: Model, setKey: string, isRising: boolean)
	if activeFor(boss) then
		return
	end
	local floor = arenaFloor()
	if not floor then
		warn(`[BossArenaController] No {Themes.FloorName} in Workspace.{BossConfig.ArenaName}`)
		return
	end
	local asset = AssetRegistry.get(setKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	for _, other in table.clone(sets) do
		sink(other)
	end
	local centre = floor.Position + Vector3.new(0, floor.Size.Y / 2, 0)
	asset.Name = Themes.FolderName
	asset:PivotTo(CFrame.new(centre))
	local emitters: { ParticleEmitter } = {}
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
			table.insert(emitters, descendant)
		end
	end
	local dustColor = asset:GetAttribute(Themes.DustColorAttribute)
	local token = newToken()
	local active: Types.Active = {
		Model = asset,
		Boss = boss,
		Pieces = Motion.Collect(asset, centre),
		Emitters = emitters,
		Centre = centre,
		DustColor = if typeof(dustColor) == "Color3" then dustColor else Color3.fromRGB(200, 180, 150),
		Token = token,
		Sinking = false,
	}
	table.insert(sets, active)
	if not isRising then
		moveDais(true, true)
		asset.Parent = workspace
		setEmitters(active, true)
		return
	end
	moveDais(true, false)
	Motion.Hide(active.Pieces)
	asset.Parent = workspace
	task.spawn(function()
		local duration = Motion.Schedule(active.Pieces, true)
		Effects.Rumble(duration, centre)
		local isDone = Motion.Run(active.Pieces, true, function()
			return active.Token == token
		end, function(piece)
			puff(active, piece)
		end)
		if isDone and active.Token == token then
			setEmitters(active, true)
		end
	end)
end

local function show(boss: Model)
	local key = boss:GetAttribute(BossConfig.BossAttribute)
	local setKey = if type(key) == "string" then Themes.Sets[key] else nil
	local phase = boss:GetAttribute(BossConfig.PhaseAttribute)
	if not setKey or phase == Phases.Defeated or phase == Phases.Leaving then
		return
	end
	showSet(boss, setKey, phase == nil or phase == Phases.Sleeping)
end

local function watch(trove: TroveInstance, boss: Instance)
	if not boss:IsA("Model") then
		return
	end
	if CollectionService:HasTag(boss, DiamondRockConfig.Tag) then
		showSet(boss, Themes.Sets[Themes.DiamondSetKey], true)
		return
	end
	local function refresh()
		local phase = boss:GetAttribute(BossConfig.PhaseAttribute)
		if phase == Phases.Defeated or phase == Phases.Leaving then
			local active = activeFor(boss)
			if active then
				task.delay(Themes.SinkDelaySeconds, sink, active)
			end
		else
			show(boss)
		end
	end
	trove:Connect(boss:GetAttributeChangedSignal(BossConfig.BossAttribute), refresh)
	trove:Connect(boss:GetAttributeChangedSignal(BossConfig.PhaseAttribute), refresh)
	refresh()
end

function BossArenaController.Init(self: any, _registry: { [string]: any })
	self._trove = Trove.new()
end

function BossArenaController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local dust = AssetRegistry.get(Themes.DustKey)
	if dust:IsA("Model") then
		dustTemplate = dust
	else
		dust:Destroy()
	end
	local watched: { [Instance]: TroveInstance } = {}
	local function add(instance: Instance)
		if watched[instance] then
			return
		end
		local bossTrove = Trove.new()
		watched[instance] = bossTrove
		watch(bossTrove, instance)
	end
	local function remove(instance: Instance)
		local bossTrove = watched[instance]
		if bossTrove then
			watched[instance] = nil
			bossTrove:Destroy()
		end
		if instance:IsA("Model") then
			local active = activeFor(instance)
			if active then
				sink(active)
			end
		end
	end
	for _, tag in { BossConfig.Tag, DiamondRockConfig.Tag } do
		trove:Connect(CollectionService:GetInstanceAddedSignal(tag), add)
		trove:Connect(CollectionService:GetInstanceRemovedSignal(tag), remove)
		for _, instance in CollectionService:GetTagged(tag) do
			add(instance)
		end
	end
	trove:Add(function()
		for instance in watched do
			remove(instance)
		end
		Effects.StopRumble()
		for _, active in sets do
			active.Token = newToken()
			active.Model:Destroy()
		end
		table.clear(sets)
		daisState.Token = newToken()
		if daisState.Pieces then
			Motion.Show(daisState.Pieces)
		end
	end)
end

function BossArenaController.Destroy(self: any)
	local trove = self._trove :: TroveInstance?
	if trove then
		trove:Destroy()
	end
	if dustTemplate then
		dustTemplate:Destroy()
		dustTemplate = nil
	end
end

local _lifecycleCheck: Lifecycle.System = BossArenaController

return BossArenaController
