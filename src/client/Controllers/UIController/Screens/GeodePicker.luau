--!strict

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodePickerConfig = require(ReplicatedStorage.Config.GeodePickerConfig)
local GeodeStandConfig = require(ReplicatedStorage.Config.GeodeStandConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ShopCards = require(script.Parent.Parent.ShopCards)
local Types = require(script.Parent.Parent.Types)

local GeodePicker = {}

local function buildPreview(frame: ViewportFrame, modelKey: string)
	local model = AssetRegistry.get(modelKey)
	if not model:IsA("Model") then
		model:Destroy()
		warn(`[GeodePicker] Asset "{modelKey}" is not a Model`)
		return
	end
	local settings = GeodeStandConfig.Preview
	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.FieldOfView
	camera.Parent = frame
	model.Parent = frame
	local center, size = model:GetBoundingBox()
	local distance = size.Magnitude / 2 / math.tan(math.rad(camera.FieldOfView / 2)) * settings.CameraPadding
	camera.CFrame = CFrame.lookAt(center.Position + settings.CameraDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
end

local function orderedKeys(): { string }
	local keys: { string } = {}
	local lucky = GeodeOrder.SortedLucky()
	for _, key in GeodeOrder.Sorted() do
		table.insert(keys, key)
		local luckyKey = GeodeOrder.LuckyKey(key)
		if luckyKey and table.find(lucky, luckyKey) then
			table.insert(keys, luckyKey)
		end
	end
	return keys
end

function GeodePicker.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local cardTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local dataController = context.Controllers.DataController
	local panel = gui:FindFirstChild("Panel", true)
	local itemsInstance = if panel then panel:FindFirstChild("Items") else nil
	local items: GuiObject? = if itemsInstance and itemsInstance:IsA("GuiObject") then itemsInstance else nil
	local template = if items then items:FindFirstChild("ItemTemplate") else nil
	if not panel or not items or not template then
		warn(`[GeodePicker] Missing Items/ItemTemplate in {gui:GetFullName()}`)
	end
	if panel then
		ShopCards.SetText(panel, "Step", GeodePickerConfig.StepText)
	end

	local isOpen = false

	local function build()
		cardTrove:Clean()
		if not items or not template then
			return
		end
		local geodes = dataController:Get({ "Geodes" })
		if type(geodes) ~= "table" then
			return
		end
		local selected = dataController:Get({ "SelectedGeode" })
		local current = GeodeOrder.Pick(geodes, if type(selected) == "string" then selected else nil)
		for index, key in orderedKeys() do
			local count = geodes[key] or 0
			local geode = GeodeConfig.Geodes[key]
			if count < 1 or not geode then
				continue
			end
			local tray = template:Clone()
			local inner = tray:FindFirstChild("Card")
			if not tray:IsA("Frame") or not inner or not inner:IsA("Frame") then
				tray:Destroy()
				continue
			end
			cardTrove:Add(tray)
			tray.Visible = true
			tray.LayoutOrder = index
			local paletteName = if geode.RobuxOnly
				then GeodePickerConfig.LuckyPalette
				else GeodePickerConfig.ZonePalette
			ShopCards.Paint(tray, inner, RobuxShopConfig.Palettes[paletteName])
			ShopCards.SetIcon(inner, "", false)
			ShopCards.SetVisible(inner, "Icon", false)
			local preview = inner:FindFirstChild("Preview")
			if preview and preview:IsA("ViewportFrame") then
				preview.Visible = true
				buildPreview(preview, geode.ModelKey)
			end
			ShopCards.SetText(inner, "Title", geode.DisplayName)
			ShopCards.SetText(inner, "Ribbon", string.format(GeodePickerConfig.CountFormat, count))
			local choose = ShopCards.Find(inner, "BuyButton")
			local isCurrent = key == current
			ShopCards.SetButton(
				choose,
				if isCurrent then GeodePickerConfig.ChosenText else GeodePickerConfig.ChooseText,
				if isCurrent then RobuxShopConfig.OwnedColors else RobuxShopConfig.BuyColors
			)
			if choose then
				cardTrove:Connect(choose.Activated, function()
					context.Feedback(choose, true)
					if not isCurrent then
						Packets.SelectGeode:Fire(key)
					end
					context.Close(GeodePickerConfig.ScreenName)
				end)
			end
			tray.Parent = items
		end
	end

	local close = if panel then panel:FindFirstChild("CloseButton", true) else nil
	if close and close:IsA("GuiButton") then
		trove:Connect(close.Activated, function()
			context.Close(GeodePickerConfig.ScreenName)
		end)
	end
	trove:Connect(ProximityPromptService.PromptTriggered, function(prompt: ProximityPrompt)
		if CollectionService:HasTag(prompt, GeodeConfig.PickPromptTag) then
			context.Open(GeodePickerConfig.ScreenName)
		end
	end)
	for _, path in { { "Geodes" }, { "SelectedGeode" } } do
		trove:Add(dataController:Observe(path, function()
			if isOpen then
				build()
			end
		end))
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen, _argument: any?)
			isOpen = true
			gui.Enabled = true
			build()
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			gui.Enabled = false
			cardTrove:Clean()
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return GeodePicker
