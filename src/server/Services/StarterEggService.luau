--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local HatchRevealConfig = require(ReplicatedStorage.Config.HatchRevealConfig)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local StarterEggConfig = require(ReplicatedStorage.Config.StarterEggConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local OWNED_PROMPT_TAG = "OwnedPrompt"
local TICK_SECONDS = 1
local SPOT_CLEANUP_SECONDS = 5

type Egg = {
	SecondsLeft: number,
	Model: Model?,
	Prompt: ProximityPrompt?,
	IsDropping: boolean,
	IsOpening: boolean,
	HasToldReady: boolean,
}

local StarterEggService = { Name = "StarterEggService" }

local services: { [string]: any } = {}
local trove = Trove.new()
local eggs: { [Player]: Egg } = {}
local lastTick = 0
local lastSave = 0

local function notify(player: Player, message: string)
	services.NotificationService:Notify(
		player,
		"Event",
		message,
		ItemIcons.Get("Pet", StarterEggConfig.PetKey)
	)
end

local function spotOf(player: Player): CFrame?
	local data = services.DataService:GetData(player)
	if not data then
		return nil
	end
	local index = data.StarterEgg.PadIndex
	if index == 0 or data.HatchPads[tostring(index)] ~= nil then
		local free = services.GeodeService:FreePadIndex(player)
		if not free then
			return nil
		end
		index = free
		services.DataService:Set(player, { "StarterEgg", "PadIndex" }, index)
		services.GeodeService:Refresh(player)
	end
	local spot = services.GeodeService:GetPadSpot(player, index)
	if not spot then
		return nil
	end
	local top = spot.WorldCFrame
	local look = top.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then
		look = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(top.Position, top.Position + look.Unit)
end

local function save(player: Player)
	local egg = eggs[player]
	local data = services.DataService:GetData(player)
	if not egg or not data or not data.StarterEgg.HasEgg then
		return
	end
	local seconds = math.max(0, math.ceil(egg.SecondsLeft))
	if data.StarterEgg.SecondsLeft ~= seconds then
		services.DataService:Set(player, { "StarterEgg", "SecondsLeft" }, seconds)
	end
end

local function removeModel(egg: Egg)
	if egg.Model then
		egg.Model:Destroy()
	end
	egg.Model = nil
	egg.Prompt = nil
end

local function isReady(egg: Egg): boolean
	return egg.SecondsLeft <= 0 and not egg.IsDropping
end

local function refreshPrompt(egg: Egg)
	if egg.Prompt then
		egg.Prompt:SetAttribute("Active", isReady(egg) and not egg.IsOpening)
	end
end

local function publishTimer(egg: Egg)
	local model = egg.Model
	local part = if model then model.PrimaryPart else nil
	if part then
		local landsAt = part:GetAttribute(StarterEggConfig.LandsAtAttribute)
		local start = if type(landsAt) == "number"
			then math.max(landsAt, workspace:GetServerTimeNow())
			else workspace:GetServerTimeNow()
		part:SetAttribute(StarterEggConfig.EndsAtAttribute, start + math.max(egg.SecondsLeft, 0))
	end
	refreshPrompt(egg)
end

local function open(player: Player)
	local egg = eggs[player]
	local data = services.DataService:GetData(player)
	local model = if egg then egg.Model else nil
	local part = if model then model.PrimaryPart else nil
	if not egg or not data or not model or not part or not isReady(egg) or egg.IsOpening then
		return
	end
	if not services.GeodeService:HasBagRoom(player) then
		notify(player, StarterEggConfig.BagFullText)
		return
	end
	local pet = PetConfig.Pets[StarterEggConfig.PetKey]
	if not pet then
		return
	end
	egg.IsOpening = true
	refreshPrompt(egg)
	local revealDelay = ChopConfig.SlowMoPreImpactSeconds
	local revealSeconds = HatchTiming.RevealSeconds(pet.Rarity)
	local grant = services.PetService:Grant(player, StarterEggConfig.PetKey, nil, revealDelay + revealSeconds)
	if not grant then
		egg.IsOpening = false
		refreshPrompt(egg)
		return
	end
	services.DataService:Set(player, { "StarterEgg" }, {
		HasEgg = false,
		HasLanded = false,
		SecondsLeft = 0,
		PadIndex = 0,
		IsOpened = true,
	})
	services.DataService:RequestSave(player)
	local spot = Instance.new("Attachment")
	spot.Name = "StarterEggSpot"
	spot.WorldCFrame = model:GetPivot()
	spot.Parent = workspace.Terrain
	removeModel(egg)
	eggs[player] = nil
	services.GeodeService:Refresh(player)
	print(`[StarterEggService] {player.Name} opened the starter egg: pet={grant.PetKey}, new={grant.IsNew}`)
	task.delay(revealDelay, function()
		Packets.GeodeHatched:FireAllClients(
			player,
			spot,
			StarterEggConfig.Key,
			grant.PetKey,
			table.find(RarityConfig.Order, pet.Rarity) or 1,
			grant.IsNew,
			grant.Trait or "",
			grant.Modifier or "",
			grant.Size or ""
		)
	end)
	task.delay(
		revealDelay + revealSeconds + HatchRevealConfig.PetShowSeconds + SPOT_CLEANUP_SECONDS,
		function()
			spot:Destroy()
		end
	)
end

local function buildModel(player: Player, egg: Egg, spot: CFrame, landsAt: number): boolean
	local asset = AssetRegistry.get(StarterEggConfig.ModelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		warn(`[StarterEggService] Asset "{StarterEggConfig.ModelKey}" is not a Model`)
		return false
	end
	local model = asset :: Model
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		model:Destroy()
		return false
	end
	model.PrimaryPart = part
	model.Name = StarterEggConfig.ModelName
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = descendant == part
			descendant.CanTouch = false
		end
	end
	model:ScaleTo(StarterEggConfig.Scale)
	model:PivotTo(spot)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, spot.Position.Y - bottom, 0))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StarterEggPrompt"
	prompt.ActionText = StarterEggConfig.PromptText
	prompt.ObjectText = StarterEggConfig.DisplayName
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = StarterEggConfig.PromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt:SetAttribute("Active", false)
	CollectionService:AddTag(prompt, OWNED_PROMPT_TAG)
	prompt.Parent = part
	prompt.Triggered:Connect(function(who: Player)
		if who == player then
			open(player)
		end
	end)

	part:SetAttribute(StarterEggConfig.OwnerAttribute, player.UserId)
	part:SetAttribute(StarterEggConfig.LandsAtAttribute, landsAt)
	egg.Model = model
	egg.Prompt = prompt
	publishTimer(egg)
	CollectionService:AddTag(model, StarterEggConfig.Tag)
	model.Parent = workspace
	return true
end

local function show(player: Player)
	local egg = eggs[player]
	local data = services.DataService:GetData(player)
	if not egg or egg.Model or not data or not data.StarterEgg.HasLanded then
		return
	end
	local spot = spotOf(player)
	if spot then
		buildModel(player, egg, spot, 0)
	end
end

local function drop(player: Player)
	local egg = eggs[player]
	local spot = spotOf(player)
	if not egg or egg.Model or egg.IsDropping or not spot then
		return
	end
	egg.IsDropping = true
	local landsAt = workspace:GetServerTimeNow() + StarterEggConfig.MarkerLeadSeconds
	if not buildModel(player, egg, spot, landsAt) then
		egg.IsDropping = false
		return
	end
	notify(player, StarterEggConfig.FallingText)
	task.delay(StarterEggConfig.MarkerLeadSeconds, function()
		if eggs[player] ~= egg or not egg.Model then
			return
		end
		egg.IsDropping = false
		services.DataService:Set(player, { "StarterEgg", "HasLanded" }, true)
		services.DataService:RequestSave(player)
		publishTimer(egg)
		notify(player, StarterEggConfig.LandedText)
	end)
end

local function isNearPlot(player: Player): boolean
	local plot = services.BaseService:GetPlot(player)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not plot or not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - plot:GetPivot().Position).Magnitude <= StarterEggConfig.DropRangeStuds
end

local function track(player: Player)
	local data = services.DataService:GetData(player)
	if not data or not data.StarterEgg.HasEgg then
		return
	end
	local egg = eggs[player]
	if not egg then
		egg = {
			SecondsLeft = data.StarterEgg.SecondsLeft,
			Model = nil,
			Prompt = nil,
			IsDropping = false,
			IsOpening = false,
			HasToldReady = data.StarterEgg.SecondsLeft <= 0,
		}
		eggs[player] = egg
	end
	show(player)
end

local function tick()
	local clock = os.clock()
	local elapsed = clock - lastTick
	if elapsed < TICK_SECONDS then
		return
	end
	lastTick = clock
	for player, egg in eggs do
		local data = services.DataService:GetData(player)
		if not data then
			continue
		end
		if not data.StarterEgg.HasLanded then
			if not egg.Model and isNearPlot(player) then
				drop(player)
			end
			continue
		end
		if not egg.Model then
			show(player)
		end
		if egg.SecondsLeft > 0 then
			egg.SecondsLeft = math.max(0, egg.SecondsLeft - elapsed)
			if egg.SecondsLeft <= 0 then
				publishTimer(egg)
				save(player)
			end
		end
		if egg.SecondsLeft <= 0 and not egg.HasToldReady then
			egg.HasToldReady = true
			notify(player, StarterEggConfig.ReadyNoticeText)
		end
	end
	if clock - lastSave >= StarterEggConfig.SaveSeconds then
		lastSave = clock
		for player in eggs do
			save(player)
		end
	end
end

function StarterEggService.Give(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	local egg = eggs[player]
	if egg then
		removeModel(egg)
		eggs[player] = nil
	end
	services.DataService:Set(player, { "StarterEgg" }, {
		HasEgg = true,
		HasLanded = false,
		SecondsLeft = StarterEggConfig.HatchSeconds,
		PadIndex = 0,
		IsOpened = false,
	})
	services.GeodeService:Refresh(player)
	track(player)
	return true
end

function StarterEggService.PadIndexOf(_self: any, player: Player): number?
	local data = services.DataService:GetData(player)
	if not data or not data.StarterEgg.HasEgg or data.StarterEgg.PadIndex == 0 then
		return nil
	end
	return data.StarterEgg.PadIndex
end

function StarterEggService.SetSecondsLeft(_self: any, player: Player, seconds: number): boolean
	local egg = eggs[player]
	if not egg then
		return false
	end
	egg.SecondsLeft = math.max(0, seconds)
	egg.HasToldReady = egg.SecondsLeft <= 0
	publishTimer(egg)
	save(player)
	return true
end

function StarterEggService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function StarterEggService.Start(_self: any)
	trove:Add(services.TutorialService.Finished:Connect(function(player: Player)
		local data = services.DataService:GetData(player)
		if data and not data.StarterEgg.IsOpened and not data.StarterEgg.HasEgg then
			StarterEggService:Give(player)
		end
	end))
	trove:Add(services.DataService.PlayerLoaded:Connect(function(player: Player)
		track(player)
	end))
	trove:Add(services.BaseService.PlotClaimed:Connect(function(player: Player)
		show(player)
	end))
	trove:Add(services.BaseService.PlotReleased:Connect(function(player: Player)
		local egg = eggs[player]
		if egg then
			removeModel(egg)
		end
	end))
	trove:Add(services.DataService.PlayerReleasing:Connect(function(player: Player, data: any)
		local egg = eggs[player]
		if not egg then
			return
		end
		if data.StarterEgg.HasEgg then
			data.StarterEgg.SecondsLeft = math.max(0, math.ceil(egg.SecondsLeft))
		end
		removeModel(egg)
		eggs[player] = nil
	end))
	trove:Add(RunService.Heartbeat:Connect(tick))
end

function StarterEggService.Destroy(_self: any)
	for _, egg in eggs do
		removeModel(egg)
	end
	table.clear(eggs)
	trove:Destroy()
end

return StarterEggService
