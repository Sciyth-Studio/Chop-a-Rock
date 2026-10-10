--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local GuideConfig = require(ReplicatedStorage.Config.GuideConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RushRockConfig = require(ReplicatedStorage.Config.RushRockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TweenService = game:GetService("TweenService")

type TroveInstance = typeof(Trove.new())
type Arrow = { Part: BasePart, SetTransparency: (number) -> () }

local SHOP_TAG = "ShopKiosk"
local ROCK_TAG = "ChopRock"

local ArrowTrail = {}

local function readData(dataController: any, key: string): number
	local value = dataController:Get({ key })
	return if type(value) == "number" then value else 0
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function bestBreakable(strength: number): (string?, RockConfig.Rock?)
	local bestKey: string? = nil
	local best: RockConfig.Rock? = nil
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for key, rock in rocks do
		if
			rock.StrengthRequired <= strength
			and (not best or rock.StrengthRequired > best.StrengthRequired)
		then
			bestKey = key
			best = rock
		end
	end
	return bestKey, best
end

local function requirementOf(part: BasePart): number?
	local key = part:GetAttribute("RockKey")
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local rock = if type(key) == "string" then rocks[key] else nil
	return if rock then rock.StrengthRequired else nil
end

local function nearestRock(position: Vector3, accepts: (BasePart, number) -> boolean): BasePart?
	local nearest: BasePart? = nil
	local nearestDistance = math.huge
	for _, tagged in CollectionService:GetTagged(ROCK_TAG) do
		if not tagged:IsA("BasePart") then
			continue
		end
		local requirement = requirementOf(tagged)
		if not requirement or not accepts(tagged, requirement) then
			continue
		end
		local distance = flatDistance(position, tagged.Position)
		if distance < nearestDistance then
			nearest = tagged
			nearestDistance = distance
		end
	end
	return nearest
end

local function findDiamond(strength: number): BasePart?
	for _, tagged in CollectionService:GetTagged(DiamondRockConfig.Tag) do
		local part = if tagged:IsA("Model") then tagged.PrimaryPart else nil
		if not part then
			continue
		end
		local required = part:GetAttribute(DiamondRockConfig.StrengthAttribute)
		local health = part:GetAttribute(DiamondRockConfig.HealthAttribute)
		local endsAt = part:GetAttribute(DiamondRockConfig.EndsAtAttribute)
		if
			type(required) == "number"
			and strength >= required
			and type(health) == "number"
			and health > 0
			and type(endsAt) == "number"
			and endsAt > workspace:GetServerTimeNow()
		then
			return part
		end
	end
	return nil
end

local function isNearWorseRock(position: Vector3, best: RockConfig.Rock): boolean
	local worse = nearestRock(position, function(_part: BasePart, requirement: number): boolean
		return requirement < best.StrengthRequired
	end)
	return worse ~= nil and flatDistance(position, worse.Position) <= GuideConfig.GrindDistance
end

local function isReadyToUpgrade(dataController: any): boolean
	local nextTier = ArmConfig.Tiers[math.max(1, readData(dataController, "ArmTier")) + 1]
	return nextTier ~= nil and readData(dataController, "Cash") >= nextTier.Price
end

local function findShopPosition(): Vector3?
	for _, tagged in CollectionService:GetTagged(SHOP_TAG) do
		if tagged:IsA("BasePart") then
			return tagged.Position
		end
		if tagged:IsA("Model") then
			local anchor = tagged.PrimaryPart or tagged:FindFirstChild(SHOP_TAG)
			if anchor and anchor:IsA("BasePart") then
				return anchor.Position
			end
			return tagged:GetPivot().Position
		end
	end
	return nil
end

local function makeArrow(): Arrow
	local part = Instance.new("Part")
	part.Name = "GuideArrow"
	part.Size = GuideConfig.ArrowSize
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false

	local image = AssetRegistry.get(GuideConfig.ArrowImageKey)
	if image:IsA("Decal") and image.Texture ~= "" then
		part.Transparency = 1
		image.Face = Enum.NormalId.Top
		image.Parent = part
		return {
			Part = part,
			SetTransparency = function(value: number)
				image.Transparency = value
			end,
		}
	end
	image:Destroy()
	part.Material = Enum.Material.Neon
	part.Color = GuideConfig.ArrowFallbackColor
	return {
		Part = part,
		SetTransparency = function(value: number)
			part.Transparency = value
		end,
	}
end

function ArrowTrail.Start(trove: TroveInstance, dataController: any)
	local arrows: { Arrow } = {}
	local isGuidingRock = false
	local isShopDismissed = false
	local guidedPart: BasePart? = nil
	local highlight: Highlight? = nil
	local highlightPart: BasePart? = nil

	local function clear()
		for _, arrow in arrows do
			arrow.Part:Destroy()
		end
		table.clear(arrows)
	end
	trove:Add(clear)

	local function fadeOutHighlight()
		local current = highlight
		if not current then
			return
		end
		highlight = nil
		highlightPart = nil
		local info =
			TweenInfo.new(GuideConfig.HighlightFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(current, info, { FillTransparency = 1, OutlineTransparency = 1 })
		tween.Completed:Once(function()
			current:Destroy()
		end)
		tween:Play()
	end

	local function setHighlight(part: BasePart?)
		if part == highlightPart and (not part or (highlight and highlight.Parent)) then
			return
		end
		fadeOutHighlight()
		if not part then
			return
		end
		local created = Instance.new("Highlight")
		created.Name = "GuideHighlight"
		created.FillColor = GuideConfig.HighlightColor
		created.OutlineColor = GuideConfig.HighlightColor
		created.FillTransparency = 1
		created.OutlineTransparency = 1
		created.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		created.Adornee = part
		created.Parent = part
		local info =
			TweenInfo.new(GuideConfig.HighlightFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(created, info, {
			FillTransparency = GuideConfig.HighlightFillTransparency,
			OutlineTransparency = GuideConfig.HighlightOutlineTransparency,
		}):Play()
		highlight = created
		highlightPart = part
	end
	trove:Add(function()
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
	end)

	local function ensureArrows()
		if #arrows > 0 then
			return
		end
		for _ = 1, GuideConfig.ArrowCount do
			local arrow = makeArrow()
			arrow.Part.Parent = workspace
			table.insert(arrows, arrow)
		end
	end

	local function chooseTarget(position: Vector3): Vector3?
		guidedPart = nil
		local rushPart = nearestRock(position, function(part: BasePart, _requirement: number): boolean
			return part:GetAttribute(RushRockConfig.EndsAtAttribute) ~= nil
		end)
		if rushPart and flatDistance(position, rushPart.Position) > GuideConfig.ArrivalDistance then
			isGuidingRock = false
			return rushPart.Position
		end
		local diamondPart = findDiamond(readData(dataController, "Strength"))
		if
			diamondPart
			and flatDistance(position, diamondPart.Position)
				> GuideConfig.ArrivalDistance + math.max(diamondPart.Size.X, diamondPart.Size.Z) / 2
		then
			isGuidingRock = false
			return diamondPart.Position
		end
		local isReady = isReadyToUpgrade(dataController)
		if not isReady then
			isShopDismissed = false
		end
		local shopPosition = if isReady and not isShopDismissed then findShopPosition() else nil
		if shopPosition then
			if flatDistance(position, shopPosition) <= GuideConfig.ShopArrivalDistance then
				isShopDismissed = true
			else
				isGuidingRock = false
				return shopPosition
			end
		end
		local strength = readData(dataController, "Strength")
		local bestKey, best = bestBreakable(strength)
		local targetPart = if bestKey
			then nearestRock(position, function(part: BasePart, _requirement: number): boolean
				return part:GetAttribute("RockKey") == bestKey
			end)
			else nil
		targetPart = targetPart
			or nearestRock(position, function(_part: BasePart, requirement: number): boolean
				return requirement <= strength
			end)
		if not best or not targetPart then
			isGuidingRock = false
			return nil
		end
		local target = targetPart.Position
		if isGuidingRock then
			if flatDistance(position, target) <= GuideConfig.ArrivalDistance then
				isGuidingRock = false
			end
		elseif
			flatDistance(position, target) > GuideConfig.ArrivalDistance and isNearWorseRock(position, best)
		then
			isGuidingRock = true
		end
		guidedPart = if isGuidingRock then targetPart else nil
		return if isGuidingRock then target else nil
	end

	trove:Connect(RunService.Heartbeat, function()
		local character = Players.LocalPlayer.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not root or not root:IsA("BasePart") then
			setHighlight(nil)
			isGuidingRock = false
			clear()
			return
		end

		local position = root.Position
		local target = chooseTarget(position)
		setHighlight(guidedPart)
		if not target then
			clear()
			return
		end

		local flat = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
		local total = flat.Magnitude
		if total < 0.01 then
			clear()
			return
		end
		local direction = flat.Unit
		local origin = Vector3.new(position.X, position.Y + GuideConfig.ArrowChestHeight, position.Z)
		local rotation = CFrame.lookAt(Vector3.zero, direction)
			* CFrame.Angles(0, math.rad(GuideConfig.ArrowYawDegrees), 0)
		ensureArrows()

		local phase = (os.clock() * GuideConfig.ArrowScrollSpeed / GuideConfig.ArrowSpacing) % 1
		local count = #arrows
		for index, arrow in arrows do
			local step = index - 1 + phase
			local distance = GuideConfig.ArrowStartDistance + step * GuideConfig.ArrowSpacing
			local reach = math.clamp(
				(total - GuideConfig.ArrowStopDistance - distance) / GuideConfig.ArrowSpacing,
				0,
				1
			)
			arrow.Part.CFrame = rotation + origin + direction * distance
			arrow.SetTransparency(1 - math.sin(step / count * math.pi) * reach)
		end
	end)
end

return ArrowTrail
