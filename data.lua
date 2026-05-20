require("prototypes.fluid")
require("prototypes.input")
require("prototypes.science-altar")
require("prototypes.soul-scouter")
require("prototypes.particles")

data.raw.item["lab"].hidden = true
data.raw.recipe["lab"].hidden = true
data.raw.lab["lab"].hidden = true

if mods["aai-industry"] then
	data.raw.item["burner-lab"].hidden = true
	data.raw.recipe["burner-lab"].hidden = true
	data.raw.lab["burner-lab"].hidden = true
	data.raw.lab["burner-lab"].next_upgrade = nil
end

if mods["space-age"] then
	data.raw.item["biolab"].hidden = true
	data.raw.recipe["biolab"].hidden = true
	data.raw.lab["biolab"].hidden = true
end
