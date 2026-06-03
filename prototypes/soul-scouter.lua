data:extend({
	{
		type = "selection-tool",
		name = "bitlab-soul-scouter",
		icon = "__biter-labs__/graphics/icons/soul-scouter.png",
		icon_size = 64,
		flags = {"only-in-cursor", "not-stackable", "spawnable"},
		subgroup = "tool",
		stack_size = 1,
		select = {
			border_color = {1, 0, 1},
			cursor_box_type = "entity",
			mode = {"enemy", "entity-with-health"},
			ended_sound = "__core__/sound/smart-pipette.ogg"
		},
		alt_select = {
			border_color = {1, 0, 1},
			cursor_box_type = "entity",
			mode = {"friend", "entity-with-health"},
			entity_filter_mode = "whitelist",
			entity_filters = {"character", "bitlab-tank"},
			ended_sound = "__core__/sound/smart-pipette.ogg"
		},
		open_sound = {filename="__base__/sound/item-open.ogg", volume=1},
		close_sound = {filename="__base__/sound/item-close.ogg", volume=1}
	},
	{
		type = "custom-input",
		name = "bitlab-give-soul-scouter",
		localised_name = {"shortcut-name.bitlab-give-soul-scouter"},
		key_sequence = "ALT + L",
		consuming = "game-only",
		item_to_spawn = "bitlab-soul-scouter",
		action = "spawn-item",
	},
	{
		type = "shortcut",
		name = "bitlab-give-soul-scouter",
		icon = "__biter-labs__/graphics/icons/soul-scouter.png",
		icon_size = 64,
		action = "spawn-item",
		technology_to_unlock = "bitlab-soul-scouter",
		unavailable_until_unlocked = true,
		associated_control_input = "bitlab-give-soul-scouter",
		item_to_spawn = "bitlab-soul-scouter",
		style = "red",
		small_icon = "__biter-labs__/graphics/icons/soul-scouter.png",
		small_icon_size = 64
	},
	{
		type = "technology",
		name = "bitlab-soul-scouter",
		icon = "__biter-labs__/graphics/technology/soul-scouter.png",
		icon_size = 256,
		prerequisites = {"stone-wall", "gun-turret"},
		unit = {
			ingredients = {
				{"automation-science-pack", 1},
			},
			count = 100,
			time = 10,
		}
	}
})

local soul_scouter = data.raw["selection-tool"]["bitlab-soul-scouter"]
soul_scouter.reverse_select = soul_scouter.alt_select
soul_scouter.alt_reverse_select = soul_scouter.select
