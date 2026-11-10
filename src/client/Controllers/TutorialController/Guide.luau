--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type Guide = {
	Folder: Folder,
	Ray: Beam,
	Start: Attachment,
	Finish: Attachment,
	Highlight: Highlight,
	Params: RaycastParams,
	Clock: number,
	IsUrgent: boolean,
}

local Guide = {}

local function makeRay(folder: Folder, finish: Attachment): Beam
	local ray = Instance.new("Beam")
	ray.Name = "GuideRay"
	ray.Texture = TutorialConfig.RayTexture
	ray.TextureMode = Enum.TextureMode.Wrap
	ray.TextureLength = TutorialConfig.RaySpacing
	ray.TextureSpeed = TutorialConfig.RayScrollSpeed
	ray.Width0 = TutorialConfig.RayWidth
	ray.Width1 = TutorialConfig.RayWidth
	ray.FaceCamera = true
	ray.Segments = 1
	ray.LightEmission = 0
	ray.LightInfluence = 0
	ray.Color = ColorSequence.new(TutorialConfig.RayColor)
	ray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1 - TutorialConfig.RayFadeShare, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	ray.Attachment0 = finish
	ray.Enabled = false
	ray.Parent = folder
	return ray
end

function Guide.new(): Guide
	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuide"
	folder.Parent = workspace

	local anchor = Instance.new("Part")
	anchor.Name = "RayAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Parent = folder

	local finish = Instance.new("Attachment")
	finish.Name = "RayFinish"
	finish.Parent = anchor

	local start = Instance.new("Attachment")
	start.Name = "TutorialRayStart"

	local highlight = Instance.new("Highlight")
	highlight.Name = "TutorialHighlight"
	highlight.FillColor = TutorialConfig.HighlightColor
	highlight.OutlineColor = TutorialConfig.HighlightColor
	highlight.OutlineTransparency = TutorialConfig.HighlightOutlineTransparency
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = folder

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true

	return {
		Folder = folder,
		Ray = makeRay(folder, finish),
		Start = start,
		Finish = finish,
		Highlight = highlight,
		Params = params,
		Clock = 0,
		IsUrgent = false,
	}
end

local function groundAt(guide: Guide, position: Vector3): Vector3?
	local character = Players.LocalPlayer.Character
	guide.Params.FilterDescendantsInstances = if character
		then { guide.Folder, character }
		else { guide.Folder }
	local result = workspace:Raycast(
		position + Vector3.new(0, TutorialConfig.RayGroundProbeStuds, 0),
		Vector3.new(0, -TutorialConfig.RayGroundProbeStuds * 4, 0),
		guide.Params
	)
	return if result then result.Position else nil
end

function Guide.DrawPath(guide: Guide, goal: Vector3, stopStuds: number?)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		Guide.HidePath(guide)
		return
	end
	local start = guide.Start
	if start.Parent ~= root then
		start.Parent = root
	end
	local chest = Vector3.new(0, TutorialConfig.RayChestOffset, 0)
	if start.Position ~= chest then
		start.Position = chest
	end

	local from = root.Position + chest
	local flat = Vector3.new(goal.X - from.X, 0, goal.Z - from.Z)
	local length = flat.Magnitude - (stopStuds or TutorialConfig.RayStopStuds)
	if length < TutorialConfig.RayMinStuds then
		Guide.HidePath(guide)
		return
	end

	local rootGround = groundAt(guide, root.Position)
	local goalGround = groundAt(guide, goal)
	local height = if rootGround then from.Y - rootGround.Y else TutorialConfig.RayChestOffset
	local endY = if goalGround then goalGround.Y + height else from.Y
	local finish = from + flat.Unit * length
	guide.Finish.WorldPosition = Vector3.new(finish.X, endY, finish.Z)

	local ray = guide.Ray
	if ray.Attachment1 ~= start then
		ray.Attachment1 = start
	end
	local width = TutorialConfig.RayWidth * (if guide.IsUrgent then TutorialConfig.IdleRayScale else 1)
	if ray.Width0 ~= width then
		ray.Width0 = width
		ray.Width1 = width
	end
	ray.Enabled = true
end

function Guide.HidePath(guide: Guide)
	guide.Ray.Enabled = false
end

function Guide.DrawMarker(guide: Guide, adornee: Instance, dt: number)
	guide.Clock += dt
	local highlight = guide.Highlight
	if highlight.Adornee ~= adornee then
		highlight.Adornee = adornee
	end
	highlight.Enabled = true
	local pulseSpeed = TutorialConfig.HighlightPulseSpeed
		* (if guide.IsUrgent then TutorialConfig.IdlePulseScale else 1)
	local pulse = (math.sin(guide.Clock * pulseSpeed) + 1) / 2
	highlight.FillTransparency = TutorialConfig.HighlightFillMin
		+ (TutorialConfig.HighlightFillMax - TutorialConfig.HighlightFillMin) * pulse
end

function Guide.SetUrgent(guide: Guide, isUrgent: boolean)
	guide.IsUrgent = isUrgent
end

function Guide.HideMarker(guide: Guide)
	guide.Highlight.Enabled = false
	guide.Highlight.Adornee = nil
end

function Guide.Destroy(guide: Guide)
	guide.Folder:Destroy()
	guide.Start:Destroy()
end

return Guide
