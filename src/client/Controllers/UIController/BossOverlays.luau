--!strict

-- Draws a boss's signature move over the chop bar: ice chunks (Frost), croc jaws (Chomp)
-- and stone slabs (Shell). Pieces are cloned from Bar.Overlays.Templates (authored in Studio).
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossOverlayConfig = require(ReplicatedStorage.Config.BossOverlayConfig)
local BossSoundConfig = require(ReplicatedStorage.Config.BossSoundConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local Trove = require(ReplicatedStorage.Packages.Trove)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)

export type BossOverlays = {
	Set: (kind: number, values: { number }, center: number, strengthRatio: number, isTouch: boolean) -> (),
	Clear: () -> (),
	Destroy: () -> (),
}

type Debris = {
	Image: ImageLabel,
	Position: Vector2,
	Velocity: Vector2,
	Spin: number,
	Age: number,
}

type Jaw = {
	Image: ImageLabel,
	Base: UDim2,
	Direction: number,
}

local Signatures = BossConfig.Signatures
local config = BossOverlayConfig

local BossOverlays = {}

local function find(root: Instance, name: string, class: string): Instance?
	local found = root:FindFirstChild(name)
	if found and found:IsA(class) then
		return found
	end
	return nil
end

local function aspectOf(image: ImageLabel): number
	local aspect = image:GetAttribute(config.AspectAttribute)
	return if type(aspect) == "number" and aspect > 0 then aspect else 1
end

function BossOverlays.new(
	overlays: Frame,
	trackWidth: number,
	trackHeight: number,
	shake: (seconds: number) -> ()
): BossOverlays
	local trove = Trove.new()
	local random = Random.new()
	local templates = overlays:FindFirstChild(config.TemplatesName)
	if not templates then
		warn(`[BossOverlays] Missing "{config.TemplatesName}" in {overlays:GetFullName()}; no move overlays`)
	end
	local frostLayer = find(overlays, "Frost", "Frame") :: Frame?
	local shellLayer = find(overlays, "Shell", "Frame") :: Frame?
	local chompLayer = find(overlays, "Chomp", "Frame") :: Frame?
	local debrisLayer = find(overlays, "Debris", "Frame") :: Frame?
	-- Download every piece now so the first move doesn't pop in blank.
	task.spawn(function()
		local images: { Instance } = {}
		for _, descendant in overlays:GetDescendants() do
			if descendant:IsA("ImageLabel") then
				table.insert(images, descendant)
			end
		end
		local ok, problem = pcall(function()
			ContentProvider:PreloadAsync(images)
		end)
		if not ok then
			warn(`[BossOverlays] Preloading the overlay images failed: {problem}`)
		end
	end)
	local zoneFlash = if chompLayer then find(chompLayer, "ZoneFlash", "Frame") :: Frame? else nil

	local tweens: { [Instance]: Tween } = {}
	local function play(instance: Instance, info: TweenInfo, goals: { [string]: any }): Tween
		local previous = tweens[instance]
		if previous then
			previous:Cancel()
		end
		local tween = TweenService:Create(instance, info, goals)
		tweens[instance] = tween
		tween:Play()
		return tween
	end
	local function stop(instance: Instance)
		local previous = tweens[instance]
		if previous then
			previous:Cancel()
			tweens[instance] = nil
		end
	end
	local function remove(instance: Instance)
		stop(instance)
		for _, descendant in instance:GetDescendants() do
			stop(descendant)
		end
		instance:Destroy()
	end

	local function clone(name: string, parent: Instance?): ImageLabel?
		local template = if templates then templates:FindFirstChild(name) else nil
		if not template or not template:IsA("ImageLabel") or not parent then
			return nil
		end
		local image = template:Clone()
		image.Visible = true
		image.Parent = parent
		return image
	end

	local function popScale(image: ImageLabel, from: number): UIScale
		local scale = Instance.new("UIScale")
		scale.Scale = from
		scale.Parent = image
		return scale
	end

	-- Debris: shards and rubble that fly off, fall and fade.
	local debris: { Debris } = {}
	local function spawnDebris(
		names: { string },
		center: Vector2,
		spread: Vector2,
		count: number,
		size: number
	)
		for _ = 1, count do
			local image = clone(names[random:NextInteger(1, #names)], debrisLayer)
			if image then
				image.ScaleType = Enum.ScaleType.Fit
				image.AnchorPoint = Vector2.new(0.5, 0.5)
				local pixels = size * random:NextNumber(0.7, 1.15)
				image.Size = UDim2.fromOffset(pixels, pixels)
				local offset =
					Vector2.new(random:NextNumber(-1, 1) * spread.X, random:NextNumber(-1, 1) * spread.Y)
				local position = center + offset
				image.Position = UDim2.fromOffset(position.X, position.Y)
				image.Rotation = random:NextNumber(0, 360)
				table.insert(debris, {
					Image = image,
					Position = position,
					Velocity = Vector2.new(
						random:NextNumber(-1, 1) * config.DebrisSpeed.X + offset.X * 2,
						-random:NextNumber(0.3, 1) * config.DebrisSpeed.Y
					),
					Spin = random:NextNumber(-1, 1) * config.DebrisSpin,
					Age = 0,
				})
			end
		end
	end
	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		for index = #debris, 1, -1 do
			local piece = debris[index]
			piece.Age += deltaTime
			if piece.Age >= config.DebrisSeconds or not piece.Image.Parent then
				piece.Image:Destroy()
				table.remove(debris, index)
				continue
			end
			piece.Velocity += Vector2.new(0, config.DebrisGravity * deltaTime)
			piece.Position += piece.Velocity * deltaTime
			piece.Image.Position = UDim2.fromOffset(piece.Position.X, piece.Position.Y)
			piece.Image.Rotation += piece.Spin * deltaTime
			piece.Image.ImageTransparency = (piece.Age / config.DebrisSeconds) ^ 2
		end
	end)

	-- Frost
	local chunks: { [number]: ImageLabel } = {}
	local chunkLows: { [number]: number } = {}
	local function breakChunk(index: number)
		local chunk = chunks[index]
		chunks[index] = nil
		chunkLows[index] = nil
		if not chunk then
			return
		end
		local position =
			Vector2.new(chunk.Position.X.Offset, chunk.Position.Y.Offset + chunk.Size.Y.Offset * 0.3)
		spawnDebris(
			config.IceShards,
			position,
			Vector2.new(chunk.Size.X.Offset * 0.35, trackHeight * 0.3),
			config.IceShardCount,
			config.IceShardPixels
		)
		local tween = play(
			chunk,
			TweenInfo.new(config.IceBreakSeconds),
			{ ImageTransparency = 1, Size = chunk.Size + UDim2.fromOffset(16, 8) }
		)
		tween.Completed:Once(function()
			remove(chunk)
		end)
	end
	local function dropChunk(index: number, low: number, width: number)
		local name = config.IceChunks[(index - 1) % #config.IceChunks + 1]
		local chunk = clone(name, frostLayer)
		if not chunk then
			return
		end
		local pixels = width * trackWidth * config.IceWidthScale
		chunk.AnchorPoint = Vector2.new(0.5, 0)
		chunk.Size = UDim2.fromOffset(pixels, pixels * aspectOf(chunk))
		chunk.Position = UDim2.fromOffset((low + width / 2) * trackWidth, config.IceTopPixels)
		chunk.ImageTransparency = 1
		local scale = popScale(chunk, config.IceDropScale)
		chunks[index] = chunk
		chunkLows[index] = low
		play(chunk, TweenInfo.new(config.IceDropSeconds * 0.5), { ImageTransparency = 0 })
		play(
			scale,
			TweenInfo.new(config.IceDropSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 1 }
		).Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				shake(config.LandShakeSeconds)
			end
		end)
	end
	local function setFrost(values: { number })
		local width = values[3]
		for index = 1, 2 do
			local low = values[index]
			if type(low) ~= "number" or type(width) ~= "number" or width <= 0 then
				breakChunk(index)
			elseif chunkLows[index] ~= low then
				breakChunk(index)
				dropChunk(index, low, width)
			end
		end
	end
	local function clearFrost(animate: boolean)
		for index in chunks do
			if animate then
				breakChunk(index)
			else
				local chunk = chunks[index]
				remove(chunk)
				chunks[index] = nil
				chunkLows[index] = nil
			end
		end
	end

	-- Chomp
	local jaws: { Jaw } = {}
	if chompLayer then
		local entries: { { Name: string, Direction: number } } = {
			{ Name = "UpperJaw", Direction = -1 },
			{ Name = "LowerJaw", Direction = 1 },
		}
		for _, entry in entries do
			local image = find(chompLayer, entry.Name, "ImageLabel") :: ImageLabel?
			if image then
				image.Visible = false
				table.insert(jaws, { Image = image, Base = image.Position, Direction = entry.Direction })
			else
				warn(`[BossOverlays] Missing ImageLabel "{entry.Name}" in {chompLayer:GetFullName()}`)
			end
		end
	end
	local jawsOpen = false
	local function showJaws()
		jawsOpen = true
		for _, jaw in jaws do
			jaw.Image.Visible = true
			jaw.Image.ImageTransparency = 1
			jaw.Image.Position = jaw.Base + UDim2.fromOffset(0, jaw.Direction * config.JawStartPixels)
			play(
				jaw.Image,
				TweenInfo.new(config.JawInSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{
					Position = jaw.Base,
					ImageTransparency = 0,
				}
			)
		end
		task.delay(config.JawInSeconds * config.JawLandFraction, function()
			if jawsOpen then
				shake(config.LandShakeSeconds)
			end
		end)
	end
	local function hideJaws(animate: boolean)
		jawsOpen = false
		for _, jaw in jaws do
			if animate and jaw.Image.Visible then
				play(
					jaw.Image,
					TweenInfo.new(config.JawOutSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Position = jaw.Base + UDim2.fromOffset(0, jaw.Direction * config.JawStartPixels),
						ImageTransparency = 1,
					}
				).Completed:Once(function(state: Enum.PlaybackState)
					if state == Enum.PlaybackState.Completed then
						jaw.Image.Visible = false
					end
				end)
			else
				stop(jaw.Image)
				jaw.Image.Visible = false
			end
		end
	end
	local function zoneWidth(center: number, strengthRatio: number, isTouch: boolean): number
		local bands = ChopZones.Bands(center, strengthRatio, isTouch)
		local outer = bands[#bands]
		return if outer then outer.High - outer.Low else 0.1
	end
	local function chomp(oldCenter: number, newCenter: number, strengthRatio: number, isTouch: boolean)
		LocalSound.Play(BossSoundConfig.Chomp)
		for _, jaw in jaws do
			local closed = jaw.Base - UDim2.fromOffset(0, jaw.Direction * config.ChompPixels)
			play(
				jaw.Image,
				TweenInfo.new(config.ChompCloseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = closed,
					ImageTransparency = 0,
				}
			).Completed:Once(function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed and jawsOpen then
					play(
						jaw.Image,
						TweenInfo.new(
							config.ChompOpenSeconds,
							Enum.EasingStyle.Back,
							Enum.EasingDirection.Out
						),
						{ Position = jaw.Base }
					)
				end
			end)
		end
		local oldX = oldCenter * trackWidth
		local bite = clone(config.BiteMarkName, chompLayer)
		if bite then
			local height = trackHeight * config.BiteMarkHeightScale
			bite.AnchorPoint = Vector2.new(0.5, 0.5)
			bite.Size = UDim2.fromOffset(height / aspectOf(bite), height)
			bite.Position = UDim2.fromOffset(oldX, trackHeight / 2)
			local scale = popScale(bite, 0.6)
			play(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			play(
				bite,
				TweenInfo.new(
					config.BiteMarkSeconds * 0.4,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In,
					0,
					false,
					config.BiteMarkSeconds * 0.6
				),
				{ ImageTransparency = 1 }
			).Completed:Once(function()
				remove(bite)
			end)
		end
		local burst = clone(config.ChompBurstName, debrisLayer)
		if burst then
			burst.ScaleType = Enum.ScaleType.Fit
			burst.AnchorPoint = Vector2.new(0.5, 0.5)
			burst.Size = UDim2.fromOffset(config.ChompBurstPixels, config.ChompBurstPixels)
			burst.Position = UDim2.fromOffset(oldX, trackHeight / 2)
			local scale = popScale(burst, 0.4)
			play(
				scale,
				TweenInfo.new(config.ChompBurstSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Scale = 1.2 }
			)
			play(
				burst,
				TweenInfo.new(config.ChompBurstSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					ImageTransparency = 1,
				}
			).Completed:Once(function()
				remove(burst)
			end)
		end
		if zoneFlash then
			zoneFlash.Position = UDim2.fromScale(newCenter, 0.5)
			zoneFlash.Size = UDim2.fromScale(zoneWidth(newCenter, strengthRatio, isTouch), 1)
			zoneFlash.BackgroundTransparency = config.ZoneFlashTransparency
			play(zoneFlash, TweenInfo.new(config.ZoneFlashSeconds), { BackgroundTransparency = 1 })
		end
	end

	-- Shell
	local slabs: { ImageLabel } = {}
	local shellCenter: number? = nil
	local function crumbleSlabs(animate: boolean)
		for _, slab in slabs do
			if animate then
				local position =
					Vector2.new(slab.Position.X.Offset + slab.Size.X.Offset / 2, slab.Position.Y.Offset)
				spawnDebris(
					config.StoneRubble,
					position,
					Vector2.new(slab.Size.X.Offset * 0.35, trackHeight * 0.25),
					config.RubblePerSlab,
					config.RubblePixels
				)
				play(slab, TweenInfo.new(config.SlabSinkSeconds), {
					ImageTransparency = 1,
					Position = slab.Position + UDim2.fromOffset(0, 16),
				}).Completed:Once(function()
					remove(slab)
				end)
			else
				remove(slab)
			end
		end
		table.clear(slabs)
		shellCenter = nil
	end
	local function slabWidths(height: number): { [string]: number }
		local widths: { [string]: number } = {}
		for _, name in config.StoneSlabs do
			local template = if templates then templates:FindFirstChild(name) else nil
			if template and template:IsA("ImageLabel") then
				widths[name] = height / aspectOf(template)
			end
		end
		return widths
	end
	local function fillRegion(low: number, high: number, height: number, delayIndex: number): number
		local widths = slabWidths(height)
		local names: { string } = {}
		for name in widths do
			table.insert(names, name)
		end
		table.sort(names, function(first: string, second: string)
			return widths[first] < widths[second]
		end)
		if #names == 0 or high - low < config.SlabMinPixels then
			return delayIndex
		end
		local widest = widths[names[#names]]
		local x = low
		while high - x > 1 do
			local remaining = high - x
			local name: string
			local width: number
			if remaining <= widest * 1.3 then
				name = names[1]
				for _, candidate in names do
					if math.abs(widths[candidate] - remaining) < math.abs(widths[name] - remaining) then
						name = candidate
					end
				end
				width = remaining
			else
				name = names[random:NextInteger(1, #names)]
				width = math.min(widths[name], remaining - config.SlabMinPixels)
			end
			local slab = clone(name, shellLayer)
			if not slab then
				break
			end
			local overlap = config.SlabOverlapPixels
			local landed = UDim2.fromOffset(x - overlap / 2, trackHeight / 2)
			slab.AnchorPoint = Vector2.new(0, 0.5)
			slab.Size = UDim2.fromOffset(width + overlap, height)
			slab.Position = landed - UDim2.fromOffset(0, config.SlabDropPixels)
			slab.ImageTransparency = 1
			local info = TweenInfo.new(
				config.SlabDropSeconds,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				delayIndex * config.SlabStaggerSeconds
			)
			play(slab, info, { Position = landed, ImageTransparency = 0 }).Completed:Once(
				function(state: Enum.PlaybackState)
					if state == Enum.PlaybackState.Completed then
						shake(config.LandShakeSeconds)
					end
				end
			)
			table.insert(slabs, slab)
			delayIndex += 1
			x += width
		end
		return delayIndex
	end
	local function setShell(center: number, strengthRatio: number, isTouch: boolean)
		if shellCenter == center then
			return
		end
		crumbleSlabs(shellCenter ~= nil)
		shellCenter = center
		local great: ChopZones.Band? = nil
		for _, band in ChopZones.Bands(center, strengthRatio, isTouch) do
			if band.Quality == ChopQuality.Great then
				great = band
			end
		end
		if not great then
			return
		end
		local height = trackHeight * config.SlabHeightScale
		local edge = config.SlabOverlapPixels
		local index = fillRegion(-edge, great.Low * trackWidth, height, 0)
		fillRegion(great.High * trackWidth, trackWidth + edge, height, index)
	end

	local currentKind = Signatures.None
	local lastCenter: number? = nil

	local function exit(kind: number, animate: boolean)
		if kind == Signatures.Frost then
			clearFrost(animate)
		elseif kind == Signatures.Chomp then
			hideJaws(animate)
		elseif kind == Signatures.Shell then
			crumbleSlabs(animate)
		end
	end

	local function set(
		kind: number,
		values: { number },
		center: number,
		strengthRatio: number,
		isTouch: boolean
	)
		if kind ~= currentKind then
			exit(currentKind, true)
			currentKind = kind
			lastCenter = center
			if kind == Signatures.Chomp then
				showJaws()
			elseif kind == Signatures.Frost then
				LocalSound.Play(BossSoundConfig.Frost)
			elseif kind == Signatures.Shell then
				LocalSound.Play(BossSoundConfig.ShellHide)
			end
		end
		if kind == Signatures.Frost then
			setFrost(values)
		elseif kind == Signatures.Shell then
			setShell(center, strengthRatio, isTouch)
		elseif kind == Signatures.Chomp and lastCenter ~= center then
			chomp(lastCenter or center, center, strengthRatio, isTouch)
		end
		lastCenter = center
	end

	local function clear()
		exit(Signatures.Frost, false)
		exit(Signatures.Chomp, false)
		exit(Signatures.Shell, false)
		currentKind = Signatures.None
		lastCenter = nil
		for _, piece in debris do
			piece.Image:Destroy()
		end
		table.clear(debris)
		if zoneFlash then
			stop(zoneFlash)
			zoneFlash.BackgroundTransparency = 1
		end
	end
	clear()

	return {
		Set = set,
		Clear = clear,
		Destroy = function()
			clear()
			trove:Destroy()
		end,
	}
end

return BossOverlays
