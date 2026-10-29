--!strict

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local IntroConfig = require(ReplicatedStorage.Config.IntroConfig)
local LoadingCoverConfig = require(ReplicatedStorage.Config.LoadingCoverConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Shots = require(script.Shots)
local Stage = require(script.Stage)
local Types = require(script.Types)

type TroveInstance = typeof(Trove.new())

type Event = { At: number, Run: () -> () }

local IntroController = {
	Name = "IntroController",
	LoadProgressed = nil :: any,
}

local HIDDEN_CORE_GUIS = { Enum.CoreGuiType.PlayerList }
local HOLD_MARGIN_SECONDS = 1 / 30
local DUST_KEY = "VFX_Rock_Dust"
local CRASH_KEY = "VFX_GeodeFall_Impact"
local LAND_KEY = "VFX_Cannon_Land"
local EFFECT_LIFETIME_SECONDS = 4
local MUSIC_PREFIX = "MUS_"
local MUSIC_GROUP = "Music"

local controllers: { [string]: any } = {}
local trove: TroveInstance? = nil
local isPlaying = false
local finishActive: (() -> ())? = nil

local function closeCover()
	local uiController = controllers.UIController
	if uiController then
		uiController:Close(LoadingCoverConfig.ScreenName)
	end
end

local function shouldPlay(): boolean
	local state = controllers.DataController:Get({ "Tutorial" })
	if type(state) ~= "table" then
		return false
	end
	local taps = if type(state.Taps) == "number" then state.Taps else 0
	local furthest = if type(state.Furthest) == "number" then state.Furthest else Tutorial.Train
	return state.Step == Tutorial.Train and taps == 0 and furthest <= Tutorial.Train
end

local function standPosition(): Vector3?
	local plots = workspace:FindFirstChild("BasePlots")
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		if plot:GetAttribute("OwnerUserId") ~= Players.LocalPlayer.UserId then
			continue
		end
		local stand = plot:FindFirstChild("TrainingStand", true)
		if not stand then
			return nil
		end
		for _, tagged in CollectionService:GetTagged("TrainingBoard") do
			if tagged:IsA("BasePart") and tagged:IsDescendantOf(stand) then
				return tagged.Position
			end
		end
		if stand:IsA("Model") then
			return stand:GetPivot().Position
		end
	end
	return nil
end

local function waitForStand(): Vector3?
	local start = os.clock()
	while os.clock() - start < IntroConfig.PlotTimeoutSeconds do
		local position = standPosition()
		if position then
			return position
		end
		task.wait(0.25)
	end
	return nil
end

local function flatLook(from: Vector3, to: Vector3): Vector3?
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else nil
end

local function arrivalCamera(root: BasePart, stand: Vector3?): CFrame
	local look = if stand then flatLook(root.Position, stand) else nil
	local forward = look or root.CFrame.LookVector
	local position = root.Position
		- forward * IntroConfig.ArriveBackStuds
		+ Vector3.yAxis * IntroConfig.ArriveHeightStuds
	return CFrame.lookAt(position, root.Position + forward * IntroConfig.ArriveBackStuds * 0.5)
end

local function play(character: Model, humanoid: Humanoid, realRoot: BasePart)
	local uiController = controllers.UIController
	local rockController = controllers.RockController
	local camera = workspace.CurrentCamera
	if not camera then
		closeCover()
		return
	end
	isPlaying = true
	local runTrove = Trove.new()
	local reopen: { string } = {}
	for _, name in IntroConfig.HiddenScreens do
		if uiController:IsOpen(name) then
			table.insert(reopen, name)
			uiController:Close(name)
		end
	end
	local coreStates: { [Enum.CoreGuiType]: boolean } = {}
	for _, coreType in HIDDEN_CORE_GUIS do
		coreStates[coreType] = StarterGui:GetCoreGuiEnabled(coreType)
		StarterGui:SetCoreGuiEnabled(coreType, false)
	end
	local promptsWereEnabled = ProximityPromptService.Enabled
	ProximityPromptService.Enabled = false
	local unlockMovement = MovementLock.Acquire(humanoid)
	local releaseMusic = controllers.MusicController:Hold()
	uiController:Open(IntroConfig.LetterboxScreen)

	local stage: Types.Stage? = nil
	local shots: Shots.State? = nil
	local isFinished = false
	local stand: Vector3? = nil

	local function finish()
		if isFinished then
			return
		end
		isFinished = true
		finishActive = nil
		runTrove:Destroy()
		if shots then
			Shots.Stop(shots)
		end
		if stage then
			Stage.Destroy(stage)
		end
		uiController:Close(IntroConfig.LetterboxScreen)
		for _, name in reopen do
			uiController:Open(name)
		end
		for coreType, wasEnabled in coreStates do
			StarterGui:SetCoreGuiEnabled(coreType, wasEnabled)
		end
		ProximityPromptService.Enabled = promptsWereEnabled
		unlockMovement()
		releaseMusic()
		if realRoot.Parent then
			camera.CFrame = arrivalCamera(realRoot, stand)
		end
		camera.CameraType = Enum.CameraType.Custom
		isPlaying = false
		closeCover()
	end
	finishActive = finish
	runTrove:Connect(humanoid.Died, finish)
	runTrove:Connect(character.AncestryChanged, function()
		if not character:IsDescendantOf(workspace) then
			finish()
		end
	end)

	local cueSounds: { [number]: Sound } = {}
	for index, cue in IntroConfig.Cues do
		local asset = AssetRegistry.get(cue.Key)
		if asset:IsA("Sound") then
			if string.sub(cue.Key, 1, #MUSIC_PREFIX) == MUSIC_PREFIX then
				local group = SoundService:FindFirstChild(MUSIC_GROUP)
				if group and group:IsA("SoundGroup") then
					asset.SoundGroup = group
				end
			end
			asset.Parent = SoundService
			cueSounds[index] = asset
			runTrove:Add(asset)
		else
			asset:Destroy()
		end
	end

	local built = Stage.Build(character)
	if not built then
		finish()
		return
	end
	stage = built
	IntroController.LoadProgressed:Fire("StageBuilt")
	local loadStart = os.clock()
	while not Stage.IsLoaded(built) and os.clock() - loadStart < IntroConfig.LoadTimeoutSeconds do
		if isFinished then
			return
		end
		task.wait(0.05)
	end
	if isFinished then
		return
	end
	if not Stage.IsLoaded(built) then
		warn(`[IntroController] Animations did not load in time: {table.concat(Stage.Unloaded(built), ", ")}`)
		finish()
		return
	end
	IntroController.LoadProgressed:Fire("AnimationsLoaded")
	local isPreloaded = false
	local preloadTargets: { Instance } = { built.Set, built.Master.Model, built.Player.Model, built.Boulder }
	for _, sound in cueSounds do
		table.insert(preloadTargets, sound)
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(preloadTargets)
		isPreloaded = true
	end)
	local preloadStart = os.clock()
	while not isPreloaded and os.clock() - preloadStart < IntroConfig.PreloadTimeoutSeconds do
		if isFinished then
			return
		end
		task.wait(0.05)
	end
	if isFinished then
		return
	end
	IntroController.LoadProgressed:Fire("Preloaded")
	local firstShot = built.Markers.CamDriveFront or built.Markers.CarStop
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(firstShot.Position, built.Car:GetPivot().Position + Vector3.yAxis * 1.5)
	for _ = 1, IntroConfig.WarmupFrames do
		RunService.RenderStepped:Wait()
		if isFinished then
			return
		end
	end
	closeCover()
	stand = standPosition()
	task.spawn(function()
		local found = waitForStand()
		if found then
			stand = found
		end
	end)

	local markers = built.Markers
	local player = built.Player
	local master = built.Master
	local startClock = os.clock()
	local function clock(): number
		return os.clock() - startClock
	end
	local cameraState = Shots.Start(camera, clock)
	shots = cameraState

	local carStart = markers.CarStart
	local carStop = markers.CarStop
	local isSeated = true
	local starsShown = false
	local isBoulderLanded = false
	local splitAt: number? = nil
	local darken: ColorCorrectionEffect? = nil
	local fade: ColorCorrectionEffect? = nil
	local up = Vector3.yAxis
	local engine: Sound? = nil

	local function carPosition(elapsed: number): CFrame
		local alpha = math.clamp(elapsed / IntroConfig.CarDriveSeconds, 0, 1)
		local eased = 1 - (1 - alpha) * (1 - alpha)
		return carStart:Lerp(carStop, eased)
	end

	local function onMarker(track: AnimationTrack, name: string, callback: () -> ())
		runTrove:Connect(track:GetMarkerReachedSignal(name), function()
			if not isFinished then
				callback()
			end
		end)
	end

	local function lookAtFrom(position: Vector3, target: () -> Vector3): Shots.Shot
		return function()
			return CFrame.lookAt(position, target())
		end
	end

	local function carTarget(): Vector3
		return built.Car:GetPivot().Position + up * 1.5
	end

	onMarker(player.Tracks.BoingOut, "Boing", function()
		if engine then
			engine:Stop()
		end
		Stage.Squash(built)
		built.Shadow.Transparency = 1
		Stage.Emit(
			CRASH_KEY,
			built.BoulderRest - Vector3.new(0, built.Boulder.Size.Y / 2, 0),
			EFFECT_LIFETIME_SECONDS
		)
		LocalSound.Play(IntroConfig.Sounds.Crash)
		LocalSound.Play(IntroConfig.Sounds.Break)
		LocalSound.Play(IntroConfig.Sounds.Boing)
		Shots.Shake(cameraState, IntroConfig.CrashShakeStuds, IntroConfig.CrashShakeSeconds)
	end)
	onMarker(player.Tracks.BoingOut, "Touchdown", function()
		LocalSound.Play(IntroConfig.Sounds.Touchdown)
		local head = player.Head
		if head then
			Stage.Emit(
				DUST_KEY,
				CFrame.new(head.Position.X, markers.Boulder.Position.Y, head.Position.Z),
				EFFECT_LIFETIME_SECONDS
			)
		end
	end)
	onMarker(master.Tracks.Leap, "Land", function()
		local ground = master.Root.Position + IntroConfig.LeapRootOffset.Position
		Stage.Emit(
			LAND_KEY,
			CFrame.new(ground.X, markers.Boulder.Position.Y, ground.Z),
			EFFECT_LIFETIME_SECONDS
		)
		LocalSound.Play(IntroConfig.Sounds.Land)
		Shots.Shake(cameraState, IntroConfig.LandShakeStuds, IntroConfig.LandShakeSeconds)
	end)
	onMarker(master.Tracks.Chop, "Impact", function()
		if darken then
			darken:Destroy()
			darken = nil
		end
		Shots.Flash(cameraState)
		Shots.Punch(cameraState)
		Shots.Shake(cameraState, IntroConfig.ImpactShakeStuds, IntroConfig.ImpactShakeSeconds)
		rockController:PlayBreakBurst(built.Boulder, ChopQuality.Master)
		Stage.Split(built, master.Root.CFrame.RightVector)
		splitAt = clock()
		LocalSound.Play(IntroConfig.Sounds.Crash)
		LocalSound.Play(IntroConfig.Sounds.FlyAway)
		task.delay(0.3, function()
			if not isFinished then
				Stage.PopBack(built)
				LocalSound.Play(IntroConfig.Sounds.PopBack)
			end
		end)
	end)

	local events: { Event } = {
		{
			At = 0,
			Run = function()
				Stage.Play(player, "Drive", true)
				local asset = AssetRegistry.get(IntroConfig.Sounds.Drive)
				if asset:IsA("Sound") then
					asset.Looped = true
					asset.Parent = SoundService
					asset:Play()
					engine = asset
					runTrove:Add(asset)
				else
					asset:Destroy()
				end
				local front = markers.CamDriveFront or carStop
				Shots.Set(cameraState, lookAtFrom(front.Position, carTarget))
			end,
		},
		{
			At = IntroConfig.DriveFrontUntil,
			Run = function()
				local side = (markers.CamDriveSide or carStop).Position - carStop.Position
				Shots.Set(cameraState, function()
					local target = carTarget()
					return CFrame.lookAt(target + side, target)
				end)
			end,
		},
		{
			At = IntroConfig.HonkAt,
			Run = function()
				LocalSound.Play(IntroConfig.Sounds.Honk)
			end,
		},
		{
			At = IntroConfig.RumbleAt,
			Run = function()
				LocalSound.Play(IntroConfig.Sounds.Rumble)
				Shots.Shake(
					cameraState,
					IntroConfig.RumbleShakeStuds,
					IntroConfig.BoingAt - IntroConfig.RumbleAt
				)
				local cliff = markers.CamCliff or carStop
				Shots.Set(cameraState, function()
					return CFrame.lookAt(cliff.Position, built.Boulder.Position)
				end)
			end,
		},
		{
			At = IntroConfig.BoulderRollAt,
			Run = function()
				LocalSound.Play(IntroConfig.Sounds.Roll)
			end,
		},
		{
			At = IntroConfig.LookUpAt,
			Run = function()
				Stage.Play(player, "LookUp")
				local sky = markers.CamSky or carStop
				local skyTarget = sky.Position + sky.LookVector * 30
				local tiltStart = clock()
				Shots.Set(cameraState, function(elapsed: number)
					local alpha = Shots.Ease((elapsed - tiltStart) / 1.2)
					local target = carTarget():Lerp(skyTarget, alpha)
					return CFrame.lookAt(sky.Position, target)
				end)
				local shadow = built.Shadow
				local grow = IntroConfig.BoingAt - IntroConfig.LookUpAt
				shadow.Transparency = 0.9
				TweenService
					:Create(shadow, TweenInfo.new(grow, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = Vector3.new(0.1, IntroConfig.ShadowMaxStuds, IntroConfig.ShadowMaxStuds),
						Transparency = 0.45,
					})
					:Play()
			end,
		},
		{
			At = IntroConfig.GulpAt,
			Run = function()
				LocalSound.Play(IntroConfig.Sounds.Gulp)
			end,
		},
		{
			At = IntroConfig.BoingAt,
			Run = function()
				isSeated = false
				built.Car:PivotTo(carStop)
				Stage.SeatPlayer(built)
				Stage.Play(player, "BoingOut")
			end,
		},
		{
			At = IntroConfig.CrashCutAt,
			Run = function()
				local crash = markers.CamCrash or carStop
				Shots.Set(cameraState, function()
					return crash
				end)
			end,
		},
		{
			At = IntroConfig.DazedAt,
			Run = function()
				player.Root.CFrame *= IntroConfig.BoingRootOffset
				Stage.Play(player, "Dazed", true)
				starsShown = true
				LocalSound.Play(IntroConfig.Sounds.Dizzy)
			end,
		},
		{
			At = IntroConfig.TeleportAt,
			Run = function()
				Stage.Play(master, "Idle", true)
				Stage.Teleport(master, true)
				LocalSound.Play(IntroConfig.Sounds.Teleport)
			end,
		},
		{
			At = IntroConfig.HeroCutAt,
			Run = function()
				local hero = markers.CamHero or carStop
				local look = hero.Position + hero.LookVector * 20
				Shots.Set(cameraState, function()
					local body = master.Model:FindFirstChild("LowerTorso")
					local target = if body and body:IsA("BasePart")
						then body.Position
						else master.Root.Position
					look = look:Lerp(target, 0.12)
					return CFrame.lookAt(hero.Position, look)
				end)
			end,
		},
		{
			At = IntroConfig.LeapAt,
			Run = function()
				Stage.Play(master, "Leap")
			end,
		},
		{
			At = IntroConfig.ChopAt,
			Run = function()
				master.Root.CFrame *= IntroConfig.LeapRootOffset
				Stage.Play(master, "Chop")
			end,
		},
		{
			At = IntroConfig.ChopSideAt,
			Run = function()
				rockController:PlayMasterWindUp(built.Boulder, true)
				darken = Shots.Darken(cameraState, 2)
				local root = master.Root
				local side = root.CFrame:VectorToWorldSpace(IntroConfig.ChopSideOffset)
				Shots.Set(cameraState, function()
					return CFrame.lookAt(root.Position + side, root.Position + up * 1.5)
				end)
			end,
		},
		{
			At = IntroConfig.ChopFaceAt,
			Run = function()
				local root = master.Root
				local facing = -root.CFrame.LookVector
				local across = root.CFrame.RightVector
				local panStart = clock()
				Shots.Set(cameraState, function(elapsed: number)
					local head = master.Head
					local focus = if head then head.Position else root.Position + up * 2
					local pan = (Shots.Ease((elapsed - panStart) / 1.2) - 0.5) * 2
					local position = focus + facing * IntroConfig.ChopFaceDistanceStuds + across * pan
					return CFrame.lookAt(position, focus)
				end)
			end,
		},
		{
			At = IntroConfig.ChopWideAt,
			Run = function()
				local wide = markers.CamChopWide or carStop
				Shots.Set(cameraState, function()
					return wide
				end)
			end,
		},
		{
			At = IntroConfig.AweAt,
			Run = function()
				starsShown = false
				Stage.Play(player, "Awe")
			end,
		},
		{
			At = IntroConfig.AweCutAt,
			Run = function()
				Stage.SetVisible(master, false)
				local masterHead = master.Head
				local eye = if masterHead then masterHead.Position else master.Root.Position + up * 1.5
				local function target(): Vector3
					local head = player.Head
					return if head then head.Position else player.Root.Position + up * 1.5
				end
				local offset = target() - eye
				local look = if offset.Magnitude > 0.01 then offset.Unit else master.Root.CFrame.LookVector
				local push = math.min(IntroConfig.PovPushStuds, offset.Magnitude * 0.5)
				local start = eye + look * IntroConfig.PovForwardStuds
				local pushStart = clock()
				Shots.Set(cameraState, function(elapsed: number)
					local alpha =
						Shots.Ease((elapsed - pushStart) / (IntroConfig.PointCutAt - IntroConfig.AweCutAt))
					return CFrame.lookAt(start + look * push * alpha, target())
				end)
			end,
		},
		{
			At = IntroConfig.PointAt,
			Run = function()
				Stage.Play(master, "Point")
			end,
		},
		{
			At = IntroConfig.PointCutAt,
			Run = function()
				Stage.SetVisible(master, true)
				local root = master.Root
				Shots.Set(cameraState, function()
					local head = master.Head
					local focus = if head then head.Position - up * 0.8 else root.Position + up
					return CFrame.lookAt(
						focus + root.CFrame.LookVector * IntroConfig.PointDistanceStuds,
						focus
					)
				end)
			end,
		},
		{
			At = IntroConfig.GoTrainAt,
			Run = function()
				LocalSound.Play(IntroConfig.Sounds.GoTrain)
			end,
		},
		{
			At = IntroConfig.WhooshAt,
			Run = function()
				LocalSound.Play(IntroConfig.Sounds.Teleport)
				Stage.Teleport(master, false)
				fade = Shots.FadeIn(cameraState)
				local from = camera.CFrame
				local root = master.Root
				local direction = (-root.CFrame.RightVector + up * 0.5 - root.CFrame.LookVector * 0.3).Unit
				local whooshStart = clock()
				Shots.Set(cameraState, function(elapsed: number)
					local alpha = math.clamp((elapsed - whooshStart) / IntroConfig.WhooshSeconds, 0, 1)
					local position = from.Position + direction * IntroConfig.WhooshStuds * alpha * alpha
					return CFrame.lookAt(position, position + direction)
				end)
			end,
		},
		{
			At = IntroConfig.ArriveAt,
			Run = function()
				Stage.Destroy(built)
				local look = if stand then flatLook(realRoot.Position, stand) else nil
				if look then
					realRoot.CFrame = CFrame.lookAt(realRoot.Position, realRoot.Position + look)
				end
				local arrival = arrivalCamera(realRoot, stand)
				Shots.Set(cameraState, function()
					return arrival
				end)
				uiController:Close(IntroConfig.LetterboxScreen)
				if fade then
					Shots.FadeOut(fade)
				end
			end,
		},
		{
			At = IntroConfig.EndAt,
			Run = finish,
		},
	}
	for index, cue in IntroConfig.Cues do
		local sound = cueSounds[index]
		if not sound then
			continue
		end
		table.insert(events, {
			At = cue.At,
			Run = function()
				sound.TimePosition = cue.StartSeconds
				sound:Play()
			end,
		})
		table.insert(events, {
			At = cue.Until,
			Run = function()
				if cue.FadeSeconds <= 0 then
					sound:Stop()
					return
				end
				local fadeOut = TweenService:Create(sound, TweenInfo.new(cue.FadeSeconds), { Volume = 0 })
				fadeOut.Completed:Once(function()
					sound:Stop()
				end)
				fadeOut:Play()
			end,
		})
	end
	table.sort(events, function(a: Event, b: Event)
		return a.At < b.At
	end)

	local nextEvent = 1
	runTrove:Connect(RunService.PreAnimation, function()
		if isFinished then
			return
		end
		local elapsed = clock()
		while nextEvent <= #events and events[nextEvent].At <= elapsed do
			local event = events[nextEvent]
			nextEvent += 1
			event.Run()
			if isFinished then
				return
			end
		end
		if isSeated then
			built.Car:PivotTo(carPosition(elapsed))
			Stage.SeatPlayer(built)
		end
		if not isBoulderLanded then
			Stage.PlaceBoulder(built, elapsed)
			isBoulderLanded = elapsed >= IntroConfig.BoingAt + 0.1
		end
		local split = splitAt
		if split then
			Stage.UpdatePieces(built, elapsed - split)
		end
		Stage.UpdateStars(built, starsShown, elapsed)
		for _, actor in { player, master } do
			for _, track in actor.Tracks do
				if track.IsPlaying and not track.Looped and track.Speed > 0 then
					if track.TimePosition >= track.Length - HOLD_MARGIN_SECONDS then
						track:AdjustSpeed(0)
					end
				end
			end
		end
	end)
end

local function begin()
	local dataController = controllers.DataController
	if not dataController:IsLoaded() then
		dataController.Loaded:Wait()
	end
	if not shouldPlay() then
		closeCover()
		return
	end
	local localPlayer = Players.LocalPlayer
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", IntroConfig.LoadTimeoutSeconds)
	local root = character:WaitForChild("HumanoidRootPart", IntroConfig.LoadTimeoutSeconds)
	if not (humanoid and humanoid:IsA("Humanoid") and root and root:IsA("BasePart")) then
		closeCover()
		return
	end
	if not shouldPlay() then
		closeCover()
		return
	end
	play(character, humanoid, root)
end

function IntroController.IsPlaying(_self: any): boolean
	return isPlaying
end

function IntroController.Init(_self: any, registry: { [string]: any })
	controllers = registry
	IntroController.LoadProgressed = Signal.new()
end

function IntroController.Start(_self: any)
	local startTrove = Trove.new()
	trove = startTrove
	startTrove:Add(task.spawn(begin))
end

function IntroController.Destroy(_self: any)
	local finish = finishActive
	if finish then
		finish()
	end
	if trove then
		trove:Destroy()
		trove = nil
	end
	if IntroController.LoadProgressed then
		IntroController.LoadProgressed:Destroy()
		IntroController.LoadProgressed = nil
	end
end

return IntroController
