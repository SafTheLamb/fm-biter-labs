local ftech = require("__fdsl__.lib.technology")
local frep = require("__fdsl__.lib.recipe")

local techs = ftech.find_by_unlock("lab")
for _,tech_name in pairs(techs) do
	ftech.replace_unlock(tech_name, "lab", "science-altar")
	data.raw.recipe["science-altar"].enabled = false
end

for _,tech in pairs(data.raw.technology) do
	if tech.research_trigger and tech.research_trigger.item == "lab" then
		tech.research_trigger.item = "science-altar"
	end
end

local recipes = frep.find_by_ingredient("lab")
for _,recipe_name in pairs(recipes) do
	frep.replace_ingredient(recipe_name, "lab", "science-altar")
end

