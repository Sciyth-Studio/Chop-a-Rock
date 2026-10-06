--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RokValue = require(ReplicatedStorage.RokValue)
local SellShopConfig = require(ReplicatedStorage.Config.SellShopConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

type Card = {
	Frame: Frame,
	Stroke: UIStroke?,
	PetKey: string,
	HatchedAt: number,
	Value: number,
}

type SortButton = {
	Key: string,
	Fill: Instance?,
	Arrow: TextLabel?,
}

local SellShop = {}

local function find(root: Instance, name: string, className: string, recursive: boolean): any
	local found = root:FindFirstChild(name, recursive)
	if found and found:IsA(className) then
		return found
	end
	warn(`[SellShop] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
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

local function buildPreview(frame: ViewportFrame, modelKey: string)
	local model = AssetRegistry.get(modelKey)
	if not model:IsA("Model") then
		model:Destroy()
		return
	end
	local settings = SellShopConfig.Preview
	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.FieldOfView
	camera.Parent = frame
	model.Parent = frame
	local center, size = model:GetBoundingBox()
	local distance = size.Magnitude / 2 / math.tan(math.rad(camera.FieldOfView / 2)) * settings.CameraPadding
	camera.CFrame = CFrame.lookAt(center.Position + settings.CameraDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
end

local function rarityRank(petKey: string): number
	local pet = PetConfig.Pets[petKey]
	return if pet then table.find(RarityConfig.Order, pet.Rarity) or 0 else 0
end

function SellShop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local cardTrove = trove:Extend()

	local grid: GuiObject? = find(gui, "Grid", "GuiObject", true)
	local template: Frame? = find(gui, "CardTemplate", "Frame", true)
	local sortTemplate: TextButton? = find(gui, "SortTemplate", "TextButton", true)
	local selectAll: TextButton? = find(gui, "SelectAllButton", "TextButton", true)
	local selectAllTick: GuiObject? = if selectAll then find(selectAll, "Tick", "GuiObject", true) else nil
	local sellButton: TextButton? = find(gui, "SellButton", "TextButton", true)
	local sellFill = if sellButton then sellButton:FindFirstChild("Fill", true) else nil
	local totalLabel: TextLabel? = find(gui, "Total", "TextLabel", true)
	local emptyLabel: TextLabel? = find(gui, "EmptyLabel", "TextLabel", true)
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton", true)

	if template then
		template.Visible = false
	end
	if sortTemplate then
		sortTemplate.Visible = false
	end

	local cards: { [string]: Card } = {}
	local selected: { [string]: true } = {}
	local sortKey: string = SellShopConfig.Sorts[1].Key
	local isDescending = true
	local sortButtons: { SortButton } = {}
	local isOpen = false
	local isSelling = false

	local function refreshSelection()
		local total = 0
		local count = 0
		local all = true
		for id, card in cards do
			local isSelected = selected[id] == true
			if card.Stroke then
				card.Stroke.Color = if isSelected
					then SellShopConfig.SelectedStrokeColor
					else SellShopConfig.IdleStrokeColor
			end
			if isSelected then
				total += card.Value
			else
				all = false
			end
			count += 1
		end
		setText(totalLabel, `${NumberFormat.Commas(total)}`)
		paint(sellFill, if total > 0 then SellShopConfig.Palette.Ready else SellShopConfig.Palette.Disabled)
		if selectAllTick then
			selectAllTick.Visible = count > 0 and all
		end
		if emptyLabel then
			emptyLabel.Visible = count == 0
		end
	end

	local function compare(a: string, b: string): boolean
		local cardA, cardB = cards[a], cards[b]
		local keyA: number, keyB: number
		if sortKey == "Rarity" then
			keyA, keyB = rarityRank(cardA.PetKey), rarityRank(cardB.PetKey)
		elseif sortKey == "Newest" then
			keyA, keyB = cardA.HatchedAt, cardB.HatchedAt
		else
			keyA, keyB = cardA.Value, cardB.Value
		end
		if keyA == keyB then
			keyA, keyB = cardA.Value, cardB.Value
		end
		if keyA == keyB then
			keyA, keyB = tonumber(a) or 0, tonumber(b) or 0
		end
		if isDescending then
			return keyA > keyB
		end
		return keyA < keyB
	end

	local function refreshOrder()
		local ids: { string } = {}
		for id in cards do
			table.insert(ids, id)
		end
		table.sort(ids, compare)
		for order, id in ids do
			cards[id].Frame.LayoutOrder = order
		end
		for _, button in sortButtons do
			local isActive = button.Key == sortKey
			paint(
				button.Fill,
				if isActive then SellShopConfig.Palette.Active else SellShopConfig.Palette.Inactive
			)
			if button.Arrow then
				button.Arrow.Text = if isActive and not isDescending
					then SellShopConfig.AscendingArrow
					else SellShopConfig.DescendingArrow
			end
		end
	end

	local function rebuild()
		cardTrove:Clean()
		table.clear(cards)
		local pets = dataController:Get({ "Pets" })
		if type(pets) == "table" and grid and template then
			for id, pet in pets do
				local config = if type(pet) == "table" then PetConfig.Pets[pet.Key] else nil
				if not config or pet.Slot ~= nil then
					continue
				end
				local frame = template:Clone()
				frame.Name = `Rok{id}`
				frame.Visible = true
				local rarity = RarityConfig.Rarities[config.Rarity]
				local rarityLabel: TextLabel? = find(frame, "Rarity", "TextLabel", true)
				setText(rarityLabel, if rarity then rarity.DisplayName else "")
				if rarityLabel and rarity then
					rarityLabel.TextColor3 = rarity.Color
				end
				setText(
					find(frame, "Rate", "TextLabel", true),
					`${NumberFormat.Commas(config.MoneyPerSecond)}/s`
				)
				local value = RokValue.Sell(pet.Key)
				setText(find(frame, "Price", "TextLabel", true), `${NumberFormat.Commas(value)}`)
				local preview: ViewportFrame? = find(frame, "Preview", "ViewportFrame", true)
				if preview then
					buildPreview(preview, config.ModelKey)
				end
				local stroke = frame:FindFirstChild("OuterStroke")
				cards[id] = {
					Frame = frame,
					Stroke = if stroke and stroke:IsA("UIStroke") then stroke else nil,
					PetKey = pet.Key,
					HatchedAt = if type(pet.HatchedAt) == "number" then pet.HatchedAt else 0,
					Value = value,
				}
				local button: TextButton? = find(frame, "Select", "TextButton", true)
				if button then
					cardTrove:Connect(button.Activated, function()
						if selected[id] then
							selected[id] = nil
						else
							selected[id] = true
						end
						refreshSelection()
					end)
				end
				frame.Parent = grid
				cardTrove:Add(frame)
			end
		end
		for id in selected do
			if not cards[id] then
				selected[id] = nil
			end
		end
		refreshOrder()
		refreshSelection()
	end

	if sortTemplate then
		for order, mode in SellShopConfig.Sorts do
			local button = sortTemplate:Clone()
			button.Name = `Sort{mode.Key}`
			button.LayoutOrder = order
			button.Visible = true
			setText(find(button, "Label", "TextLabel", true), mode.Label)
			table.insert(sortButtons, {
				Key = mode.Key :: string,
				Fill = button:FindFirstChild("Fill", true),
				Arrow = find(button, "Arrow", "TextLabel", true),
			})
			trove:Connect(button.Activated, function()
				if sortKey == mode.Key then
					isDescending = not isDescending
				else
					sortKey = mode.Key
					isDescending = true
				end
				refreshOrder()
			end)
			button.Parent = sortTemplate.Parent
		end
	end

	if selectAll then
		trove:Connect(selectAll.Activated, function()
			local all = next(cards) ~= nil
			for id in cards do
				if not selected[id] then
					all = false
				end
			end
			table.clear(selected)
			if not all then
				for id in cards do
					selected[id] = true
				end
			end
			refreshSelection()
		end)
	end

	if sellButton then
		trove:Connect(sellButton.Activated, function()
			local ids: { string } = {}
			for id in selected do
				table.insert(ids, id)
			end
			if isSelling or #ids == 0 then
				return
			end
			isSelling = true
			task.spawn(function()
				local earned = Packets.SellPets:Fire(ids)
				isSelling = false
				if type(earned) == "number" and earned > 0 then
					table.clear(selected)
					LocalSound.Play("SFX_Money_Gain")
					refreshSelection()
				end
			end)
		end)
	end

	if closeButton then
		trove:Connect(closeButton.Activated, function()
			context.Close("SellShop")
		end)
	end

	trove:Add(dataController:Observe({ "Pets" }, function()
		if isOpen then
			rebuild()
		end
	end))

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			table.clear(selected)
			rebuild()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			gui.Enabled = false
			cardTrove:Clean()
			table.clear(cards)
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return SellShop
