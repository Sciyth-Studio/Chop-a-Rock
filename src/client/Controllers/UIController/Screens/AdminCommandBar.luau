--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local AdminWarps = require(ReplicatedStorage.Utils.AdminWarps)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

type Entry = {
	Alias: string,
	Id: string,
	Label: string,
	Command: AdminConfig.Command?,
}

local AdminCommandBar = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[AdminCommandBar] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function buildEntries(): { Entry }
	local entries: { Entry } = {}
	for _, extra in AdminConfig.CommandBar.Extras do
		table.insert(entries, { Alias = extra.Alias, Id = extra.Id, Label = extra.Id })
	end
	for _, command in AdminConfig.Commands do
		table.insert(entries, {
			Alias = command.Alias or string.lower(command.Id),
			Id = command.Id,
			Label = command.Label,
			Command = command,
		})
	end
	return entries
end

local function matchOne(query: string, options: { string }): string?
	local lowered = string.lower(query)
	for _, option in options do
		if string.lower(option) == lowered then
			return option
		end
	end
	local found: string? = nil
	for _, option in options do
		if string.sub(string.lower(option), 1, #lowered) == lowered then
			if found then
				return nil
			end
			found = option
		end
	end
	return found
end

local function optionsFor(entry: Entry): ({ string }, { [string]: string })
	local options: { string } = {}
	local values: { [string]: string } = {}
	local function add(text: string, value: string)
		local key = string.gsub(text, "%s+", "")
		table.insert(options, key)
		values[key] = value
	end
	if entry.Id == "ApplyPreset" then
		for _, preset in AdminConfig.Presets do
			add(preset.Id, preset.Id)
		end
	elseif entry.Id == "Warp" then
		add(AdminConfig.BaseWarpLabel, AdminConfig.BaseWarpLabel)
		for _, warp in AdminWarps.List() do
			add(warp.Label, warp.Label)
		end
	elseif entry.Command and entry.Command.Choices then
		for _, choice in entry.Command.Choices do
			add(choice.Value, choice.Value)
		end
	end
	return options, values
end

local function findEntry(entries: { Entry }, word: string): Entry?
	local aliases: { string } = {}
	local byAlias: { [string]: Entry } = {}
	for _, entry in entries do
		table.insert(aliases, entry.Alias)
		byAlias[entry.Alias] = entry
		if string.lower(entry.Id) == string.lower(word) then
			return entry
		end
	end
	local alias = matchOne(word, aliases)
	return if alias then byAlias[alias] else nil
end

local function resolve(entries: { Entry }, text: string): (Entry?, string?, string?)
	local first, rest = string.match(text, "^%s*(%S+)%s*(.-)%s*$")
	if not first then
		return nil, nil, nil
	end
	local entry = findEntry(entries, first)
	if not entry then
		return nil, nil, `Unknown command "{first}"`
	end
	local argument = rest or ""
	local options, values = optionsFor(entry)
	if #options > 0 then
		local choice, tail = string.match(argument, "^(%S+)%s*(.-)$")
		local matched = if choice then matchOne(choice, options) else nil
		if not matched then
			return nil, nil, `{entry.Alias}: pick one of {table.concat(options, ", ")}`
		end
		argument = values[matched] .. (if tail and #tail > 0 then " " .. tail else "")
	end
	if entry.Command and entry.Command.Kind == "Button" then
		argument = ""
	end
	return entry, argument, nil
end

function AdminCommandBar.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local adminController = context.Controllers.AdminController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local input: TextBox? = find(gui, "Input", "TextBox")
	local hints: TextLabel? = find(gui, "Hints", "TextLabel")
	local entries = buildEntries()
	local history: { string } = {}
	local historyIndex = 0
	local isOpen = false

	local function setHints(lines: { string })
		if hints then
			hints.Text = table.concat(lines, "\n")
			hints.Visible = #lines > 0
		end
	end

	local function refreshHints(text: string)
		local first, rest = string.match(text, "^%s*(%S*)(.-)$")
		local word = string.lower(first or "")
		local lines: { string } = {}
		if #word == 0 then
			setHints({ "Type a command. Up/Down for history, Esc to close." })
			return
		end
		local entry = if rest and #rest > 0 then findEntry(entries, word) else nil
		if entry then
			local options = optionsFor(entry)
			table.insert(lines, `{entry.Alias}: {entry.Label}`)
			if #options > 0 then
				table.insert(lines, table.concat(options, ", "))
			end
			setHints(lines)
			return
		end
		for _, candidate in entries do
			if string.sub(candidate.Alias, 1, #word) == word then
				table.insert(lines, `{candidate.Alias}: {candidate.Label}`)
				if #lines >= AdminConfig.CommandBar.MaxHints then
					break
				end
			end
		end
		setHints(if #lines > 0 then lines else { `No command starts with "{word}"` })
	end

	local function submit()
		if not input then
			return
		end
		local text = input.Text
		local entry, argument, problem = resolve(entries, text)
		if not entry then
			if problem then
				setHints({ problem })
			end
			input:CaptureFocus()
			return
		end
		table.insert(history, text)
		historyIndex = #history + 1
		adminController:Run(entry.Id, argument)
		context.Close(AdminConfig.CommandBar.ScreenName)
	end

	if input then
		local box = input
		trove:Add(box:GetPropertyChangedSignal("Text"):Connect(function()
			refreshHints(box.Text)
		end))
		trove:Add(box.FocusLost:Connect(function(enterPressed: boolean, cause: InputObject?)
			if enterPressed then
				submit()
			elseif cause and cause.KeyCode == Enum.KeyCode.Escape then
				context.Close(AdminConfig.CommandBar.ScreenName)
			end
		end))
	end

	trove:Add(UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if not adminController:IsAdmin() then
			return
		end
		local key = inputObject.KeyCode
		if key == AdminConfig.CommandBar.Key then
			for _, modifier in AdminConfig.ShortcutModifiers do
				if not UserInputService:IsKeyDown(modifier) then
					return
				end
			end
			if isOpen then
				context.Close(AdminConfig.CommandBar.ScreenName)
			else
				context.Open(AdminConfig.CommandBar.ScreenName)
			end
		elseif isOpen and input and input:IsFocused() then
			if (key == Enum.KeyCode.Up or key == Enum.KeyCode.Down) and #history > 0 then
				historyIndex =
					math.clamp(historyIndex + (if key == Enum.KeyCode.Up then -1 else 1), 1, #history)
				input.Text = history[historyIndex]
				input.CursorPosition = #input.Text + 1
			end
		end
	end))

	trove:Add(Players.LocalPlayer:GetAttributeChangedSignal(AdminConfig.AttributeName):Connect(function()
		if not adminController:IsAdmin() then
			context.Close(AdminConfig.CommandBar.ScreenName)
		end
	end))

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = adminController:IsAdmin()
			gui.Enabled = isOpen
			if isOpen and input then
				local box = input
				historyIndex = #history + 1
				task.defer(function()
					box.Text = ""
					refreshHints("")
					box:CaptureFocus()
				end)
			end
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			gui.Enabled = false
			if input and input:IsFocused() then
				input:ReleaseFocus()
			end
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return AdminCommandBar
