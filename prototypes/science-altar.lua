local hit_effects = require("__base__.prototypes.entity.hit-effects")
local item_sounds = require("__base__.prototypes.item_sounds")
local sounds = require("__base__.prototypes.entity.sounds")

data:extend({
	{
		type = "item",
		name = "science-altar",
		icon = "__biter-labs__/graphics/icons/science-altar.png",
		subgroup = "production-machine",
		order = "zb[science-altar]",
		place_result = "science-altar",
		inventory_move_sound = item_sounds.lab_inventory_move,
		pick_sound = item_sounds.lab_inventory_pickup,
		drop_sound = item_sounds.lab_inventory_move,
		stack_size = 10
	},
	{
		type = "recipe",
		name = "science-altar",
		energy_required = 2,
		ingredients = {
			{type="item", name="electronic-circuit", amount=10},
			{type="item", name="stone-brick", amount=10},
			{type="item", name="firearm-magazine", amount=5}
		},
		results = {{type="item", name="science-altar", amount=1}}
	},
	{
		type = "lab",
		name = "science-altar",
		icon = "__biter-labs__/graphics/icons/science-altar.png",
		flags = {"placeable-player", "player-creation", "get-by-unit-number"},
		minable = {mining_time = 1, result = "science-altar"},
		max_health = 250,
		corpse = "science-altar-remnants",
		dying_explosion = "lab-explosion",
		collision_box = {{-1.7, -1.7}, {1.7, 1.7}},
		selection_box = {{-2, -2}, {2, 2}},
		damaged_trigger_effect = hit_effects.entity(),
		on_animation = {
			layers = {
				{
					filename = "__biter-labs__/graphics/entity/science-altar/science-altar.png",
					width = 194,
					height = 174,
					frame_count = 33,
					line_length = 11,
					animation_speed = 1 / 3,
					shift = util.by_pixel(0, 1.5*4/3),
					scale = 2/3
				},
				{
					filename = "__base__/graphics/entity/lab/lab-integration.png",
					width = 242,
					height = 162,
					line_length = 1,
					repeat_count = 33,
					animation_speed = 1 / 3,
					shift = util.by_pixel(0, 15.5*4/3),
					scale = 2/3
				},
				{
					filename = "__biter-labs__/graphics/entity/science-altar/science-altar-light.png",
					blend_mode = "additive",
					draw_as_light = true,
					width = 216,
					height = 194,
					frame_count = 33,
					line_length = 11,
					animation_speed = 1 / 3,
					shift = util.by_pixel(0, 0),
					scale = 2/3
				},
				{
					filename = "__base__/graphics/entity/lab/lab-shadow.png",
					width = 242,
					height = 136,
					line_length = 1,
					repeat_count = 33,
					animation_speed = 1 / 3,
					shift = util.by_pixel(13*4/3, 11*4/3),
					scale = 2/3,
					draw_as_shadow = true
				}
			}
		},
		off_animation = {
			layers = {
				{
					filename = "__biter-labs__/graphics/entity/science-altar/science-altar.png",
					width = 194,
					height = 174,
					shift = util.by_pixel(0, 1.5*4/3),
					scale = 2/3
				},
				{
					filename = "__base__/graphics/entity/lab/lab-integration.png",
					width = 242,
					height = 162,
					shift = util.by_pixel(0, 15.5*4/3),
					scale = 2/3
				},
				{
					filename = "__base__/graphics/entity/lab/lab-shadow.png",
					width = 242,
					height = 136,
					shift = util.by_pixel(13*4/3, 11*4/3),
					draw_as_shadow = true,
					scale = 2/3
				}
			}
		},
		working_sound = {
			sound = {
				filename = "__base__/sound/lab.ogg",
				volume = 0.7,
				modifiers = {volume_multiplier("main-menu", 2.2), volume_multiplier("tips-and-tricks", 0.8)},
				audible_distance_modifier = 0.7,
			},
			fade_in_ticks = 4,
			fade_out_ticks = 20
		},
		impact_category = "glass",
		open_sound = sounds.lab_open,
		close_sound = sounds.lab_close,
		energy_source = {type="void"},
		energy_usage = "1kW",
		researching_speed = 0,
		inputs = {
			"automation-science-pack",
			"logistic-science-pack",
			"military-science-pack",
			"chemical-science-pack",
			"production-science-pack",
			"utility-science-pack",
			"space-science-pack"
		},
		-- module_slots = 2,
		icons_positioning = {
			{inventory_index = defines.inventory.lab_modules, shift = {0, 0.9}},
			{inventory_index = defines.inventory.lab_input, shift = {0, 0}, max_icons_per_row = 4, separation_multiplier = 1/1.1}
		},
	},
	{
		type = "corpse",
		name = "science-altar-remnants",
		icon = "__biter-labs__/graphics/icons/science-altar.png",
		flags = {"placeable-neutral", "not-on-map"},
		hidden_in_factoriopedia = true,
		subgroup = "production-machine-remnants",
		order = "a-g-a",
		selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
		tile_width = 3,
		tile_height = 3,
		selectable_in_game = false,
		time_before_removed = 60 * 60 * 15, -- 15 minutes
		expires = false,
		final_render_layer = "remnants",
		remove_on_tile_placement = false,
		animation = make_rotated_animation_variations_from_sheet (2, {
			filename = "__biter-labs__/graphics/entity/science-altar/remnants.png",
			line_length = 1,
			width = 266,
			height = 196,
			direction_count = 1,
			shift = util.by_pixel(7, 5.5),
			scale = 0.5
		})
	}
})
