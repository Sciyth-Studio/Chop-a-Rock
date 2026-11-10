--!strict

export type OutlinedIconSettings = {
	SmallMaxPixels: number,
	Normal: { [string]: string },
	Small: { [string]: string },
}

local OutlinedIconConfig: OutlinedIconSettings = {
	SmallMaxPixels = 72,
	Normal = {
		["rbxassetid://124121424211029"] = "rbxassetid://128319899091395",
		["rbxassetid://120312068437386"] = "rbxassetid://100360480462258",
		["rbxassetid://77810536840332"] = "rbxassetid://127640865540613",
		["rbxassetid://127246458137884"] = "rbxassetid://89098434230831",
		["rbxassetid://115907731373474"] = "rbxassetid://127249037957040",
		["rbxassetid://93115935204377"] = "rbxassetid://128938826131941",
		["rbxassetid://80371787143053"] = "rbxassetid://114059717767895",
		["rbxassetid://111696014625309"] = "rbxassetid://105543628272239",
		["rbxassetid://137511164992804"] = "rbxassetid://87970951489062",
		["rbxassetid://119119338643616"] = "rbxassetid://82503645421605",
		["rbxassetid://132080330376191"] = "rbxassetid://87285149397096",
		["rbxassetid://139362520433112"] = "rbxassetid://116172753210312",
		["rbxassetid://79905876183400"] = "rbxassetid://82087287594287",
		["rbxassetid://113854894532938"] = "rbxassetid://132272340546373",
		["rbxassetid://91457041311285"] = "rbxassetid://101164053200118",
		["rbxassetid://97839648540693"] = "rbxassetid://88048386772291",
		["rbxassetid://117415041002029"] = "rbxassetid://72947446403299",
		["rbxassetid://135474126728093"] = "rbxassetid://80210331017843",
		["rbxassetid://101112809904563"] = "rbxassetid://135460604417395",
		["rbxassetid://118503914460480"] = "rbxassetid://80184070291400",
		["rbxassetid://123447750647234"] = "rbxassetid://72766450103598",
	},
	Small = {
		["rbxassetid://124121424211029"] = "rbxassetid://137807346699234",
		["rbxassetid://120312068437386"] = "rbxassetid://123300420859502",
		["rbxassetid://77810536840332"] = "rbxassetid://74621122874702",
		["rbxassetid://127246458137884"] = "rbxassetid://94684220427373",
		["rbxassetid://115907731373474"] = "rbxassetid://137794080161008",
		["rbxassetid://97839648540693"] = "rbxassetid://115895841336737",
		["rbxassetid://117415041002029"] = "rbxassetid://83009479189797",
	},
}

return table.freeze(OutlinedIconConfig)
