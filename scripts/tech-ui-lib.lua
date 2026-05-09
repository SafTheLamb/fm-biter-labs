local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")

local tu_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Leaderboard

function tu_lib.open_tech_leaderboard(player)
	assert(player.gui.goal["biter-labs-tech-leaderboard"] == nil)
	local leaderboard = player.gui.center.add{type="flow", name="biter-labs-tech-leaderboard", direction="vertical"}
	leaderboard.style.width = 0.95 * player.display_resolution.width
	leaderboard.style.height = 0.95 * player.display_resolution.height
	leaderboard.style.horizontal_align = "center"
	leaderboard.style.vertical_align = "top"
	leaderboard.location = {0,0}
	tu_lib.update_tech_leaderboard(player)
end

function tu_lib.close_tech_leaderboard(player)
	assert(player.gui.goal["biter-labs-tech-leaderboard"] ~= nil)
	player.gui.goal["biter-labs-tech-leaderboard"].destroy()
end

tu_lib.events[defines.events.on_player_created] = function(e)
	tu_lib.open_tech_leaderboard(game.get_player(e.player_index))
end

------------------------------------------------------------------------------- 

function tu_lib.update_tech_leaderboard(player)
	local leaderboard = player.gui.center["biter-labs-tech-leaderboard"]
	leaderboard.clear()
	local top_tech_ids = tq_lib.get_top_tech_ids(player.force, 5)
	for i,tech_id in pairs(top_tech_ids) do
		local tech_data = tq_lib.get_tech_data(player.force, tech_id)
		local tech = player.force.technologies[tech_data.name]
		local label = leaderboard.add{type="label", name="tech-"..i, caption={"biter-labs-ui.leaderboard-tech", i, tech_data.name, {"technology-name."..tech_data.name}, math.max(0.1 * math.floor(1000 * tech.saved_progress), 0.1)}}
		label.style.font_color = {0,1,0}
	end
end

tu_lib.on_nth_tick[60] = function(e)
	for _,player in pairs(game.players) do
		tu_lib.update_tech_leaderboard(player)
	end
end

return tu_lib
