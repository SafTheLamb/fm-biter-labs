local ftech = require("__fdsl__.lib.technology")
local frep = require("__fdsl__.lib.recipe")
local utibl = require("__biter-labs__.scripts.bitlab-util")

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

-- Setup souls from fish
local fish_with_souls = {}
for _,fish in pairs(data.raw.fish) do
	-- "But Sapphira, can't you just search for `fish` in the fish name?" NO.
	-- "fishing-rod" would also trigger that, and what about alien fish that aren't called fish???
	-- Also I need to find it anyway to add the script trigger alongside it.
	if fish.minable and (fish.minable.result or fish.minable.results) then
		for _,result in pairs(fish.minable.results or {fish.minable.result}) do
			local capsule = data.raw.capsule[type(result) == "string" and result or result.name]
			if capsule then
				local food_delivery = utibl.get_food_delivery(capsule.capsule_action)
				if food_delivery then
					if food_delivery.target_effects.type then
						food_delivery.target_effects = {food_delivery.target_effects}
					end
					table.insert(food_delivery.target_effects, {
						type = "script",
						effect_id = "bitlab-fish-eaten-"..fish.name
					})
					local amount
					if type(result) == "string" then
						amount = fish.minable.count or 1
					else
						local product = util.normalize_recipe_product(result)
						amount = (product.amount_min + product.amount_max) / 2 * (product.probability or 1)
					end
					fish_with_souls[fish.name.."-eat"] = fish.max_health ^ 0.9
					fish_with_souls[fish.name.."-kill"] = math.sqrt(math.max(amount, 0))
				end
			end
		end
	end
end

data:extend({
	{
		type = "mod-data",
		name = "bitlab-fish-with-souls",
		data = fish_with_souls
	}
})
