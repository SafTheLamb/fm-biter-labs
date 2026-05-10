data:extend({
	{
		type = "custom-input",
		name = "biter-labs-open-research-leaderboard",
		key_sequence = "CONTROL + ALT + L",
		consuming = "game-only",
		action = "lua"
	},
	{
		type = "shortcut",
		name = "biter-labs-open-research-leaderboard",
		localised_name = {"shortcut-name.biter-labs-open-research-leaderboard"},
		icon = "__core__/graphics/icons/mip/technology-white.png",
		icon_size = 64,
		order = "f[biter-labs]-a[research-leaderboard]",
		associated_control_input = "biter-labs-open-research-leaderboard",
		action = "lua",
		toggleable = true,
		style = "blue",
		small_icon = "__core__/graphics/icons/mip/technology-white.png",
		small_icon_size = 64,
	}
})
