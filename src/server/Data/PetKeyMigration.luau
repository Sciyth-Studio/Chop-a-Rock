--!strict

local PetKeyMigration = {}

PetKeyMigration.Map = table.freeze({
	Bloky = "Bunny",
	Sprout = "Squirrel",
	Shroomy = "Fox",
	Nesty = "Owl",
	Berry = "Bear",
	Treebo = "Unicorn",
	Pointy = "Gecko",
	Spike = "Armadillo",
	Howdy = "Scorpion",
	Flowy = "Vulture",
	Ankhy = "Camel",
	Sunny = "Sphinx",
	Roly = "Monkey",
	Leafy = "Toucan",
	Viney = "Sloth",
	Coco = "Tiger",
	Tiki = "Gorilla",
	Bloomy = "Panther",
	Drip = "Crab",
	Bubbly = "Clownfish",
	Shelly = "Turtle",
	Reefy = "Octopus",
	Glowy = "Shark",
	Chompy = "Narwhal",
	Hexy = "Penguin",
	Beanie = "Seal",
	Cozy = "Reindeer",
	Stacky = "Walrus",
	Climby = "ArcticWolf",
	Starry = "Yeti",
	Champ = "Capybara",
	Kingy = "KingRex",
} :: { [string]: string })

local function moveCounts(counts: any)
	if type(counts) ~= "table" then
		return
	end
	for oldKey, newKey in PetKeyMigration.Map do
		local amount = counts[oldKey]
		if type(amount) == "number" then
			local existing = counts[newKey]
			counts[newKey] = (if type(existing) == "number" then existing else 0) + amount
		end
		counts[oldKey] = nil
	end
end

local function moveFlags(flags: any)
	if type(flags) ~= "table" then
		return
	end
	for oldKey, newKey in PetKeyMigration.Map do
		if flags[oldKey] ~= nil then
			flags[newKey] = flags[newKey] == true or flags[oldKey] == true
			flags[oldKey] = nil
		end
	end
end

function PetKeyMigration.Apply(data: any)
	if type(data.Pets) == "table" then
		for _, pet in data.Pets do
			if type(pet) == "table" and type(pet.Key) == "string" then
				pet.Key = PetKeyMigration.Map[pet.Key] or pet.Key
			end
		end
	end
	if type(data.Index) == "table" then
		moveCounts(data.Index.Pets)
		if type(data.Index.Claimed) == "table" then
			moveFlags(data.Index.Claimed.Pets)
		end
	end
	moveCounts(data.PendingPets)
	moveFlags(data.Exclusives)
end

return PetKeyMigration
