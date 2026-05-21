local hit_effects = require("__base__.prototypes.entity.hit-effects")
local item_sounds = require("__base__.prototypes.item_sounds")
local sounds = require("__base__.prototypes.entity.sounds")

local magazine_ingredient = "firearm-magazine"
-- if mods["wood-military"] and settings.startup["wood-military-smg-ammo"].value then
-- 	magazine_ingredient = "wood-darts-magazine"
-- end

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
			{type="item", name=magazine_ingredient, amount=5}
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
			{inventory_index = defines.inventory.lab_modules, shift = {0, 0.9}},
			{inventory_index = defines.inventory.lab_input, shift = {0, 0}, max_icons_per_row = 4, separation_multiplier = 1/1.1}
		},
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
		selection_box = {{-2, 1}, {2, 2}},
		icon_draw_specification = {scale=0},
		fluid_box = {
			volume = 25000,
			filter = "bitlab-souls",
			pipe_picture = assembler2pipepictures(),
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
		window_bounding_box = {{-0.125, 0.6875}, {0.1875, 1.1875}},
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
				layers = {
					{
						filename = "__biter-labs__/graphics/entity/science-altar/science-altar.png",
						width = 196,
						height = 219,
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
				height = 15
			},
			window_background = {
				filename = "__base__/graphics/entity/storage-tank/window-background.png",
				priority = "extra-high",
				width = 34,
				height = 48,
				scale = 0.5
			},
			flow_sprite = {
				filename = "__base__/graphics/entity/pipe/fluid-flow-low-temperature.png",
				priority = "extra-high",
				width = 160,
				height = 20
			},
			gas_flow = {
				filename = "__base__/graphics/entity/pipe/steam.png",
				priority = "extra-high",
				line_length = 10,
				width = 48,
				height = 30,
				frame_count = 60,
				animation_speed = 0.25,
				scale = 0.5
			}
		},
		flow_length_in_ticks = 360,
		working_sound = {
			sound = {filename = "__base__/sound/storage-tank.ogg", volume = 0.6, audible_distance_modifier = 0.5},
			match_volume_to_activity = true,
			max_sounds_per_prototype = 3
		},
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
