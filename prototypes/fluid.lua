data:extend({
	{
		type = "item-subgroup",
		name = "bitlab-fluids",
		group = "fluids",
		order = "b"
	},
	{
		type = "fluid",
		name = "bitlab-souls",
		icon = "__biter-labs__/graphics/icons/fluid/souls.png",
		subgroup = "bitlab-fluids",
		order = "a[fluid]",
		default_temperature = 666,
		gas_teperature = 0,
		base_color = {1, 0, 1},
		flow_color = {1, 0.5, 1},
	}
})
