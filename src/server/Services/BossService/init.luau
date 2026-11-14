--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local ArenaShare = require(ServerScriptService.Utils.ArenaShare)
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BlockJudge = require(ServerScriptService.Utils.BlockJudge)
local BlockRoundConfig = require(ReplicatedStorage.Config.BlockRoundConfig)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossHazards = require(ReplicatedStorage.BossHazards)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopZones = require(ReplicatedStorage.ChopZones)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PotionConfig = require(ReplicatedStorage.Config.PotionConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Attacks = require(script.Attacks)
local Fight = require(script.Fight)
local Signature = require(script.Signature)
local Types = require(script.Types)

local BossService = { Name = "BossService" }

local Phases = BossConfig.Phases
local AttackKinds = BossConfig.Attacks
local Signatures = BossConfig.Signatures
local endChopsDelaySeconds = 0.7
local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local current: Types.Fight? = nil
local sessions: { [Player]: Types.Session } = {}
local lastKey: string? = nil

local scheduleNextRound: (player: Player, session: Types.Session, pause: number) -> ()
local startAttack: (fight: Types.Fight, kind: number) -> ()
local knockOut: (fight: Types.Fight, player: Player) -> ()

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end

local function inTutorial(player: Player): boolean
	local data = services.DataService:GetData(player)
	return data == nil or Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

local function statsOf(player: Player): ArenaShare.ZoneStats?
	local data = services.DataService:GetData(player)
	return if data then ArenaShare.StatsFor(data.PeakStrength) else nil
end

local function bossOf(fight: Types.Fight): BossConfig.Boss
	return BossConfig.Bosses[fight.Key]
end

local function arenaSpot(): Vector3?
	local arena = workspace:FindFirstChild(BossConfig.ArenaName)
	local spot = if arena then arena:FindFirstChild(BossConfig.SpotName, true) else nil
	if spot and spot:IsA("BasePart") then
		return spot.Position - Vector3.new(0, spot.Size.Y / 2, 0)
	end
	return nil
end

local function gateCFrame(): CFrame?
	local arena = workspace:FindFirstChild(BossConfig.ArenaName)
	local gate = if arena then arena:FindFirstChild(BossConfig.GateName, true) else nil
	if gate and gate:IsA("BasePart") then
		return gate.CFrame + Vector3.new(0, 3, 0)
	end
	local spot = arenaSpot()
	return if spot then CFrame.new(spot + BossConfig.GateFallbackOffset) else nil
end

local function publish(fight: Types.Fight)
	local model = fight.Model
	model:SetAttribute(BossConfig.PhaseAttribute, fight.Phase)
	model:SetAttribute(BossConfig.MadAttribute, fight.IsMad)
	model:SetAttribute(BossConfig.HealthAttribute, math.max(fight.Health, 0))
	model:SetAttribute(BossConfig.MaxHealthAttribute, fight.MaxHealth)
	model:SetAttribute(BossConfig.EndsAtAttribute, workspace:GetServerTimeNow() + (fight.EndsAt - os.clock()))
	model:SetAttribute(BossConfig.GoldSpotAttribute, fight.GoldSpot)
end

local function loadClip(fight: Types.Fight, clip: string): AnimationTrack?
	local animator = fight.Animator
	if not animator then
		return nil
	end
	local asset = AssetRegistry.get(bossOf(fight).AnimPrefix .. clip)
	if not asset:IsA("Animation") then
		asset:Destroy()
		return nil
	end
	local track = animator:LoadAnimation(asset)
	asset:Destroy()
	return track
end

local function playLoop(fight: Types.Fight, clip: string)
	local old = fight.Loop
	local track = loadClip(fight, clip)
	fight.Loop = track
	if track then
		track.Looped = true
		track:Play(0.3)
	end
	if old then
		old:Stop(0.3)
	end
end

local function playOnce(fight: Types.Fight, clip: string)
	local track = loadClip(fight, clip)
	if track then
		track.Looped = false
		track:Play(0.15)
	end
end

local function setPlayerHealth(fight: Types.Fight, player: Player, health: number)
	local clamped = math.clamp(health, 0, BossConfig.PlayerHealth)
	fight.PlayerHealth[player] = clamped
	player:SetAttribute(BossConfig.PlayerHealthAttribute, clamped)
end

local function notifyFighters(fight: Types.Fight, text: string)
	for player in fight.Counted do
		if player.Parent then
			services.NotificationService:Notify(player, BossConfig.AnnouncementKind, text)
		end
	end
end

local function isOver(fight: Types.Fight): boolean
	return current ~= fight or fight.Phase == Phases.Defeated or fight.Phase == Phases.Leaving
end

local function arenaPlayers(fight: Types.Fight, center: Vector3): { Player }
	local found: { Player } = {}
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if
			root
			and not fight.KnockedOut[player]
			and not inTutorial(player)
			and Attacks.InArena(root.Position, center)
		then
			table.insert(found, player)
		end
	end
	return found
end

local function notifyArena(fight: Types.Fight, center: Vector3, text: string)
	local told: { [Player]: true } = {}
	for _, player in arenaPlayers(fight, center) do
		told[player] = true
		services.NotificationService:Notify(player, BossConfig.AnnouncementKind, text)
	end
	for player in fight.Counted do
		if player.Parent and not told[player] then
			services.NotificationService:Notify(player, BossConfig.AnnouncementKind, text)
		end
	end
end

local function clearAttackAttributes(fight: Types.Fight)
	local model = fight.Model
	model:SetAttribute(BossConfig.AttackAttribute, AttackKinds.None)
	model:SetAttribute(BossConfig.SlamRadiusAttribute, nil)
	BossHazards.Clear(model)
	fight.Hazard = nil
end

local function endSession(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	if session.Spot.Slots[session.Slot] == player then
		session.Spot.Slots[session.Slot] = nil
	end
	player:SetAttribute(DiamondRockConfig.PlayerSlotAttribute, nil)
end

local function endAllSessions(fight: Types.Fight, except: Player?)
	for player, session in sessions do
		if session.Fight ~= fight then
			continue
		end
		endSession(player)
		if player ~= except then
			Packets.ChopEnded:FireClient(player)
		end
	end
end

local function payWith(player: Player, amount: number): number
	if amount <= 0 then
		return 0
	end
	local payout = services.FriendBoostService:ApplyBoost(player, amount)
	payout = services.IndexService:ApplyCashMultiplier(player, payout)
	payout = services.PassService:ApplyCashMultiplier(player, payout)
	services.DataService:AdjustCash(player, payout, AnalyticsConfig.Sources.Boss)
	return payout
end

local function winBonus(player: Player): number
	local stats = statsOf(player)
	if not stats then
		return 0
	end
	local strength = services.StatsService:GetStrength(player)
	local round = Fight.RoundPay(stats, ChopQuality.Good, strength, ChopConfig.GoodDamageMultiplier)
	return round * BossConfig.WinBonusRounds
end

local function clearFight(fight: Types.Fight, cleanupSeconds: number)
	for player in fight.PlayerHealth do
		if player.Parent then
			player:SetAttribute(BossConfig.PlayerHealthAttribute, nil)
			player:SetAttribute(BossConfig.KnockedOutAttribute, nil)
		end
	end
	task.delay(cleanupSeconds, function()
		fight.Model:Destroy()
		if current == fight then
			current = nil
		end
	end)
end

local function finish(fight: Types.Fight, isWin: boolean, breaker: Player?)
	if fight.Phase == Phases.Defeated or fight.Phase == Phases.Leaving then
		return
	end
	fight.Token += 1
	fight.AttackToken += 1
	fight.Busy = false
	fight.Attack = AttackKinds.None
	clearAttackAttributes(fight)
	local name = bossOf(fight).DisplayName
	fight.Phase = if isWin then Phases.Defeated else Phases.Leaving
	if isWin then
		fight.Health = 0
	end
	publish(fight)
	endAllSessions(fight, breaker)
	if isWin then
		local defeat = loadClip(fight, BossConfig.Clips.Defeat)
		if defeat then
			defeat.Looped = false
			defeat.Priority = Enum.AnimationPriority.Action4
			defeat:Play(0.15)
			task.spawn(function()
				local waited = 0
				while defeat.Length <= 0 and waited < 2 do
					waited += task.wait()
				end
				task.wait(math.max(defeat.Length - BossConfig.DefeatHoldLeadSeconds, 0))
				if defeat.IsPlaying then
					defeat:AdjustSpeed(0)
				end
			end)
		end
		if fight.Loop then
			fight.Loop:Stop(0.2)
		end
	end
	for player, share in fight.Counted do
		if not player.Parent then
			continue
		end
		local dealt = fight.Dealt[player] or 0
		local pending = fight.Pending[player] or 0
		local isCredited = dealt >= share * BossConfig.WinCreditShare
		local paid = 0
		if isWin then
			paid = payWith(player, pending + (if isCredited then winBonus(player) else 0))
			if isCredited then
				services.PotionService:GrantRandom(player, PotionConfig.BossWinCount)
			end
		elseif fight.IsMad and dealt > 0 then
			paid = payWith(player, math.floor((pending + winBonus(player)) * BossConfig.AlmostShare + 0.5))
			if random:NextNumber() < PotionConfig.BossAlmostChance then
				services.PotionService:GrantRandom(player, 1)
			end
		end
		local text = if paid <= 0
			then nil
			elseif isWin and isCredited then string.format(
				BossConfig.WinText,
				name,
				NumberFormat.CompactRock(paid)
			)
			elseif isWin then string.format(BossConfig.EarnedText, name, NumberFormat.CompactRock(paid))
			else string.format(BossConfig.AlmostText, NumberFormat.CompactRock(paid))
		if text then
			services.NotificationService:Notify(player, BossConfig.AnnouncementKind, text, IconConfig.Money)
		end
		if not isWin then
			services.NotificationService:Notify(
				player,
				BossConfig.AnnouncementKind,
				string.format(if fight.IsMad then BossConfig.RanText else BossConfig.BoredText, name)
			)
		end
	end
	clearFight(fight, if isWin then BossConfig.DefeatSeconds else BossConfig.LeaveSeconds)
	print(`[BossService] {name} {if isWin then "beaten" else "left"} (mad={fight.IsMad})`)
end

local function becomeMad(fight: Types.Fight)
	if fight.IsMad then
		return
	end
	fight.IsMad = true
	fight.Phase = Phases.Mad
	fight.Busy = true
	fight.EndsAt = os.clock() + BossConfig.MadSeconds + BossConfig.HalfTwoSeconds
	local pupils = fight.Model:FindFirstChild(BossConfig.PupilsName)
	if pupils and pupils:IsA("BasePart") then
		pupils.Color = BossConfig.MadEyeColor
		pupils.Material = Enum.Material.Neon
	end
	playOnce(fight, BossConfig.Clips.Mad)
	publish(fight)
	notifyFighters(fight, string.format(BossConfig.MadText, bossOf(fight).DisplayName))
	local token = fight.Token
	task.delay(endChopsDelaySeconds, function()
		if current == fight and fight.Token == token then
			endAllSessions(fight, nil)
		end
	end)
	task.delay(BossConfig.MadSeconds, function()
		if current == fight and fight.Token == token and fight.Phase == Phases.Mad then
			fight.Phase = Phases.Fighting
			publish(fight)
			startAttack(fight, AttackKinds.Big)
		end
	end)
end

local function startFinish(fight: Types.Fight)
	fight.Phase = Phases.Finish
	fight.FinishUntil = os.clock() + BossConfig.FinishSeconds
	playLoop(fight, BossConfig.Clips.Dizzy)
	publish(fight)
	notifyFighters(fight, BossConfig.FinishText)
end

local function afterDamage(fight: Types.Fight, hitter: Player?)
	if Fight.IsBeaten(fight) then
		finish(fight, true, hitter)
		return
	end
	if fight.Busy then
		publish(fight)
		return
	end
	if Fight.ReachedHalf(fight) then
		becomeMad(fight)
	elseif
		not fight.IsMad
		and not fight.SlamDone
		and fight.Phase == Phases.Fighting
		and fight.Health <= fight.MaxHealth * BossConfig.Slam.HealthRatio
	then
		fight.SlamDone = true
		startAttack(fight, AttackKinds.Slam)
	elseif
		fight.IsMad
		and fight.BigCount < 2
		and fight.FinishUntil == 0
		and fight.Phase == Phases.Fighting
		and fight.Health <= fight.MaxHealth * BossConfig.BigAttack.SecondRatio
	then
		startAttack(fight, AttackKinds.Big)
	elseif
		fight.IsMad
		and fight.FinishUntil == 0
		and fight.Phase == Phases.Fighting
		and fight.Health <= fight.MaxHealth * BossConfig.FinishRatio
	then
		startFinish(fight)
	end
	publish(fight)
end

local function judge(fight: Types.Fight, player: Player, kind: number, center: Vector3, isSafe: boolean)
	local root = rootOf(player)
	if not root then
		return
	end
	local isBig = kind == AttackKinds.Big
	local health = fight.PlayerHealth[player] or BossConfig.PlayerHealth
	if isSafe then
		if isBig then
			setPlayerHealth(fight, player, health + BossConfig.BigAttack.SafeHeal)
			fight.NextBonus[player] = BossConfig.BigAttack.SafeBonus
		elseif not fight.PlayerHealth[player] then
			setPlayerHealth(fight, player, health)
		end
		Packets.BossAttackResult:FireClient(player, BossConfig.AttackOutcomes.Safe, Vector3.zero)
		return
	end
	local damage = if isBig then BossConfig.BigAttack.Damage else BossConfig.Slam.Damage
	local knockStuds = if isBig then BossConfig.BigAttack.KnockbackStuds else BossConfig.Slam.KnockbackStuds
	setPlayerHealth(fight, player, health - damage)
	Packets.BossAttackResult:FireClient(
		player,
		BossConfig.AttackOutcomes.Hit,
		Attacks.Knock(kind, root.Position, center, fight.Hazard, knockStuds)
	)
	if (fight.PlayerHealth[player] or 0) <= 0 then
		knockOut(fight, player)
	end
end

local function sweep(fight: Types.Fight, token: number, center: Vector3, hazard: BossHazards.Hazard): boolean
	local low, high = Attacks.SweepRange(hazard)
	local seconds = BossConfig.BigAttack.TailSweep.SweepSeconds
	local began = os.clock()
	local ahead: { [Player]: number } = {}
	local judged: { [Player]: true } = {}
	while true do
		if isOver(fight) or fight.AttackToken ~= token then
			return false
		end
		local alpha = math.clamp((os.clock() - began) / seconds, 0, 1)
		local line = low + (high - low) * alpha
		for _, player in arenaPlayers(fight, center) do
			if judged[player] then
				continue
			end
			local root = rootOf(player)
			local angle = if root then Attacks.SweepAngle(hazard, root.Position) else nil
			if not angle then
				continue
			end
			local was = ahead[player]
			if was and angle <= line and math.abs(angle - was) < math.pi then
				judged[player] = true
				judge(fight, player, AttackKinds.Big, center, false)
			elseif angle > line and angle <= high then
				ahead[player] = angle
			else
				ahead[player] = nil
			end
		end
		if alpha >= 1 then
			break
		end
		task.wait()
	end
	for _, player in arenaPlayers(fight, center) do
		if not judged[player] then
			judge(fight, player, AttackKinds.Big, center, true)
		end
	end
	return true
end

local function land(fight: Types.Fight, token: number, kind: number, center: Vector3)
	if isOver(fight) or fight.AttackToken ~= token then
		return
	end
	local isBig = kind == AttackKinds.Big
	local hazard = fight.Hazard
	if isBig and hazard and hazard.Style == BossConfig.BigStyles.TailSweep then
		if not sweep(fight, token, center, hazard) then
			return
		end
	else
		for _, player in arenaPlayers(fight, center) do
			local root = rootOf(player)
			if root then
				judge(
					fight,
					player,
					kind,
					center,
					Attacks.IsSafe(kind, root.Position, center, fight.SlamRadius, hazard)
				)
			end
		end
	end
	print(`[BossService] {fight.Key} {if isBig then "Big Attack" else "Slam"} landed`)
	local recover = if isBig then BossConfig.BigAttack.RecoverSeconds else BossConfig.Slam.RecoverSeconds
	task.delay(recover, function()
		if isOver(fight) or fight.AttackToken ~= token then
			return
		end
		fight.Busy = false
		fight.Attack = AttackKinds.None
		clearAttackAttributes(fight)
		if isBig and fight.IsMad and fight.NextSignature == math.huge then
			fight.NextSignature = os.clock() + BossConfig.Signature.EverySeconds
		end
		notifyArena(fight, center, BossConfig.BackText)
		afterDamage(fight, nil)
	end)
end

function startAttack(fight: Types.Fight, kind: number)
	if isOver(fight) then
		return
	end
	local center = arenaSpot() or fight.Model:GetPivot().Position
	local isBig = kind == AttackKinds.Big
	local warnSeconds = if isBig then BossConfig.BigAttack.WarnSeconds else BossConfig.Slam.WarnSeconds
	local clipHitSeconds = if isBig
		then BossConfig.BigAttack.ClipHitSeconds
		else BossConfig.Slam.ClipHitSeconds
	fight.Busy = true
	fight.Attack = kind
	fight.AttackToken += 1
	local token = fight.AttackToken
	task.delay(endChopsDelaySeconds, function()
		if not isOver(fight) and fight.AttackToken == token then
			endAllSessions(fight, nil)
		end
	end)
	local model = fight.Model
	model:SetAttribute(BossConfig.AttackCenterAttribute, center)
	local warnText = BossConfig.Slam.WarnText
	local judgeDelay = 0
	if isBig then
		fight.BigCount += 1
		local pivot = model:GetPivot()
		local origin = Vector3.new(pivot.Position.X, center.Y, pivot.Position.Z)
		local targets: { Vector3 } = {}
		for _, player in arenaPlayers(fight, center) do
			local root = rootOf(player)
			if root then
				table.insert(targets, root.Position)
			end
		end
		local style = bossOf(fight).BigStyle
		fight.Hazard =
			Attacks.BigHazard(style, fight.Spots, center, origin, pivot.LookVector, targets, random)
		BossHazards.Write(model, fight.Hazard :: BossHazards.Hazard)
		warnText = Attacks.WarnText(style)
		judgeDelay = Attacks.JudgeDelay(style)
	else
		fight.SlamRadius = Attacks.SlamRadius(fight.Spots, center)
		model:SetAttribute(BossConfig.SlamRadiusAttribute, fight.SlamRadius)
	end
	local clip = if isBig then BossConfig.Clips.BigAttack else BossConfig.Clips.Slam
	local sweeps = isBig and fight.Hazard ~= nil and fight.Hazard.Style == BossConfig.BigStyles.TailSweep
	task.delay(math.max(warnSeconds - clipHitSeconds, 0), function()
		if not sweeps and not isOver(fight) and fight.AttackToken == token then
			playOnce(fight, clip)
		end
	end)
	model:SetAttribute(BossConfig.AttackLandsAtAttribute, workspace:GetServerTimeNow() + warnSeconds)
	model:SetAttribute(BossConfig.AttackAttribute, kind)
	notifyArena(fight, center, warnText)
	task.delay(warnSeconds + judgeDelay, land, fight, token, kind, center)
	print(`[BossService] {fight.Key} {if isBig then "Big Attack" else "Slam"} started`)
end

local function triggerSignature(fight: Types.Fight)
	fight.NextSignature = os.clock() + BossConfig.Signature.EverySeconds
	local kind = bossOf(fight).Signature
	local banner = BossConfig.Signature.Banners[kind]
	for player, session in sessions do
		if session.Fight == fight then
			session.SignatureLeft = BossConfig.Signature.Rounds
			if
				kind ~= Signatures.Chomp
				and session.StartTime ~= nil
				and session.BlockStart == nil
				and session.Modifier == Signatures.None
			then
				session.SignatureLeft -= 1
				local values = Signature.Build(kind, session.Center, random)
				session.Modifier = kind
				Packets.ChopModifier:FireClient(player, kind, values[1], values[2], values[3], values[4])
			end
			if banner then
				services.NotificationService:Notify(player, BossConfig.AnnouncementKind, banner)
			end
		end
	end
	print(`[BossService] {fight.Key} signature move {banner or tostring(kind)}`)
end

local function canChop(fight: Types.Fight): boolean
	return fight.Phase == Phases.Fighting or fight.Phase == Phases.Mad or fight.Phase == Phases.Finish
end

local function tick(fight: Types.Fight)
	local now = os.clock()
	if not canChop(fight) then
		return
	end
	if now >= fight.EndsAt then
		finish(fight, false, nil)
		return
	end
	if fight.Phase == Phases.Finish and now >= fight.FinishUntil then
		fight.Phase = Phases.Fighting
		playLoop(fight, BossConfig.Clips.Idle)
		publish(fight)
	end
	if fight.IsMad and not fight.Busy and fight.Phase == Phases.Fighting and now >= fight.NextSignature then
		triggerSignature(fight)
	end
	if now >= fight.NextGoldMove then
		fight.NextGoldMove = now + BossConfig.GoldMoveSeconds
		local nextSpot = random:NextInteger(1, #fight.Spots - 1)
		fight.GoldSpot = if nextSpot >= fight.GoldSpot then nextSpot + 1 else nextSpot
		publish(fight)
		notifyFighters(fight, BossConfig.GoldMovedText)
	end
end

local function wake(fight: Types.Fight)
	if current ~= fight or fight.Phase ~= Phases.Sleeping then
		return
	end
	fight.Phase = Phases.Waking
	local now = os.clock()
	fight.EndsAt = now + BossConfig.WakeSeconds + BossConfig.HalfOneSeconds
	fight.NextGoldMove = now + BossConfig.WakeSeconds + BossConfig.GoldMoveSeconds
	playOnce(fight, BossConfig.Clips.Wake)
	publish(fight)
	local token = fight.Token
	task.delay(BossConfig.WakeSeconds, function()
		if current ~= fight or fight.Token ~= token or fight.Phase ~= Phases.Waking then
			return
		end
		fight.Phase = Phases.Fighting
		playLoop(fight, BossConfig.Clips.Idle)
		publish(fight)
		for _, player in Players:GetPlayers() do
			if not inTutorial(player) then
				services.NotificationService:Notify(player, BossConfig.AnnouncementKind, BossConfig.WakeText)
			end
		end
	end)
end

local function setupSpots(model: Model, root: BasePart, floorY: number, boss: BossConfig.Boss): { Types.Spot }
	local spots: { Types.Spot } = {}
	for index = 1, BossConfig.SpotCount do
		local part = model:FindFirstChild("WeakSpot" .. index)
		if not part or not part:IsA("BasePart") then
			warn(`[BossService] {model.Name} has no WeakSpot{index}`)
			continue
		end
		part:SetAttribute(ChopConfig.ScaleAttribute, boss.StandScale)
		part:SetAttribute(BossConfig.NormalAttribute, Fight.FlatNormal(root, part))
		part:SetAttribute(BossConfig.GroundYAttribute, floorY)
		part:SetAttribute(BossConfig.FanSlotsAttribute, BossConfig.SlotsPerSpot)
		part:SetAttribute(BossConfig.FanDegreesAttribute, BossConfig.FanDegrees)
		table.insert(spots, { Index = #spots + 1, Part = part, Slots = {} })
		part:SetAttribute(BossConfig.SpotIndexAttribute, #spots)
	end
	return spots
end

local function spawnBoss(key: string?): (boolean, string)
	if current then
		return false, "a boss is already out"
	end
	if services.DiamondRockService:IsActive() then
		return false, "a Diamond Rock is in the arena"
	end
	local chosen = key
	if not chosen or not BossConfig.Bosses[chosen] then
		local options = {}
		for _, option in BossConfig.Order do
			if option ~= lastKey then
				table.insert(options, option)
			end
		end
		chosen = options[random:NextInteger(1, #options)]
	end
	local bossKey = chosen :: string
	local boss = BossConfig.Bosses[bossKey]
	local position = arenaSpot()
	if not position then
		warn(`[BossService] No {BossConfig.SpotName} in Workspace.{BossConfig.ArenaName}`)
		return false, "no arena spot"
	end
	local asset = AssetRegistry.get(boss.TemplateKey)
	if not asset:IsA("Model") or not asset.PrimaryPart then
		asset:Destroy()
		return false, `no {boss.TemplateKey} model`
	end
	local model = asset
	local root = model.PrimaryPart :: BasePart
	model.Name = BossConfig.ModelName
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.pi, 0))
	local spots = setupSpots(model, root, position.Y, boss)
	if #spots == 0 then
		model:Destroy()
		return false, "boss has no weak spots"
	end
	model:SetAttribute(BossConfig.BossAttribute, bossKey)
	model:SetAttribute(BossConfig.AttackAttribute, AttackKinds.None)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local animator = if controller then controller:FindFirstChildWhichIsA("Animator") else nil
	local now = os.clock()
	local fight: Types.Fight = {
		Key = bossKey,
		Model = model,
		Animator = animator,
		Loop = nil,
		Spots = spots,
		Phase = Phases.Sleeping,
		IsMad = false,
		Health = 0,
		MaxHealth = 0,
		EndsAt = now + BossConfig.SleepSeconds,
		FinishUntil = 0,
		GoldSpot = random:NextInteger(1, #spots),
		NextGoldMove = math.huge,
		LastAttack = 0,
		Counted = {},
		Dealt = {},
		Pending = {},
		PlayerHealth = {},
		KnockedOut = {},
		NextBonus = {},
		Token = 0,
		Busy = false,
		Attack = AttackKinds.None,
		AttackToken = 0,
		SlamDone = false,
		BigCount = 0,
		SlamRadius = 0,
		Hazard = nil,
		NextSignature = math.huge,
	}
	current = fight
	lastKey = bossKey
	for _, player in Players:GetPlayers() do
		if not inTutorial(player) then
			local stats = statsOf(player)
			if stats then
				Fight.AddShare(fight, player, Fight.Share(stats, services.StatsService:GetStrength(player)))
				setPlayerHealth(fight, player, BossConfig.PlayerHealth)
			end
		end
	end
	publish(fight)
	CollectionService:AddTag(model, BossConfig.Tag)
	model.Parent = workspace
	playLoop(fight, BossConfig.Clips.Sleep)
	task.delay(BossConfig.SleepSeconds, wake, fight)
	task.spawn(function()
		while current == fight and fight.Phase ~= Phases.Defeated and fight.Phase ~= Phases.Leaving do
			tick(fight)
			task.wait(0.25)
		end
	end)
	for _, player in Players:GetPlayers() do
		services.NotificationService:Notify(
			player,
			BossConfig.AnnouncementKind,
			string.format(BossConfig.AnnouncementText, boss.DisplayName)
		)
	end
	print(`[BossService] {boss.DisplayName} in the arena: health={fight.MaxHealth}`)
	return true, `{boss.DisplayName} in the arena`
end

function knockOut(fight: Types.Fight, player: Player)
	fight.KnockedOut[player] = true
	player:SetAttribute(BossConfig.KnockedOutAttribute, true)
	endSession(player)
	Packets.ChopEnded:FireClient(player)
	services.NotificationService:Notify(player, BossConfig.AnnouncementKind, BossConfig.KnockedText)
	task.delay(BossConfig.KnockoutSeconds, function()
		fight.KnockedOut[player] = nil
		if not player.Parent then
			return
		end
		player:SetAttribute(BossConfig.KnockedOutAttribute, nil)
		if current == fight and canChop(fight) then
			setPlayerHealth(fight, player, BossConfig.PlayerHealth)
		end
		local gate = gateCFrame()
		local character = player.Character
		if gate and character then
			character:PivotTo(gate)
		end
	end)
end

local function resolveBlock(player: Player, session: Types.Session, outcome: number)
	session.BlockStart = nil
	session.BlockDifficulty = nil
	local fight = session.Fight
	Packets.BlockResult:FireClient(player, outcome)
	local health = fight.PlayerHealth[player] or BossConfig.PlayerHealth
	if outcome == BlockRoundConfig.Outcomes.Missed then
		setPlayerHealth(
			fight,
			player,
			health - (if fight.IsMad then BossConfig.MadMissDamage else BossConfig.MissDamage)
		)
		if (fight.PlayerHealth[player] or 0) <= 0 then
			knockOut(fight, player)
			return
		end
	elseif outcome == BlockRoundConfig.Outcomes.Perfect then
		setPlayerHealth(fight, player, health + BossConfig.PerfectHeal)
		session.Bonus = BossConfig.CounterBonus
		local strength = services.StatsService:GetStrength(player)
		local applied = Fight.Apply(fight, strength * ChopConfig.GreatDamageMultiplier)
		fight.Dealt[player] = (fight.Dealt[player] or 0) + applied
		afterDamage(fight, nil)
		if sessions[player] ~= session then
			return
		end
	end
	scheduleNextRound(player, session, ChopConfig.RoundPauseSeconds)
end

local function startBlockRound(player: Player, session: Types.Session, round: number)
	local fight = session.Fight
	local difficulty = if fight.IsMad
		then BlockRoundConfig.Difficulties.Mad
		else BlockRoundConfig.Difficulties.Normal
	session.Center = ChopZones.RandomCenter(random)
	session.Modifier = Signatures.None
	session.Centers = nil
	session.BlockStart = os.clock()
	session.BlockDifficulty = difficulty
	Packets.BlockRoundStart:FireClient(player, session.Center, difficulty.Speed, difficulty.ZoneScale)
	local now = os.clock()
	if fight.Phase == Phases.Fighting and now - fight.LastAttack >= BossConfig.AttackCooldownSeconds then
		fight.LastAttack = now
		playOnce(fight, BossConfig.Clips.Attack)
	end
	task.delay(BlockJudge.TimeoutSeconds(ChopZones.IsTouch(player), difficulty), function()
		if sessions[player] == session and session.Round == round and session.BlockStart then
			resolveBlock(player, session, BlockRoundConfig.Outcomes.Missed)
		end
	end)
end

function scheduleNextRound(player: Player, session: Types.Session, pause: number)
	session.StartTime = nil
	session.Round += 1
	local round = session.Round
	task.delay(pause, function()
		if sessions[player] ~= session or session.Round ~= round then
			return
		end
		local fight = session.Fight
		if fight.Busy then
			return
		end
		local every = if fight.IsMad then BossConfig.MadBlockEvery else BossConfig.BlockEvery
		if fight.Phase == Phases.Fighting and round % every == 0 then
			startBlockRound(player, session, round)
			return
		end
		session.Center = ChopZones.RandomCenter(random)
		local modifier = Signatures.None
		local values = { 0, 0, 0, 0 }
		session.Centers = nil
		if session.SignatureLeft > 0 and fight.Phase == Phases.Fighting then
			session.SignatureLeft -= 1
			modifier = bossOf(fight).Signature
			values = Signature.Build(modifier, session.Center, random)
			if modifier == Signatures.Chomp then
				session.Centers = values
			end
		end
		session.Modifier = modifier
		session.PerfectScale = if fight.IsMad then BossConfig.MadPerfectScale else 1
		session.StartTime = os.clock()
		Packets.ChopModifier:FireClient(player, modifier, values[1], values[2], values[3], values[4])
		Packets.ChopRoundStart:FireClient(player, session.Center)
	end)
end

local function onBlockPress(player: Player, claimed: number)
	local session = sessions[player]
	local started = if session then session.BlockStart else nil
	local difficulty = if session then session.BlockDifficulty else nil
	if not session or not started or not difficulty then
		return
	end
	resolveBlock(
		player,
		session,
		BlockJudge.Judge(started, claimed, session.Center, ChopZones.IsTouch(player), difficulty)
	)
end

local function onChopRequest(player: Player, spotIndex: number)
	local fight = current
	if not fight or not canChop(fight) or fight.Busy or sessions[player] or fight.KnockedOut[player] then
		return
	end
	if services.RockService:HasSession(player) or services.DiamondRockService:HasSession(player) then
		return
	end
	if inTutorial(player) then
		return
	end
	local spot = fight.Spots[spotIndex]
	local root = rootOf(player)
	if not spot or not root then
		return
	end
	local part = spot.Part
	local reach = ChopConfig.PromptRangeStuds
		+ math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2
		+ BossConfig.ChopRangeSlackStuds
	local offset = root.Position - part.Position
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > reach then
		return
	end
	local stats = statsOf(player)
	if not stats then
		return
	end
	local slot = Fight.FreeSlot(spot)
	if not slot then
		services.NotificationService:Notify(player, "Info", BossConfig.FullText)
		return
	end
	if not fight.Counted[player] then
		Fight.AddShare(fight, player, Fight.Share(stats, services.StatsService:GetStrength(player)))
		publish(fight)
	end
	if not fight.PlayerHealth[player] then
		setPlayerHealth(fight, player, BossConfig.PlayerHealth)
	end
	local strength = services.StatsService:GetStrength(player)
	local session: Types.Session = {
		Fight = fight,
		Spot = spot,
		Slot = slot,
		StrengthRatio = strength / math.max(stats.FirstRequirement, 1),
		ZoneRatio = ChopZones.CappedRatio(
			strength / math.max(stats.FirstRequirement, 1),
			ChopZones.IsTouch(player),
			BossConfig.MaxPerfectShare
		),
		PerfectScale = if fight.IsMad then BossConfig.MadPerfectScale else 1,
		Center = ChopZones.RandomCenter(random),
		StartTime = os.clock(),
		BlockStart = nil,
		BlockDifficulty = nil,
		Round = 0,
		Bonus = fight.NextBonus[player] or 1,
		SignatureLeft = 0,
		Modifier = Signatures.None,
		Centers = nil,
	}
	fight.NextBonus[player] = nil
	sessions[player] = session
	spot.Slots[slot] = player
	player:SetAttribute(DiamondRockConfig.PlayerSlotAttribute, slot)
	services.PetService:PutAway(player)
	Packets.ChopMinigameStart:FireClient(
		player,
		part,
		true,
		session.ZoneRatio,
		session.Center,
		fight.Health,
		fight.MaxHealth
	)
end

local function onRelease(player: Player, claimed: number)
	local session = sessions[player]
	if not session or not session.StartTime then
		return
	end
	if os.clock() - session.StartTime < ChopConfig.RoundInputDelaySeconds then
		return
	end
	local fight = session.Fight
	if not canChop(fight) or fight.Busy then
		return
	end
	local stats = statsOf(player)
	if not stats then
		return
	end
	local elapsed = ChopTiming.Elapsed(session.StartTime, claimed)
	local isTouch = ChopZones.IsTouch(player)
	local centers = session.Centers
	local center = if session.Modifier == Signatures.Chomp and centers
		then ChopZones.ChompCenter(elapsed, isTouch, centers)
		else session.Center
	local quality = ChopZones.Classify(
		ChopZones.Position(elapsed, isTouch),
		center,
		session.ZoneRatio,
		isTouch,
		session.PerfectScale * services.PotionService:FocusScale(player)
	)
	local rockService = services.RockService
	if rockService:ConsumeForcedMaster(player) or rockService:RollMaster(quality, session.StrengthRatio) then
		quality = ChopQuality.Master
	end
	services.StatsService:RecordChop(player, quality)
	local strength = services.StatsService:GetStrength(player)
	local damageMultiplier = rockService:DamageMultiplier(quality)
	local spotMultiplier = if fight.Phase == Phases.Finish or session.Spot.Index == fight.GoldSpot
		then (if fight.Phase == Phases.Finish then BossConfig.FinishMultiplier else BossConfig.GoldMultiplier)
		else 1
	local isShelled = Signature.IsShelled(session.Modifier, quality, ChopQuality.Great)
	local damage = if isShelled
		then 0
		else Fight.Damage(strength, quality, damageMultiplier) * spotMultiplier * session.Bonus
	session.Bonus = 1
	session.Modifier = Signatures.None
	session.Centers = nil
	local applied = Fight.Apply(fight, damage)
	fight.Dealt[player] = (fight.Dealt[player] or 0) + applied
	services.HotStreakService:KeepAlive(player)
	local payout = if isShelled then 0 else Fight.RoundPay(stats, quality, strength, damageMultiplier)
	fight.Pending[player] = (fight.Pending[player] or 0) + payout
	local health = math.max(fight.Health, 0)
	Packets.ChopResult:FireClient(player, quality, 0, applied, health, 1)
	print(
		`[BossService] {player.Name} hit {fight.Key} spot {session.Spot.Index}: quality={quality}, damage={string.format(
			"%.1f",
			applied
		)}, health={string.format("%.1f", health)}, payout={payout}`
	)
	afterDamage(fight, player)
	if sessions[player] ~= session then
		return
	end
	local pause = if quality == ChopQuality.Master
		then MasterChopConfig.ImpactDelaySeconds
			+ MasterChopConfig.StrikeHoldSeconds
			+ ChopConfig.RoundPauseSeconds
		else ChopConfig.RoundPauseSeconds
	scheduleNextRound(player, session, pause)
end

function BossService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function BossService.Start(_self: any)
	trove:Add(Packets.BossChop.OnServerEvent:Connect(onChopRequest))
	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))
	trove:Add(Packets.BlockPress.OnServerEvent:Connect(onBlockPress))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(endSession))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		endSession(player)
		local fight = current
		if fight then
			fight.Counted[player] = nil
			fight.Dealt[player] = nil
			fight.Pending[player] = nil
			fight.PlayerHealth[player] = nil
			fight.KnockedOut[player] = nil
			fight.NextBonus[player] = nil
		end
	end))
end

function BossService.EndSession(_self: any, player: Player)
	endSession(player)
end

function BossService.HasSession(_self: any, player: Player): boolean
	return sessions[player] ~= nil
end

function BossService.IsActive(_self: any): boolean
	return current ~= nil
end

function BossService.Spawn(_self: any, _player: Player?, key: string?): (boolean, string)
	return spawnBoss(key)
end

function BossService.WakeNow(_self: any): boolean
	local fight = current
	if not fight or fight.Phase ~= Phases.Sleeping then
		return false
	end
	wake(fight)
	return true
end

function BossService.DamageShare(_self: any, share: number): boolean
	local fight = current
	if not fight or not canChop(fight) then
		return false
	end
	Fight.Apply(fight, fight.MaxHealth * share)
	afterDamage(fight, nil)
	return true
end

function BossService.SetTimeLeft(_self: any, seconds: number): boolean
	local fight = current
	if not fight or not canChop(fight) then
		return false
	end
	fight.EndsAt = os.clock() + seconds
	publish(fight)
	return true
end

function BossService.ForceAttack(_self: any, kind: number): boolean
	local fight = current
	if not fight or fight.Busy or fight.Phase ~= Phases.Fighting then
		return false
	end
	if kind == AttackKinds.Slam then
		fight.SlamDone = true
	end
	startAttack(fight, kind)
	return true
end

function BossService.ForceSignature(_self: any): boolean
	local fight = current
	if not fight or fight.Busy or fight.Phase ~= Phases.Fighting then
		return false
	end
	triggerSignature(fight)
	return true
end

function BossService.Destroy(_self: any)
	trove:Clean()
	if current then
		current.Model:Destroy()
		current = nil
	end
	table.clear(sessions)
end

return BossService
