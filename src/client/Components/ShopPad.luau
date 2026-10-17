--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local ShopPadConfig = require(ReplicatedStorage.Config.ShopPadConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type ShopPad = {
	Instance: Instance,
	Trove: any,
	Screen: string?,
	ScreenKey: string?,
	IsInside: boolean,
	Prompt: ProximityPrompt?,
}

local function buildWall(self: ShopPad, part: BasePart)
	local template = AssetRegistry.get(ShopPadConfig.WallTemplateKey)
	local wall = template:FindFirstChild("Wall", true)
	if not wall or not wall:IsA("Beam") then
		warn(`[ShopPad] {ShopPadConfig.WallTemplateKey} needs a Wall Beam`)
		template:Destroy()
		return
	end
	local heightStuds = wall:GetAttribute("HeightStuds")
	local top = Vector3.new(0, if type(heightStuds) == "number" then heightStuds else 4, 0)
	local halfX = part.Size.X / 2
	local halfZ = part.Size.Z / 2
	local sides = {
		{ Outward = Vector3.xAxis, Distance = halfX, Width = part.Size.Z },
		{ Outward = -Vector3.xAxis, Distance = halfX, Width = part.Size.Z },
		{ Outward = Vector3.zAxis, Distance = halfZ, Width = part.Size.X },
		{ Outward = -Vector3.zAxis, Distance = halfZ, Width = part.Size.X },
	}
	for _, side in sides do
		local outward = part.CFrame:VectorToWorldSpace(side.Outward)
		local tangent = Vector3.yAxis:Cross(outward)
		local position = part.Position + outward * side.Distance
		local bottomAttachment = self.Trove:Add(Instance.new("Attachment"))
		bottomAttachment.Parent = part
		bottomAttachment.WorldCFrame = CFrame.fromMatrix(position, outward, tangent)
		local topAttachment = self.Trove:Add(Instance.new("Attachment"))
		topAttachment.Parent = part
		topAttachment.WorldCFrame = CFrame.fromMatrix(position + top, outward, tangent)
		local beam = self.Trove:Add(wall:Clone())
		beam.Attachment0 = bottomAttachment
		beam.Attachment1 = topAttachment
		beam.Width0 = side.Width
		beam.Width1 = side.Width
		beam.Color = ColorSequence.new(part.Color)
		beam.Parent = part
	end
	template:Destroy()
end

local function buildPrompt(self: ShopPad, part: BasePart, onTriggered: () -> ())
	local anchor = self.Trove:Add(Instance.new("Attachment"))
	anchor.Parent = part
	anchor.WorldPosition = part.Position + Vector3.new(0, ShopPadConfig.PromptHeightStuds, 0)
	local shopName = part:GetAttribute("ShopName")
	local prompt = self.Trove:Add(Instance.new("ProximityPrompt"))
	prompt.ActionText = "Open"
	prompt.ObjectText = if type(shopName) == "string" then shopName else ""
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = ShopPadConfig.PromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = anchor
	self.Trove:Connect(prompt.Triggered, onTriggered)
	self.Prompt = prompt
end

local function isCharacterInside(self: ShopPad, part: BasePart): boolean
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local offset = part.CFrame:PointToObjectSpace(root.Position)
	if offset.Y < 0 or offset.Y > ShopPadConfig.EnterHeightStuds then
		return false
	end
	local padding = if self.IsInside then ShopPadConfig.ExitPaddingStuds else 0
	return math.abs(offset.X) <= part.Size.X / 2 + padding and math.abs(offset.Z) <= part.Size.Z / 2 + padding
end

return function(controllers: { [string]: any })
	local ShopPad = Component.new({ Tag = "ShopPad" }) :: any

	function ShopPad.Construct(self: ShopPad)
		local screen = self.Instance:GetAttribute("Screen")
		local screenKey = self.Instance:GetAttribute("ScreenKey")
		self.Trove = Trove.new()
		self.Screen = if type(screen) == "string" then screen else nil
		self.ScreenKey = if type(screenKey) == "string" then screenKey else nil
		self.IsInside = false
		self.Prompt = nil
	end

	function ShopPad.Start(self: ShopPad)
		local part = self.Instance
		if not part:IsA("BasePart") or not self.Screen then
			warn(`[ShopPad] Needs a BasePart with a Screen attribute: {part:GetFullName()}`)
			return
		end
		buildWall(self, part)
		buildPrompt(self, part, function()
			if self.Screen then
				controllers.UIController:Open(self.Screen, self.ScreenKey)
			end
		end)
	end

	function ShopPad.RenderSteppedUpdate(self: ShopPad, _dt: number)
		local part = self.Instance
		local screen = self.Screen
		if not part:IsA("BasePart") or not screen then
			return
		end
		local uiController = controllers.UIController
		local isInside = isCharacterInside(self, part)
		if isInside ~= self.IsInside then
			self.IsInside = isInside
			if isInside then
				uiController:Open(screen, self.ScreenKey)
			elseif uiController:IsOpen(screen) then
				uiController:Close(screen)
			end
		end

		local prompt = self.Prompt
		if prompt then
			local shouldShow = isInside and not uiController:IsOpen(screen)
			if prompt.Enabled ~= shouldShow then
				prompt.Enabled = shouldShow
			end
		end
	end

	function ShopPad.Stop(self: ShopPad)
		self.Trove:Destroy()
	end

	return ShopPad
end
