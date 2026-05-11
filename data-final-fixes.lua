local ftech = require("__fdsl__.lib.technology")
local frep = require("__fdsl__.lib.recipe")

local techs = ftech.find_by_unlock("lab")
for _,tech_name in pairs(techs) do
	ftech.replace_unlock(tech_name, "lab", "science-altar")
	data.raw.recipe["science-altar"].enabled = false
end
local burner_techs = ftech.find_by_unlock("burner-lab")
for _,tech_name in pairs(burner_techs) do
	ftech.replace_unlock(tech_name, "burner-lab", "science-altar")
	data.raw.recipe["science-altar"].enabled = false
end

for _,tech in pairs(data.raw.technology) do
	if tech.research_trigger and (tech.research_trigger.item == "lab" or tech.research_trigger.item == "burner-lab") then
		tech.research_trigger.item = "science-altar"
	end
end

local recipes = frep.find_by_ingredient("lab")
for _,recipe_name in pairs(recipes) do
	frep.replace_ingredient(recipe_name, "lab", "science-altar")
end
if mods["aai-industry"] then
	local burner_recipes = frep.find_by_ingredient("burner-lab")
	for _,recipe_name in pairs(burner_recipes) do
		frep.replace_ingredient(recipe_name, "burner-lab", "science-altar")
	end
end
