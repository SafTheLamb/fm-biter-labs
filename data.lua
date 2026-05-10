require("prototypes.science-altar")
require("prototypes.particles")
require("prototypes.input")
require("prototypes.soul-scouter")

data.raw.item["lab"].hidden = true
data.raw.recipe["lab"].hidden = true
data.raw.lab["lab"].hidden = true

if mods["space-age"] then
	data.raw.item["biolab"].hidden = true
	data.raw.recipe["biolab"].hidden = true
	data.raw.lab["biolab"].hidden = true
end
