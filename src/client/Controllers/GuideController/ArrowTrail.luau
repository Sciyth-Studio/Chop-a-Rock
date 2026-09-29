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

type TroveInstance = typeof(Trove.new())
type Arrow = { Part: BasePart, SetTransparency: (number) -> () }

local SHOP_TAG = "ShopKiosk"

local ArrowTrail = {}

local function readAttribute(name: string): number
	local value = Players.LocalPlayer:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function bestBreakable(strength: number): RockConfig.Rock?
	local best: RockConfig.Rock? = nil
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for _, rock in rocks do
		if
			rock.StrengthRequired <= strength
			and (not best or rock.StrengthRequired > best.StrengthRequired)
		then
			best = rock
		end
	end
	return best
end

local function isNearWorseRock(position: Vector3, best: RockConfig.Rock): boolean
	local rocks: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for _, rock in rocks do
		if
			rock.StrengthRequired < best.StrengthRequired
			and flatDistance(position, rock.PlaceholderPosition) <= GuideConfig.GrindDistance
		then
			return true
		end
	end
	return false
end

local function isReadyToUpgrade(): boolean
	local nextTier = ArmConfig.Tiers[math.max(1, readAttribute("ArmTier")) + 1]
	return nextTier ~= nil and readAttribute("Cash") >= nextTier.Price
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

function ArrowTrail.Start(trove: TroveInstance)
	local arrows: { Arrow } = {}
	local isGuidingRock = false
	local isShopDismissed = false

	local function clear()
		for _, arrow in arrows do
			arrow.Part:Destroy()
		end
		table.clear(arrows)
	end
	trove:Add(clear)

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
		local isReady = isReadyToUpgrade()
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

		local best = bestBreakable(readAttribute("Strength"))
		if not best then
			isGuidingRock = false
			return nil
		end
		local target = best.PlaceholderPosition
		if isGuidingRock then
			if flatDistance(position, target) <= GuideConfig.ArrivalDistance then
				isGuidingRock = false
			end
		elseif
			flatDistance(position, target) > GuideConfig.ArrivalDistance and isNearWorseRock(position, best)
		then
			isGuidingRock = true
		end
		return if isGuidingRock then target else nil
	end

	trove:Connect(RunService.Heartbeat, function()
		local character = Players.LocalPlayer.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not root or not root:IsA("BasePart") then
			isGuidingRock = false
			clear()
			return
		end

		local position = root.Position
		local target = chooseTarget(position)
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
