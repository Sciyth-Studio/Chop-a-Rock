--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GuideConfig = require(ReplicatedStorage.Config.GuideConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
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

local function findRockPart(key: string): BasePart?
	for _, tagged in CollectionService:GetTagged(ROCK_TAG) do
		if tagged:IsA("BasePart") and tagged:GetAttribute("RockKey") == key then
			return tagged
		end
	end
	return nil
end

local function rockPosition(key: string, rock: RockConfig.Rock): Vector3
	local part = findRockPart(key)
	return if part then part.Position else rock.PlaceholderPosition
end

local function isNearWorseRock(position: Vector3, best: RockConfig.Rock): boolean
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for key, rock in rocks do
		if
			rock.StrengthRequired < best.StrengthRequired
			and flatDistance(position, rockPosition(key, rock)) <= GuideConfig.GrindDistance
		then
			return true
		end
	end
	return false
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
	local guidedKey: string? = nil
	local highlight: Highlight? = nil
	local highlightKey: string? = nil

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
		highlightKey = nil
		local info =
			TweenInfo.new(GuideConfig.HighlightFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(current, info, { FillTransparency = 1, OutlineTransparency = 1 })
		tween.Completed:Once(function()
			current:Destroy()
		end)
		tween:Play()
	end

	local function setHighlight(key: string?)
		if key == highlightKey then
			return
		end
		fadeOutHighlight()
		if not key then
			return
		end
		local part = findRockPart(key)
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
		highlightKey = key
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
		guidedKey = nil
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
		local bestKey, best = bestBreakable(readData(dataController, "Strength"))
		if not best then
			isGuidingRock = false
			return nil
		end
		local target = rockPosition(bestKey or "", best)
		if isGuidingRock then
			if flatDistance(position, target) <= GuideConfig.ArrivalDistance then
				isGuidingRock = false
			end
		elseif
			flatDistance(position, target) > GuideConfig.ArrivalDistance and isNearWorseRock(position, best)
		then
			isGuidingRock = true
		end
		guidedKey = if isGuidingRock then bestKey else nil
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
		setHighlight(guidedKey)
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
