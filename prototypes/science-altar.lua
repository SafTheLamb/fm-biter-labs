local hit_effects = require("__base__.prototypes.entity.hit-effects")
local item_sounds = require("__base__.prototypes.item_sounds")
local sounds = require("__base__.prototypes.entity.sounds")

data:extend({
	{
		type = "item",
		name = "bitlab-altar",
		icon = "__biter-labs__/graphics/icons/science-altar.png",
		subgroup = "production-machine",
		order = "zb[science-altar]",
		place_result = "bitlab-tank",
		inventory_move_sound = item_sounds.lab_inventory_move,
		pick_sound = item_sounds.lab_inventory_pickup,
		drop_sound = item_sounds.lab_inventory_move,
		stack_size = 10
	},
	{
		type = "recipe",
		name = "bitlab-altar",
		energy_required = 2,
		ingredients = {
			{type="item", name="electronic-circuit", amount=10},
			{type="item", name="stone-brick", amount=10},
			{type="item", name="firearm-magazine", amount=5}
		},
		results = {{type="item", name="bitlab-altar", amount=1}}
	},
	{
		type = "lab",
		name = "bitlab-altar",
		icon = "__biter-labs__/graphics/icons/science-altar.png",
		flags = {"placeable-player", "player-creation", "get-by-unit-number"},
		minable = {mining_time = 1, result = "bitlab-altar"},
		is_military_target = true,
		collision_mask = {layers = {}},
		collision_box = {{-1.7, -1.7}, {1.7, 1.7}},
		selection_box = {{-2, -2}, {2, 1}},
		damaged_trigger_effect = hit_effects.entity(),
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
		inputs = data.raw.lab["lab"].inputs,
		-- module_slots = 2,
		icons_positioning = {
			{inventory_index = defines.inventory.lab_modules, shift = {0, 0.4}},
			{inventory_index = defines.inventory.lab_input, shift = {0, -0.5}, max_icons_per_row = 4, separation_multiplier = 1/1.1}
		}
	},
	{
		type = "storage-tank",
		name = "bitlab-tank",
		icon = "__biter-labs__/graphics/icons/science-altar.png",
		flags = {"placeable-player", "player-creation", "get-by-unit-number"},
		minable = {mining_time = 1, result = "bitlab-altar"},
		corpse = "bitlab-altar-remnants",
		dying_explosion = "lab-explosion",
		max_health = 250,
		damaged_trigger_effect = hit_effects.entity(),
		collision_box = {{-1.7, -1.7}, {1.7, 1.7}},
		selection_box = {{-2, -2}, {2, 2}},
		selection_priority = 49,
		icon_draw_specification = {scale=0},
		fluid_box = {
			volume = 25000,
			filter = "bitlab-souls",
			pipe_covers = pipecoverspictures(),
			pipe_connections = {
				{ direction = defines.direction.north, position = {-1.5, -1.5}},
				{ direction = defines.direction.west, position = {-1.5, -1.5}},
				{ direction = defines.direction.east, position = {1.5, 1.5}},
				{ direction = defines.direction.south, position = {1.5, 1.5}},
			},
			hide_connection_info = true
		},
		two_direction_only = true,
		window_bounding_box = {{-0.125*4/3, 0.875*4/3}, {0.1875*4/3, 1.375*4/3}},
		-- The item actually places science altar storage tank, so that it can be rotated
		created_effect = {
			type = "direct",
			action_delivery = {
				type = "instant",
				source_effects = {
					type = "script",
					effect_id = "bitlab-tank-created"
				}
			}
		},
		-- Give the storage tank the pictures. The lab on_animation never actually animates anyway
		pictures = {
			picture = {
				sheets = {
					{
						filename = "__biter-labs__/graphics/entity/science-altar/top-patch.png",
						frames = 2,
						width = 256,
						height = 120,
						shift = util.by_pixel(0, 1.5*4/3 - 48),
						scale = 0.5
					},
					{
						filename = "__biter-labs__/graphics/entity/science-altar/science-altar.png",
						frames = 1,
						width = 196,
						height = 219,
						shift = util.by_pixel(0, 1.5*4/3),
						scale = 2/3
					},
					{
						filename = "__biter-labs__/graphics/entity/science-altar/bottom-patch.png",
						frames = 2,
						width = 264,
						height = 128,
						shift = util.by_pixel(0, 1.5*4/3 + 32),
						scale = 0.5
					},
					{
						filename = "__base__/graphics/entity/lab/lab-shadow.png",
						frames = 1,
						width = 242,
						height = 136,
						shift = util.by_pixel(13*4/3, 11*4/3),
						draw_as_shadow = true,
						scale = 2/3
					},
					{
						filename = "__base__/graphics/entity/storage-tank/storage-tank-shadow.png",
						priority = "extra-high",
						frames = 2,
						width = 291,
						height = 153,
						shift = util.by_pixel(29.75, 22.25),
						scale = 0.5,
						draw_as_shadow = true
          			}
				}
			},
			fluid_background = {
				filename = "__base__/graphics/entity/storage-tank/fluid-background.png",
				priority = "extra-high",
				width = 32,
				height = 15,
				scale = 4/3
			},
			window_background = {
				filename = "__base__/graphics/entity/storage-tank/window-background.png",
				priority = "extra-high",
				width = 34,
				height = 48,
				scale = 0.5*4/3
			},
			flow_sprite = {
				filename = "__base__/graphics/entity/pipe/fluid-flow-low-temperature.png",
				priority = "extra-high",
				width = 160,
				height = 20,
				scale = 4/3
			},
			gas_flow = {
				filename = "__base__/graphics/entity/pipe/steam.png",
				priority = "extra-high",
				line_length = 10,
				width = 48,
				height = 30,
				frame_count = 60,
				animation_speed = 0.25,
				scale = 0.5*4/3
			}
		},
		flow_length_in_ticks = 360,
		working_sound = {
			sound = {filename = "__base__/sound/storage-tank.ogg", volume = 0.6, audible_distance_modifier = 0.5},
			match_volume_to_activity = true,
			max_sounds_per_prototype = 3
		},
		circuit_connector = circuit_connector_definitions.create_vector(universal_connector_template, {
			{ variation = 25, main_offset = util.by_pixel(-36.625,  31.5), shadow_offset = util.by_pixel(-36.625,  31.5), show_shadow = true },
			{ variation = 25, main_offset = util.by_pixel(-36.625,  31.5), shadow_offset = util.by_pixel(-36.625,  31.5), show_shadow = true },
			{ variation = 25, main_offset = util.by_pixel(-36.625,  31.5), shadow_offset = util.by_pixel(-36.625,  31.5), show_shadow = true },
			{ variation = 25, main_offset = util.by_pixel(-36.625,  31.5), shadow_offset = util.by_pixel(-36.625,  31.5), show_shadow = true }
		}),
		circuit_wire_max_distance = default_circuit_wire_max_distance,
		water_reflection = {
			pictures =
			{
				filename = "__base__/graphics/entity/storage-tank/storage-tank-reflection.png",
				priority = "extra-high",
				width = 24,
				height = 24,
				shift = util.by_pixel(5*4/3, 35*4/3),
				variation_count = 1,
				scale = 5*4/3
			},
			rotate = false,
			orientation_to_variation = false
		}
	},
	{
		type = "corpse",
		name = "bitlab-altar-remnants",
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
