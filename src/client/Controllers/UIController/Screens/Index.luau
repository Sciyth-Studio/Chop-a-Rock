--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local IndexConfig = require(ReplicatedStorage.Config.IndexConfig)
local IndexRewards = require(ReplicatedStorage.IndexRewards)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "Index"

local Index = {}

type Card = {
	Key: string,
	Zone: IndexConfig.Zone,
	Name: TextLabel?,
	Preview: ViewportFrame?,
	Alert: GuiObject?,
	Stroke: UIStroke?,
}

type Section = {
	Zone: IndexConfig.Zone,
	Fill: GuiObject?,
	Label: TextLabel?,
	Reward: TextButton?,
	RewardLabel: TextLabel?,
}

type Tab = {
	Page: IndexConfig.Page,
	Button: TextButton,
	Count: TextLabel?,
}

local function find(root: Instance, name: string, className: string, recursive: boolean): any
	local found = root:FindFirstChild(name, recursive)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Index] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if label then
		label.Text = text
	end
end

local function fillOf(button: Instance?): Instance?
	return if button then button:FindFirstChild("Fill", true) else nil
end

local function paint(fill: Instance?, colors: ShopConfig.MeterColors)
	if not fill then
		return
	end
	local gradient = fill:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors.Edge),
			ColorSequenceKeypoint.new(0.5, colors.Center),
			ColorSequenceKeypoint.new(1, colors.Edge),
		})
	end
	local studs = fill:FindFirstChild("StudTexture")
	if studs and studs:IsA("ImageLabel") then
		studs.ImageColor3 = colors.Studs
	end
end

local function buildPreview(frame: ViewportFrame, modelKey: string?)
	for _, child in frame:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
	if not modelKey then
		return
	end
	local model = AssetRegistry.get(modelKey)
	if not model:IsA("Model") then
		model:Destroy()
		warn(`[Index] Asset "{modelKey}" is not a Model`)
		return
	end
	local settings = IndexConfig.Preview
	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.FieldOfView
	camera.Parent = frame
	model.Parent = frame
	local center, size = model:GetBoundingBox()
	local distance = size.Magnitude / 2 / math.tan(math.rad(camera.FieldOfView / 2)) * settings.CameraPadding
	camera.CFrame = CFrame.lookAt(center.Position + settings.CameraDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
end

local function modelKeyOf(page: IndexConfig.Page, key: string): string?
	if page.Kind == "Rocks" then
		return IndexConfig.RockPreviewKeys[key]
	end
	local pet = PetConfig.Pets[key]
	return if pet then pet.ModelKey else nil
end

local function displayNameOf(page: IndexConfig.Page, key: string): string
	if page.Kind == "Rocks" then
		local rock = RockConfig.Rocks[key]
		return if rock then rock.DisplayName else key
	end
	local pet = PetConfig.Pets[key]
	return if pet then pet.DisplayName else key
end

local function rarityOf(page: IndexConfig.Page, key: string): RarityConfig.Rarity?
	if page.Kind ~= "Pets" then
		return nil
	end
	local pet = PetConfig.Pets[key]
	return if pet then RarityConfig.Rarities[pet.Rarity] else nil
end

function Index.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	local pageTrove = trove:Extend()
	local rewardTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local tabsFrame: GuiObject? = find(gui, "Tabs", "GuiObject", true)
	local tabTemplate: TextButton? = find(gui, "TabTemplate", "TextButton", true)
	local headerBar: GuiObject? = find(gui, "HeaderBar", "GuiObject", true)
	local sectionsFrame: ScrollingFrame? = find(gui, "Sections", "ScrollingFrame", true)
	local sectionTemplate: Frame? = find(gui, "SectionTemplate", "Frame", true)
	local claimAll: TextButton? = find(gui, "ClaimAll", "TextButton", true)
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton", true)
	local detail: GuiObject? = find(gui, "Detail", "GuiObject", true)

	local pageName: TextLabel? = if headerBar then find(headerBar, "PageName", "TextLabel", false) else nil
	local pageCount: TextLabel? = if headerBar then find(headerBar, "Count", "TextLabel", false) else nil
	local claimAllLabel: TextLabel? = if claimAll then find(claimAll, "Label", "TextLabel", true) else nil

	local detailPreview: ViewportFrame? = if detail
		then find(detail, "Preview", "ViewportFrame", false)
		else nil
	local detailName: TextLabel? = if detail then find(detail, "EntryName", "TextLabel", false) else nil
	local detailRarity: TextLabel? = if detail then find(detail, "Rarity", "TextLabel", false) else nil
	local detailOdds: TextLabel? = if detail then find(detail, "Odds", "TextLabel", false) else nil
	local detailStat: TextLabel? = if detail then find(detail, "Stat", "TextLabel", false) else nil
	local detailCount: TextLabel? = if detail then find(detail, "Count", "TextLabel", false) else nil
	local rewardsFrame: GuiObject? = if detail then find(detail, "Rewards", "GuiObject", false) else nil
	local rewardTemplate: Frame? = if rewardsFrame
		then find(rewardsFrame, "RewardTemplate", "Frame", false)
		else nil
	local claimButton: TextButton? = if detail then find(detail, "ClaimButton", "TextButton", false) else nil
	local claimLabel: TextLabel? = if claimButton then find(claimButton, "Label", "TextLabel", true) else nil
	local rarityGradient = if detailRarity then detailRarity:FindFirstChildWhichIsA("UIGradient") else nil

	for _, template in { tabTemplate, sectionTemplate, rewardTemplate } :: { GuiObject? } do
		if template then
			template.Visible = false
		end
	end

	local currentPage: IndexConfig.Page = IndexConfig.Pages[1]
	local builtPage: IndexConfig.Page? = nil
	local selectedKey: string? = nil
	local shownKey: string? = nil
	local isClaiming = false
	local tabs: { Tab } = {}
	local cards: { Card } = {}
	local sections: { Section } = {}

	local function readIndex(): any
		return dataController:Get({ "Index" })
	end

	local function claim(request: () -> boolean)
		if isClaiming then
			return
		end
		isClaiming = true
		task.spawn(function()
			if request() then
				LocalSound.Play("SFX_Money_Gain")
			end
			isClaiming = false
		end)
	end

	local function addReward(order: number, icon: string, text: string, style: string)
		if not rewardTemplate or not rewardsFrame then
			return
		end
		local tile = rewardTemplate:Clone()
		tile.Name = `Reward{order}`
		tile.LayoutOrder = order
		tile.Visible = true
		local image = tile:FindFirstChild("Icon")
		if image and image:IsA("ImageLabel") then
			image.Image = icon
		end
		local amount = tile:FindFirstChild("Amount")
		if amount and amount:IsA("TextLabel") then
			amount.Text = text
			Typography.ApplyTextStyle(amount, style)
		end
		tile.Parent = rewardsFrame
		rewardTrove:Add(tile)
	end

	local function refreshDetail(index: any)
		local key = selectedKey
		if not key then
			return
		end
		local page = currentPage
		local zone = IndexRewards.ZoneOf(page, key)
		local isFound = IndexRewards.IsFound(index, page, key)
		local count = IndexRewards.Count(index, page, key)
		if detailPreview then
			if shownKey ~= key then
				buildPreview(detailPreview, modelKeyOf(page, key))
			end
			detailPreview.ImageColor3 = if isFound then Color3.new(1, 1, 1) else IndexConfig.HiddenColor
		end
		setText(detailName, if isFound then displayNameOf(page, key) else IndexConfig.HiddenName)
		local rarity = rarityOf(page, key)
		if detailRarity then
			detailRarity.Visible = rarity ~= nil
			if rarity then
				detailRarity.Text = rarity.DisplayName
				detailRarity.TextColor3 = if rarity.RainbowLabel then Color3.new(1, 1, 1) else rarity.Color
			end
		end
		if rarityGradient then
			rarityGradient.Enabled = rarity ~= nil and rarity.RainbowLabel
			rarityGradient.Color = RarityConfig.Rainbow
		end
		if page.Kind == "Rocks" then
			local rock = RockConfig.Rocks[key]
			setText(
				detailOdds,
				if rock then `Needs {NumberFormat.CompactRock(rock.StrengthRequired)} Strength` else ""
			)
			setText(detailStat, if rock then `${NumberFormat.CompactRock(rock.BasePayout)} per break` else "")
			setText(detailCount, `Broken {NumberFormat.CompactRock(count)}`)
		else
			local pet = PetConfig.Pets[key]
			local oneIn = if zone and zone.GeodeKey then IndexRewards.OneIn(zone.GeodeKey, key) else nil
			setText(detailOdds, if oneIn then `1 in {NumberFormat.Commas(oneIn)}` else "")
			setText(detailStat, if pet then `${NumberFormat.Commas(pet.MoneyPerSecond)}/s` else "")
			setText(detailCount, `Hatched {NumberFormat.Commas(count)}`)
		end
		if shownKey ~= key then
			rewardTrove:Clean()
			local reward = IndexRewards.Reward(page, key)
			if reward then
				addReward(1, IconConfig.Money, `${NumberFormat.Commas(reward.Cash)}`, "Green")
				addReward(2, IconConfig.Strength, `+{NumberFormat.Commas(reward.Strength)}`, "Strength")
			end
		end
		shownKey = key
		local canClaim = IndexRewards.CanClaim(index, page, key)
		local text = if IndexRewards.IsClaimed(index, page, key)
			then IndexConfig.Text.Claimed
			elseif isFound then IndexConfig.Text.Claim
			else IndexConfig.Text.Locked
		setText(claimLabel, text)
		paint(
			fillOf(claimButton),
			if canClaim then IndexConfig.Palette.Claim else IndexConfig.Palette.Claimed
		)
	end

	local function refresh()
		local index = readIndex()
		for _, tab in tabs do
			local found, total = IndexRewards.FoundCount(index, tab.Page)
			setText(tab.Count, `{found} / {total}`)
			paint(
				fillOf(tab.Button),
				if tab.Page == currentPage then IndexConfig.Palette.TabActive else IndexConfig.Palette.TabIdle
			)
		end
		local found, total = IndexRewards.FoundCount(index, currentPage)
		setText(pageName, `{currentPage.DisplayName} Index`)
		setText(pageCount, `{found} / {total}`)
		for _, card in cards do
			local isFound = IndexRewards.IsFound(index, currentPage, card.Key)
			setText(
				card.Name,
				if isFound then displayNameOf(currentPage, card.Key) else IndexConfig.HiddenName
			)
			if card.Preview then
				card.Preview.ImageColor3 = if isFound then Color3.new(1, 1, 1) else IndexConfig.HiddenColor
			end
			if card.Alert then
				card.Alert.Visible = IndexRewards.CanClaim(index, currentPage, card.Key)
			end
			if card.Stroke then
				card.Stroke.Color = if card.Key == selectedKey
					then IndexConfig.SelectedStrokeColor
					else IndexConfig.IdleStrokeColor
			end
		end
		for _, section in sections do
			local zoneFound, zoneTotal = IndexRewards.FoundCount(index, currentPage, section.Zone)
			if section.Fill then
				section.Fill.Size = UDim2.fromScale(if zoneTotal > 0 then zoneFound / zoneTotal else 0, 1)
				paint(
					section.Fill,
					if zoneFound == zoneTotal
						then IndexConfig.Palette.ProgressDone
						else IndexConfig.Palette.Progress
				)
			end
			setText(section.Label, `{zoneFound} / {zoneTotal}`)
			local isClaimed = IndexRewards.IsZoneClaimed(index, currentPage, section.Zone)
			setText(
				section.RewardLabel,
				if isClaimed
					then IndexConfig.Text.Claimed
					else `+{math.floor(IndexConfig.ZoneCashBonus * 100 + 0.5)}% Money`
			)
			paint(
				fillOf(section.Reward),
				if IndexRewards.CanClaimZone(index, currentPage, section.Zone)
					then IndexConfig.Palette.Claim
					else IndexConfig.Palette.Claimed
			)
		end
		local claimable = #IndexRewards.Claimable(index)
		setText(
			claimAllLabel,
			if claimable > 0 then `{IndexConfig.Text.ClaimAll} ({claimable})` else IndexConfig.Text.ClaimAll
		)
		paint(
			fillOf(claimAll),
			if claimable > 0 then IndexConfig.Palette.Claim else IndexConfig.Palette.Claimed
		)
		refreshDetail(index)
	end

	local function select(key: string)
		selectedKey = key
		refresh()
	end

	local function buildPage(page: IndexConfig.Page)
		pageTrove:Clean()
		table.clear(cards)
		table.clear(sections)
		currentPage = page
		builtPage = page
		shownKey = nil
		if not sectionsFrame or not sectionTemplate then
			return
		end
		for order, zone in page.Zones do
			local frame = sectionTemplate:Clone()
			frame.Name = zone.Key
			frame.LayoutOrder = order
			frame.Visible = true
			setText(find(frame, "ZoneName", "TextLabel", false), zone.DisplayName)
			local grid: GuiObject? = find(frame, "Grid", "GuiObject", false)
			local cardTemplate: Frame? = if grid then find(grid, "CardTemplate", "Frame", false) else nil
			if grid and cardTemplate then
				cardTemplate.Visible = false
				for cardOrder, key in zone.Entries do
					local cardFrame = cardTemplate:Clone()
					cardFrame.Name = key
					cardFrame.LayoutOrder = cardOrder
					cardFrame.Visible = true
					local preview: ViewportFrame? = find(cardFrame, "Preview", "ViewportFrame", false)
					if preview then
						buildPreview(preview, modelKeyOf(page, key))
					end
					local glow = cardFrame:FindFirstChild("ColorGlow")
					local gradient = if glow then glow:FindFirstChildWhichIsA("UIGradient") else nil
					if gradient then
						local rarity = rarityOf(page, key)
						gradient.Color =
							ColorSequence.new(if rarity then rarity.Color else IndexConfig.RockCardColor)
					end
					local selectButton: TextButton? = find(cardFrame, "Select", "TextButton", false)
					if selectButton then
						pageTrove:Connect(selectButton.Activated, function()
							select(key)
						end)
					end
					local stroke = cardFrame:FindFirstChild("OuterStroke")
					table.insert(cards, {
						Key = key,
						Zone = zone,
						Name = find(cardFrame, "PetName", "TextLabel", false),
						Preview = preview,
						Alert = find(cardFrame, "Alert", "GuiObject", false),
						Stroke = if stroke and stroke:IsA("UIStroke") then stroke else nil,
					})
					cardFrame.Parent = grid
				end
			end
			local progress = frame:FindFirstChild("Progress", true)
			local reward: TextButton? = find(frame, "ZoneReward", "TextButton", true)
			if reward then
				pageTrove:Connect(reward.Activated, function()
					claim(function()
						return Packets.ClaimIndexZone:Fire(page.Key, zone.Key) == true
					end)
				end)
			end
			table.insert(sections, {
				Zone = zone,
				Fill = if progress then find(progress, "Fill", "GuiObject", true) else nil,
				Label = if progress then find(progress, "Label", "TextLabel", false) else nil,
				Reward = reward,
				RewardLabel = if reward then find(reward, "Label", "TextLabel", true) else nil,
			})
			frame.Parent = sectionsFrame
			pageTrove:Add(frame)
		end
		sectionsFrame.CanvasPosition = Vector2.zero
		local index = readIndex()
		selectedKey = nil
		for _, entry in IndexRewards.Claimable(index, page) do
			if entry.Key then
				selectedKey = entry.Key
				break
			end
		end
		if not selectedKey then
			local firstZone = page.Zones[1]
			selectedKey = if firstZone then firstZone.Entries[1] else nil
		end
	end

	if tabsFrame and tabTemplate then
		for order, page in IndexConfig.Pages do
			local button = tabTemplate:Clone()
			button.Name = page.Key
			button.LayoutOrder = order
			button.Visible = true
			setText(find(button, "Label", "TextLabel", true), page.DisplayName)
			trove:Connect(button.Activated, function()
				if currentPage ~= page then
					buildPage(page)
					refresh()
				end
			end)
			table.insert(tabs, {
				Page = page,
				Button = button,
				Count = find(button, "Count", "TextLabel", true),
			})
			button.Parent = tabsFrame
			trove:Add(button)
		end
	end

	if claimButton then
		trove:Connect(claimButton.Activated, function()
			local key = selectedKey
			local page = currentPage
			if key then
				claim(function()
					return Packets.ClaimIndex:Fire(page.Key, key) == true
				end)
			end
		end)
	end

	if claimAll then
		trove:Connect(claimAll.Activated, function()
			claim(function()
				local claimed = Packets.ClaimAllIndex:Fire()
				return type(claimed) == "number" and claimed > 0
			end)
		end)
	end

	if closeButton then
		trove:Connect(closeButton.Activated, function()
			context.Close(SCREEN_NAME)
		end)
	end

	trove:Add(dataController:Observe({ "Index" }, function()
		if builtPage then
			refresh()
		end
	end))

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			if not builtPage then
				buildPage(currentPage)
			end
			refresh()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Index
