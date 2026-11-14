--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local BlockRoundConfig = require(ReplicatedStorage.Config.BlockRoundConfig)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossFxConfig = require(ReplicatedStorage.Config.BossFxConfig)
local ChopZones = require(ReplicatedStorage.ChopZones)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PotionConfig = require(ReplicatedStorage.Config.PotionConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local BossHearts = require(script.Parent.Parent.BossHearts)
local BossOverlays = require(script.Parent.Parent.BossOverlays)
local Types = require(script.Parent.Parent.Types)

local ChopBar = {}

local HEALTH_TWEEN_SECONDS = 0.2

local function findFrame(root: Instance, name: string): Frame?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("Frame") then
		return found
	end
	warn(`[ChopBar] Missing Frame "{name}" in {root:GetFullName()}`)
	return nil
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("TextLabel") then
		return found
	end
	warn(`[ChopBar] Missing TextLabel "{name}" in {root:GetFullName()}`)
	return nil
end

local function qualityColor(quality: number): Color3
	return ChopStyleConfig.Qualities[quality].Color
end

type Piece = { Low: number, High: number, Color: Color3 }

local MIN_PIECE = 0.0001
local EDGE = 0.0005

local piecesToSequence: (pieces: { Piece }) -> ColorSequence

local function focusScale(): number
	local endsAt = Players.LocalPlayer:GetAttribute(
		MonetizationConfig.BoostEndsAttributePrefix .. PotionConfig.BoostKey("Focus")
	)
	return if type(endsAt) == "number" then PotionConfig.FocusScale else 1
end

local function bossPerfectScale(target: Instance?): number
	if not target or target:GetAttribute(BossConfig.SpotIndexAttribute) == nil then
		return 1
	end
	local ancestor = target.Parent
	while ancestor and not CollectionService:HasTag(ancestor, BossConfig.Tag) do
		ancestor = ancestor.Parent
	end
	return if ancestor and ancestor:GetAttribute(BossConfig.MadAttribute) == true
		then BossConfig.MadPerfectScale
		else 1
end

local function buildRamp(
	center: number,
	strengthRatio: number,
	isShelled: boolean,
	perfectScale: number
): ColorSequence
	local bands = ChopZones.Bands(center, strengthRatio, ChopZones.IsTouch(Players.LocalPlayer), perfectScale)
	local pieces: { Piece } = {}
	local function addPiece(low: number, high: number, quality: number)
		if high - low > MIN_PIECE then
			local color = if isShelled and quality < ChopQuality.Great
				then BossFxConfig.Signature.ShellColor
				else qualityColor(quality)
			table.insert(pieces, { Low = low, High = high, Color = color })
		end
	end
	for index, band in bands do
		local inner = bands[index - 1]
		if inner then
			addPiece(band.Low, inner.Low, band.Quality)
			addPiece(inner.High, band.High, band.Quality)
		else
			addPiece(band.Low, band.High, band.Quality)
		end
	end
	local outer = bands[#bands]
	addPiece(0, outer.Low, ChopQuality.Bad)
	addPiece(outer.High, 1, ChopQuality.Bad)
	return piecesToSequence(pieces)
end

function piecesToSequence(pieces: { Piece }): ColorSequence
	table.sort(pieces, function(first: Piece, second: Piece)
		return first.Low < second.Low
	end)
	local keypoints: { ColorSequenceKeypoint } = {}
	local lastTime = -1
	local function push(time: number, color: Color3)
		local clamped = math.clamp(time, 0, 1)
		if clamped > lastTime then
			table.insert(keypoints, ColorSequenceKeypoint.new(clamped, color))
			lastTime = clamped
		end
	end
	for index, piece in pieces do
		push(if index == 1 then 0 else piece.Low + EDGE, piece.Color)
		push(if index == #pieces then 1 else piece.High, piece.Color)
	end
	return ColorSequence.new(keypoints)
end

local function buildBlockRamp(center: number, zoneScale: number): ColorSequence
	local band = ChopZones.BlockBand(center, ChopZones.IsTouch(Players.LocalPlayer), zoneScale)
	local pieces: { Piece } = {}
	local function addPiece(low: number, high: number, color: Color3)
		if high - low > MIN_PIECE then
			table.insert(pieces, { Low = low, High = high, Color = color })
		end
	end
	local outside = qualityColor(ChopQuality.Bad)
	local zone = qualityColor(ChopQuality.Great)
	addPiece(0, band.Low, outside)
	addPiece(band.Low, band.PerfectLow, zone)
	addPiece(band.PerfectLow, band.PerfectHigh, qualityColor(ChopQuality.Perfect))
	addPiece(band.PerfectHigh, band.High, zone)
	addPiece(band.High, 1, outside)
	return piecesToSequence(pieces)
end

function ChopBar.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local openTrove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local chopController = context.Controllers.ChopController

	local bar = findFrame(gui, "Bar")
	local fill = if bar then findFrame(bar, "Fill") else nil
	local rampGradientInstance = if fill then fill:FindFirstChild("RampGradient") else nil
	local rampGradient: UIGradient? = if rampGradientInstance and rampGradientInstance:IsA("UIGradient")
		then rampGradientInstance
		else nil
	local resultLabel = findLabel(gui, "ResultLabel")
	local resultStroke = if resultLabel then resultLabel:FindFirstChildWhichIsA("UIStroke") else nil
	local gradientInstance = if resultLabel then resultLabel:FindFirstChild("RainbowGradient") else nil
	local resultGradient: UIGradient? = if gradientInstance and gradientInstance:IsA("UIGradient")
		then gradientInstance
		else nil
	local rainbowColor = if resultGradient
		then resultGradient.Color
		else ColorSequence.new(Color3.new(1, 1, 1))
	local rainbowRotation = if resultGradient then resultGradient.Rotation else 0

	local cursor = if bar then findFrame(bar, "Cursor") else nil
	local cursorStroke = if cursor then cursor:FindFirstChildWhichIsA("UIStroke") else nil
	local cursorTransparency = if cursor then cursor.BackgroundTransparency else 0
	local shieldInstance = if cursor then cursor:FindFirstChild("Shield") else nil
	local shield: ImageLabel? = if shieldInstance and shieldInstance:IsA("ImageLabel")
		then shieldInstance
		else nil
	if cursor and not shield then
		warn(
			`[ChopBar] Missing ImageLabel "Shield" in {cursor:GetFullName()}; Block rounds keep the plain cursor`
		)
	end
	local function setShieldCursor(isShield: boolean)
		if not cursor or not shield then
			return
		end
		shield.Visible = isShield
		cursor.BackgroundTransparency = if isShield then 1 else cursorTransparency
		if cursorStroke then
			cursorStroke.Enabled = not isShield
		end
	end
	local healthBar = findFrame(gui, "HealthBar")
	local healthFillInstance = if healthBar then healthBar:FindFirstChild("HealthFill", true) else nil
	local healthFill: Frame? = if healthFillInstance and healthFillInstance:IsA("Frame")
		then healthFillInstance
		else nil
	if healthBar and not healthFill then
		warn(`[ChopBar] Missing Frame "HealthFill" in {healthBar:GetFullName()}`)
	end
	local healthTextInstance = if healthBar then healthBar:FindFirstChild("HealthText", true) else nil
	local healthText: TextLabel? = if healthTextInstance and healthTextInstance:IsA("TextLabel")
		then healthTextInstance
		else nil
	if healthBar and not healthText then
		warn(`[ChopBar] Missing TextLabel "HealthText" in {healthBar:GetFullName()}; no HP number`)
	end
	local healthTextShadowInstance = if healthBar
		then healthBar:FindFirstChild("HealthTextShadow", true)
		else nil
	local healthTextShadow: TextLabel? = if healthTextShadowInstance
			and healthTextShadowInstance:IsA("TextLabel")
		then healthTextShadowInstance
		else nil
	local timerInstance = gui:FindFirstChild("TimerText", true)
	local timerText: TextLabel? = if timerInstance and timerInstance:IsA("TextLabel")
		then timerInstance
		else nil
	local timerShadowInstance = gui:FindFirstChild("TimerTextShadow", true)
	local timerShadow: TextLabel? = if timerShadowInstance and timerShadowInstance:IsA("TextLabel")
		then timerShadowInstance
		else nil
	local timerColor = if timerText then timerText.TextColor3 else Color3.new(1, 1, 1)
	local function setTimer(seconds: number?)
		if timerText then
			local isFinal = seconds ~= nil and seconds <= EnemyConfig.FinalSeconds
			timerText.TextColor3 = if isFinal then EnemyConfig.TimerWarnColor else timerColor
		end
		for _, label in { timerText, timerShadow } :: { TextLabel? } do
			if label then
				label.Visible = seconds ~= nil
				if seconds then
					label.Text = string.format("%.1fs", seconds)
				end
			end
		end
	end
	local leaveInstance = gui:FindFirstChild("LeaveButton", true)
	local leaveButton: GuiButton? = if leaveInstance and leaveInstance:IsA("GuiButton")
		then leaveInstance
		else nil
	if not leaveButton then
		warn(`[ChopBar] Missing GuiButton "LeaveButton" in {gui:GetFullName()}`)
	end

	local heartsInstance = if bar then bar:FindFirstChild("Hearts") else nil
	local heartsFrame: Frame? = if heartsInstance and heartsInstance:IsA("Frame") then heartsInstance else nil
	if bar and not heartsFrame then
		warn(`[ChopBar] Missing Frame "Hearts" in {bar:GetFullName()}; no boss hearts`)
	end
	local hearts = if heartsFrame then BossHearts.new(heartsFrame) else nil
	if hearts then
		trove:Add(hearts.Destroy)
	end
	local player = Players.LocalPlayer
	local function bossHealth(): number?
		local health = player:GetAttribute(BossConfig.PlayerHealthAttribute)
		return if type(health) == "number" then health else nil
	end
	trove:Connect(player:GetAttributeChangedSignal(BossConfig.PlayerHealthAttribute), function()
		if hearts then
			hearts.Set(bossHealth())
		end
	end)
	if hearts then
		hearts.Set(bossHealth())
	end
	local function showBossParts()
		local target = if chopController then chopController:GetTarget() else nil
		local isBoss = target ~= nil and target:GetAttribute(BossConfig.SpotIndexAttribute) ~= nil
		local parent = if target then target.Parent else nil
		local isDiamond = parent ~= nil and CollectionService:HasTag(parent, DiamondRockConfig.Tag)
		if healthBar then
			healthBar.Visible = not isBoss and not isDiamond
		end
		if heartsFrame then
			heartsFrame.Visible = isBoss and bossHealth() ~= nil
		end
	end

	local crackColor = ColorSequence.new(qualityColor(ChopQuality.Crack))
	local healthTween: Tween? = nil
	local Signatures = BossConfig.Signatures
	local track = if bar then bar:FindFirstChild("Track") else nil
	local iceInstance = if track then track:FindFirstChild("IcePatch") else nil
	local iceTemplate: Frame? = if iceInstance and iceInstance:IsA("Frame") then iceInstance else nil
	if bar and not iceTemplate then
		warn(`[ChopBar] Missing Frame "Track.IcePatch" in {bar:GetFullName()}; Frost shows no ice`)
	end
	local icePatches: { Frame } = {}
	if iceTemplate then
		for index = 1, 2 do
			local patch = iceTemplate:Clone()
			patch.Name = "IcePatch" .. index
			patch.Parent = iceTemplate.Parent
			trove:Add(patch)
			table.insert(icePatches, patch)
		end
	end
	local barPosition = if bar then bar.Position else UDim2.new()
	local shownKind = -1
	local shownCenter = -1
	local shakeUntil = 0
	local overlaysInstance = if bar then bar:FindFirstChild("Overlays") else nil
	local overlays = if bar
			and overlaysInstance
			and overlaysInstance:IsA("Frame")
		then BossOverlays.new(
			overlaysInstance,
			bar.Size.X.Offset - 8,
			bar.Size.Y.Offset - 8,
			function(seconds: number)
				shakeUntil = math.max(shakeUntil, os.clock() + seconds)
			end
		)
		else nil
	if bar and not overlays then
		warn(`[ChopBar] Missing Frame "Overlays" in {bar:GetFullName()}; boss moves show no overlays`)
	end
	if overlays then
		trove:Add(overlays.Destroy)
	end

	local function modifier(): (number, { number })
		if not chopController then
			return Signatures.None, {}
		end
		return chopController:GetModifier()
	end

	local function showModifier(kind: number, values: { number })
		for index, patch in icePatches do
			local low = values[index]
			local width = values[3]
			local isShown = kind == Signatures.Frost and type(low) == "number" and type(width) == "number"
			patch.Visible = isShown
			if isShown then
				patch.Position = UDim2.fromScale(low, 0)
				patch.Size = UDim2.fromScale(width, 1)
			end
		end
	end

	local function applyRamp()
		local canBreak = if chopController then chopController:CanBreakRock() else true
		local kind, values = modifier()
		local center = if chopController then chopController:GetZoneCenter() else 0.5
		shownKind = kind
		shownCenter = center
		showModifier(kind, values)
		local strengthRatio = if chopController then chopController:GetStrengthRatio() else 1
		if overlays then
			overlays.Set(kind, values, center, strengthRatio, ChopZones.IsTouch(Players.LocalPlayer))
		end
		local ramp = if canBreak
			then buildRamp(
				center,
				strengthRatio,
				kind == Signatures.Shell,
				bossPerfectScale(if chopController then chopController:GetTarget() else nil) * focusScale()
			)
			else crackColor
		if fill then
			fill.Size = UDim2.new(1, 0, 1, 0)
			fill.Visible = true
		end
		if rampGradient then
			rampGradient.Color = ramp
		end
	end

	local function setHealth(health: number, maxHealth: number, animate: boolean)
		local text = `{NumberFormat.Compact(math.max(math.ceil(health), 0))} / {NumberFormat.Compact(
			math.ceil(maxHealth)
		)}`
		if healthText then
			healthText.Text = text
		end
		if healthTextShadow then
			healthTextShadow.Text = text
		end
		if not healthFill then
			return
		end
		if healthTween then
			healthTween:Cancel()
			healthTween = nil
		end
		local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
		local size = UDim2.new(ratio, 0, 1, 0)
		if animate then
			local tween =
				TweenService:Create(healthFill, TweenInfo.new(HEALTH_TWEEN_SECONDS), { Size = size })
			healthTween = tween
			tween:Play()
		else
			healthFill.Size = size
		end
	end

	local function setLevel(level: number)
		if not cursor then
			return
		end
		cursor.Position = UDim2.fromScale(math.clamp(level, 0, 1), 0.5)
	end

	local function showBlockText(text: string, style: string)
		if not resultLabel then
			return
		end
		if resultGradient then
			resultGradient.Enabled = false
		end
		resultLabel.Text = text
		Typography.ApplyTextStyle(resultLabel, style)
	end

	local function resetResult()
		if resultLabel then
			resultLabel.Text = ""
		end
		if resultGradient then
			resultGradient.Enabled = false
		end
	end

	local function showResult(quality: number, text: string?)
		if not resultLabel then
			return
		end
		local style = ChopStyleConfig.Qualities[quality] or ChopStyleConfig.Fallback
		resultLabel.Text = text or style.DisplayText
		if style.IsRainbow then
			resultLabel.TextColor3 = Color3.new(1, 1, 1)
			if resultStroke then
				resultStroke.Color = style.Color:Lerp(Color3.new(0, 0, 0), ChopStyleConfig.StrokeDarkenAmount)
			end
			if resultGradient then
				resultGradient.Enabled = true
				resultGradient.Color = rainbowColor
				resultGradient.Rotation = rainbowRotation
			end
		else
			Typography.ApplyTextStyle(resultLabel, ChopStyleConfig.ResultTextStyle)
		end
	end

	if chopController then
		trove:Add(chopController.ResultShown:Connect(function(quality: number)
			local kind = modifier()
			if kind == Signatures.Shell and quality < ChopQuality.Great then
				showResult(quality, BossConfig.Signature.Banners[Signatures.Shell])
			else
				showResult(quality)
			end
		end))
		trove:Add(chopController.HealthChanged:Connect(function(health: number, maxHealth: number)
			setHealth(health, maxHealth, true)
		end))
		trove:Add(chopController.BlockStarted:Connect(function(center: number, zoneScale: number)
			showModifier(Signatures.None, {})
			shownKind = Signatures.None
			if overlays then
				overlays.Set(Signatures.None, {}, center, 1, false)
			end
			if fill then
				fill.Visible = true
			end
			if rampGradient then
				rampGradient.Color = buildBlockRamp(center, zoneScale)
			end
			setLevel(0)
			setShieldCursor(true)
			showBlockText(BlockRoundConfig.WarningText, BlockRoundConfig.WarningTextStyle)
		end))
		trove:Add(chopController.BlockResolved:Connect(function(outcome: number)
			local text = BlockRoundConfig.OutcomeTexts[outcome]
			if not text then
				return
			end
			if outcome == BlockRoundConfig.Outcomes.Perfect then
				showResult(ChopQuality.Perfect, text)
			else
				showBlockText(
					text,
					BlockRoundConfig.OutcomeTextStyles[outcome] or BlockRoundConfig.WarningTextStyle
				)
			end
		end))
		trove:Add(chopController.RoundStarted:Connect(function()
			setShieldCursor(false)
			applyRamp()
			resetResult()
			setLevel(0)
		end))
		if leaveButton then
			trove:Add(leaveButton.Activated:Connect(function()
				chopController:Leave()
			end))
		end
	else
		warn("[ChopBar] ChopController is not registered; the meter will not animate")
	end

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			setShieldCursor(false)
			applyRamp()
			resetResult()
			setLevel(0)
			if chopController then
				setHealth(chopController:GetHealth(), chopController:GetMaxHealth(), false)
				showBossParts()
				openTrove:Add(RunService.RenderStepped:Connect(function()
					setLevel(chopController:GetCursorPosition())
					setTimer(chopController:GetSecondsLeft())
					showBossParts()
					if not chopController:IsBlockRound() and not chopController:IsReleased() then
						local kind = modifier()
						local center = chopController:GetZoneCenter()
						if kind ~= shownKind or center ~= shownCenter then
							if kind == Signatures.Chomp and shownKind == Signatures.Chomp then
								shakeUntil = os.clock() + BossFxConfig.Signature.ChompShakeSeconds
							end
							applyRamp()
						end
					end
					if bar then
						local now = os.clock()
						if now < shakeUntil then
							local pixels = BossFxConfig.Signature.ChompShakePixels
							bar.Position = barPosition
								+ UDim2.fromOffset(
									math.random(-pixels, pixels),
									math.random(-pixels, pixels) // 2
								)
						elseif bar.Position ~= barPosition then
							bar.Position = barPosition
						end
					end
				end))
			end
		end,
		Close = function(_self: Types.Screen)
			openTrove:Clean()
			if overlays then
				overlays.Clear()
			end
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			openTrove:Destroy()
			trove:Destroy()
		end,
	}
end

return ChopBar
