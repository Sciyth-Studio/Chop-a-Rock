--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Input = require(ReplicatedStorage.Packages.Input)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Packets = require(ReplicatedStorage.Packets)
local TrainingMinigameConfig = require(ReplicatedStorage.Config.TrainingMinigameConfig)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)
local Pieces = require(script.Pieces)
local Swipe = require(script.Swipe)

local TrainingMinigame = {}

local function findGui(root: Instance?, name: string): GuiObject?
	if not root then
		return nil
	end
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("GuiObject") then
		return found
	end
	warn(`[TrainingMinigame] missing GuiObject {name} in {root:GetFullName()}`)
	return nil
end

local function findButton(root: GuiObject?): GuiButton?
	if not root then
		return nil
	end
	if root:IsA("GuiButton") then
		return root
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("GuiButton") then
			return descendant
		end
	end
	return nil
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("TextLabel") then
		return found
	end
	warn(`[TrainingMinigame] missing TextLabel {name} in {root:GetFullName()}`)
	return nil
end

function TrainingMinigame.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local templates = gui:FindFirstChild("Templates")
	local playfield = findGui(gui, "Playfield")
	local boardTemplate = findGui(templates, "Board")
	local bombTemplate = findGui(templates, "Bomb")
	local trailTemplate = findGui(templates, "Trail")
	local flash = findGui(gui, "Flash")
	local panel = findGui(gui, "Panel")
	local panelScale = if panel then panel:FindFirstChild("ScreenScale") else nil
	local arena = findGui(panel, "Arena")
	local meter = findGui(gui, "Meter")
	local fill = findGui(meter, "Fill")
	local multiplierLabel = findLabel(gui, "Multiplier")
	local scoreLabel = findLabel(gui, "Score")
	local bestLabel = findLabel(gui, "Best")
	local tip = findLabel(gui, "Tip")
	local closeRoot = findGui(gui, "CloseButton")
	local closeButton = findButton(closeRoot)
	local playRoot = findGui(gui, "PlayButton")
	local playButton = findButton(playRoot)

	local isOpen = false
	local isPlaying = false
	local isRequesting = false
	local isGamepad = false
	local isTouch = false
	local hasSliced = false
	local flashClock = -math.huge
	local savedTouchControls: boolean? = nil
	local mouseLast: Vector2? = nil
	local touchLast: { [InputObject]: Vector2 } = {}
	local pieces: { [number]: Pieces.Piece } = {}
	local halves: { Pieces.Half } = {}
	local trails: { Swipe.Trail } = {}
	local swipeDistance = 0
	local lastSwipeSoundClock = -math.huge
	local fuse: Sound? = nil
	local roundTrove = trove:Extend()

	local canPlay = playfield ~= nil and boardTemplate ~= nil and bombTemplate ~= nil

	local function layout()
		if panel then
			local scale = if panelScale
					and panelScale:IsA("UIScale")
					and panelScale.Scale > 0
				then panelScale.Scale
				else 1
			local topInset = GuiService:GetGuiInset().Y
			panel.Position = UDim2.new(0.5, 0, 0.5, topInset / 2)
			panel.Size = UDim2.fromOffset(
				gui.AbsoluteSize.X * TrainingMinigameConfig.PanelScreenWidth / scale,
				(gui.AbsoluteSize.Y - topInset) * TrainingMinigameConfig.PanelScreenHeight / scale
			)
		end
		if playfield and arena then
			local offset = arena.AbsolutePosition - gui.AbsolutePosition
			playfield.Position = UDim2.fromOffset(offset.X, offset.Y)
			playfield.Size = UDim2.fromOffset(arena.AbsoluteSize.X, arena.AbsoluteSize.Y)
		end
	end

	local function refreshVisibility()
		if playRoot then
			playRoot.Visible = isOpen and canPlay and not isPlaying and not isGamepad
		end
		for _, element in { panel, playfield, flash } do
			if element then
				element.Visible = isPlaying
			end
		end
		if tip then
			tip.Text = if isTouch then TrainingMinigameConfig.TipTouch else TrainingMinigameConfig.TipMouse
			tip.Visible = isPlaying and not hasSliced
		end
	end

	local function setPower(power: number, multiplier: number, score: number)
		if fill then
			fill.Size = UDim2.fromScale(math.clamp(power, 0, 1), 1)
		end
		if multiplierLabel then
			multiplierLabel.Text = string.format(TrainingMinigameConfig.MultiplierFormat, multiplier)
		end
		if scoreLabel then
			scoreLabel.Text = string.format(TrainingMinigameConfig.ScoreFormat, score)
		end
	end

	local function clearRound()
		roundTrove:Clean()
		for _, piece in pieces do
			piece.Gui:Destroy()
		end
		table.clear(pieces)
		for _, half in halves do
			half.Gui:Destroy()
		end
		table.clear(halves)
		for _, trail in trails do
			trail.Gui:Destroy()
		end
		table.clear(trails)
		fuse = nil
		swipeDistance = 0
		mouseLast = nil
		table.clear(touchLast)
		if savedTouchControls ~= nil then
			GuiService.TouchControlsEnabled = savedTouchControls
			savedTouchControls = nil
		end
	end

	local function stopPlaying(shouldTellServer: boolean)
		if not isPlaying then
			return
		end
		isPlaying = false
		clearRound()
		setPower(0, 1, 0)
		if shouldTellServer then
			Packets.TrainingMinigameClose:Fire()
		end
		refreshVisibility()
	end

	local function pieceColor(): Color3
		local tier = context.Controllers.DataController:Get({ "TrainingTier" })
		local key = TrainingStands.Get(tier).Key
		return TrainingMinigameConfig.PieceColors[key] or TrainingMinigameConfig.DefaultPieceColor
	end

	local function toPlayfield(position: Vector3): Vector2
		local inset = GuiService:GetGuiInset()
		local origin = if playfield then playfield.AbsolutePosition else Vector2.zero
		return Vector2.new(position.X + inset.X, position.Y + inset.Y) - origin
	end

	local function slice(piece: Pieces.Piece)
		pieces[piece.Id] = nil
		Packets.TrainingMinigameSlice:Fire(piece.Id)
		if piece.Kind == TrainingMinigameConfig.BombKind then
			LocalSound.Play(TrainingMinigameConfig.BombSound)
			flashClock = os.clock()
		elseif playfield then
			LocalSound.Play(TrainingMinigameConfig.SliceSound)
			for _, half in Pieces.Split(piece, playfield) do
				table.insert(halves, half)
			end
		end
		piece.Gui:Destroy()
		if not hasSliced then
			hasSliced = true
			refreshVisibility()
		end
	end

	local function playSwipeSound(distance: number)
		swipeDistance += distance
		local now = os.clock()
		if
			swipeDistance < TrainingMinigameConfig.SwipeSoundPixels
			or now - lastSwipeSoundClock < TrainingMinigameConfig.SwipeSoundCooldownSeconds
		then
			return
		end
		swipeDistance = 0
		lastSwipeSoundClock = now
		local sounds = TrainingMinigameConfig.SwipeSounds
		if #sounds > 0 then
			LocalSound.Play(sounds[math.random(1, #sounds)])
		end
	end

	local function swipe(from: Vector2, to: Vector2): boolean
		local distance = (to - from).Magnitude
		if distance < TrainingMinigameConfig.MinSwipePixels or not playfield then
			return false
		end
		playSwipeSound(distance)
		if trailTemplate then
			table.insert(trails, Swipe.CreateTrail(trailTemplate, playfield, from, to))
		end
		for _, piece in pieces do
			if piece.IsFlying and Swipe.DistanceToSegment(piece.Center, from, to) <= piece.Radius then
				slice(piece)
			end
		end
		return true
	end

	local function step(dt: number)
		if not playfield then
			return
		end
		layout()
		local now = os.clock()
		local area = playfield.AbsoluteSize
		local hasBomb = false
		for id, piece in pieces do
			local wasFlying = piece.IsFlying
			if not Pieces.Update(piece, now, area) then
				piece.Gui:Destroy()
				pieces[id] = nil
				continue
			end
			local isBomb = piece.Kind == TrainingMinigameConfig.BombKind
			if piece.IsFlying and not wasFlying then
				LocalSound.Play(
					if isBomb
						then TrainingMinigameConfig.ThrowBombSound
						else TrainingMinigameConfig.ThrowBoardSound
				)
			end
			hasBomb = hasBomb or (isBomb and piece.IsFlying)
		end
		local fuseSound = fuse
		if fuseSound then
			if hasBomb and not fuseSound.IsPlaying then
				fuseSound:Play()
			elseif not hasBomb and fuseSound.IsPlaying then
				fuseSound:Stop()
			end
		end
		for index = #halves, 1, -1 do
			if not Pieces.UpdateHalf(halves[index], dt) then
				halves[index].Gui:Destroy()
				table.remove(halves, index)
			end
		end
		for index = #trails, 1, -1 do
			if not Swipe.UpdateTrail(trails[index], dt) then
				trails[index].Gui:Destroy()
				table.remove(trails, index)
			end
		end
		if flash then
			local progress = (now - flashClock) / TrainingMinigameConfig.FlashSeconds
			flash.BackgroundTransparency = if progress < 1 then 0.4 + 0.6 * progress else 1
		end
	end

	local function bindRound()
		local fuseAsset = AssetRegistry.get(TrainingMinigameConfig.FuseSound)
		if fuseAsset:IsA("Sound") then
			fuseAsset.Looped = true
			fuseAsset.Parent = SoundService
			fuse = fuseAsset
		end
		roundTrove:Add(fuseAsset)
		roundTrove:Connect(RunService.RenderStepped, step)
		roundTrove:Connect(UserInputService.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseLast = toPlayfield(input.Position)
			elseif input.UserInputType == Enum.UserInputType.Touch then
				touchLast[input] = toPlayfield(input.Position)
			end
		end)
		roundTrove:Connect(UserInputService.InputChanged, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local last = mouseLast
				local position = toPlayfield(input.Position)
				if last and swipe(last, position) then
					mouseLast = position
				end
			elseif input.UserInputType == Enum.UserInputType.Touch then
				local last = touchLast[input]
				local position = toPlayfield(input.Position)
				if last and swipe(last, position) then
					touchLast[input] = position
				end
			end
		end)
		roundTrove:Connect(UserInputService.InputEnded, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseLast = nil
				swipeDistance = 0
			elseif input.UserInputType == Enum.UserInputType.Touch then
				touchLast[input] = nil
				swipeDistance = 0
			end
		end)
	end

	local function startPlaying()
		if isPlaying or not isOpen or isRequesting or not canPlay then
			return
		end
		isRequesting = true
		task.spawn(function()
			local accepted = Packets.TrainingMinigameOpen:Fire()
			isRequesting = false
			if accepted ~= true or not isOpen or isPlaying then
				return
			end
			isPlaying = true
			hasSliced = false
			savedTouchControls = GuiService.TouchControlsEnabled
			GuiService.TouchControlsEnabled = false
			layout()
			bindRound()
			refreshVisibility()
		end)
	end

	trove:Add(
		Packets.TrainingMinigameWave.OnClientEvent:Connect(
			function(
				ids: { number },
				kinds: { number },
				delays: { number },
				startXs: { number },
				drifts: { number },
				apexes: { number }
			)
				if not isPlaying or not playfield or not boardTemplate or not bombTemplate then
					return
				end
				local now = os.clock()
				local color = pieceColor()
				for index, id in ids do
					local kind = kinds[index]
					local template = if kind == TrainingMinigameConfig.BombKind
						then bombTemplate
						else boardTemplate
					local existing = pieces[id]
					if existing then
						existing.Gui:Destroy()
					end
					pieces[id] = Pieces.Create(
						template,
						playfield,
						id,
						kind,
						color,
						now + (delays[index] or 0),
						startXs[index] or 0.5,
						drifts[index] or 0,
						apexes[index] or TrainingMinigameConfig.MinApexHeight
					)
				end
			end
		)
	)

	trove:Add(
		Packets.TrainingMinigamePower.OnClientEvent:Connect(
			function(power: number, multiplier: number, score: number)
				setPower(power, multiplier, score)
			end
		)
	)

	if playButton then
		trove:Connect(playButton.Activated, startPlaying)
	end
	if closeButton then
		trove:Connect(closeButton.Activated, function()
			stopPlaying(true)
		end)
	end

	trove:Add(context.Controllers.DataController:Observe({ "TrainingMinigameBest" }, function(best: any)
		if bestLabel then
			bestLabel.Text =
				string.format(TrainingMinigameConfig.BestFormat, if type(best) == "number" then best else 0)
		end
	end))

	trove:Add(Input.PreferredInput.observe(function(preferred: Enum.PreferredInput)
		isGamepad = preferred == Enum.PreferredInput.Gamepad
		isTouch = preferred == Enum.PreferredInput.Touch
		refreshVisibility()
		return nil
	end))

	setPower(0, 1, 0)
	refreshVisibility()

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			gui.Enabled = true
			refreshVisibility()
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			stopPlaying(true)
			gui.Enabled = false
			refreshVisibility()
		end,
		Destroy = function(_self: Types.Screen)
			isOpen = false
			isPlaying = false
			clearRound()
			trove:Destroy()
		end,
	}
end

return TrainingMinigame
