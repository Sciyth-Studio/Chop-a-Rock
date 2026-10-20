--!strict

local Players = game:GetService("Players")

export type Target = {
	UserId: number,
	Name: string,
	Player: Player?,
}

local Targets = {}

local function clean(text: string): string
	return (string.gsub(text, "^%s*@?(.-)%s*$", "%1"))
end

function Targets.Find(text: string): (Player?, string?)
	local query = string.lower(clean(text))
	if #query == 0 then
		return nil, "enter a player name"
	end
	local userId = tonumber(query)
	local matches: { Player } = {}
	for _, player in Players:GetPlayers() do
		local name = string.lower(player.Name)
		if name == query or player.UserId == userId then
			return player, nil
		end
		if
			string.sub(name, 1, #query) == query
			or string.sub(string.lower(player.DisplayName), 1, #query) == query
		then
			table.insert(matches, player)
		end
	end
	if #matches == 1 then
		return matches[1], nil
	elseif #matches > 1 then
		return nil, `{#matches} players match {text}, type more of the name`
	end
	return nil, `no player called {text} in this server`
end

function Targets.Resolve(text: string): (Target?, string?)
	local player, problem = Targets.Find(text)
	if player then
		return { UserId = player.UserId, Name = player.Name, Player = player }, nil
	end
	local query = clean(text)
	if #query == 0 or string.find(problem or "", "players match") then
		return nil, problem
	end
	local userId = tonumber(query)
	if userId then
		if userId < 1 or userId % 1 ~= 0 then
			return nil, `{query} is not a UserId`
		end
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		return { UserId = userId, Name = if ok and type(name) == "string" then name else tostring(userId) },
			nil
	end
	local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, query)
	if not ok or type(id) ~= "number" then
		return nil, `no Roblox user called {query}`
	end
	return { UserId = id, Name = query }, nil
end

return Targets
