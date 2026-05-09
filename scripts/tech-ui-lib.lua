local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")

local tu_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Leaderboard

function tu_lib.open_tech_leaderboard(player)
	if player.gui.screen["biter-labs-research-leaderboard"] then return end
	local leaderboard = player.gui.screen.add{type="flow", name="biter-labs-research-leaderboard", direction="vertical"}
	leaderboard.style.minimal_width = 0
	leaderboard.style.minimal_height = 0
	leaderboard.style.maximal_width = player.display_resolution.width*0.5
	leaderboard.style.maximal_height = player.display_resolution.height*0.5
	leaderboard.style.horizontal_align = "left"
	leaderboard.style.vertical_align = "top"
	leaderboard.location = {0.1*player.display_resolution.width,0.1*player.display_resolution.height}
	tu_lib.update_tech_leaderboard(player)
	player.set_shortcut_toggled("biter-labs-open-research-leaderboard", true)
end

function tu_lib.close_tech_leaderboard(player)
	assert(player.gui.screen["biter-labs-research-leaderboard"] ~= nil)
	player.gui.screen["biter-labs-research-leaderboard"].destroy()
	player.set_shortcut_toggled("biter-labs-open-research-leaderboard", false)
end

tu_lib.events[defines.events.on_player_created] = function(e)
	local player = game.get_player(e.player_index)
	tu_lib.open_tech_leaderboard(player)
end

------------------------------------------------------------------------------- 

function tu_lib.update_tech_leaderboard(player)
	local leaderboard = player.gui.screen["biter-labs-research-leaderboard"]
	if not leaderboard then return end
	leaderboard.style.minimal_width = 0
	leaderboard.style.minimal_height = 0
	leaderboard.style.maximal_width = player.display_resolution.width*0.5
	leaderboard.style.maximal_height = player.display_resolution.height*0.5
	leaderboard.style.horizontal_align = "left"
	leaderboard.style.vertical_align = "top"
	leaderboard.location = {0.1*player.display_resolution.width,0.1*player.display_resolution.height}
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

tu_lib.events["biter-labs-open-research-leaderboard"] = function(e)
	local player = game.get_player(e.player_index)
	if player.is_shortcut_toggled("biter-labs-open-research-leaderboard") then
		tu_lib.close_tech_leaderboard(player)
	else
		tu_lib.open_tech_leaderboard(player)
	end
end
tu_lib.events[defines.events.on_lua_shortcut] = function(e)
	if e.prototype_name == "biter-labs-open-research-leaderboard" then
		local player = game.get_player(e.player_index)
		if player.is_shortcut_toggled("biter-labs-open-research-leaderboard") then
			tu_lib.close_tech_leaderboard(player)
		else
			tu_lib.open_tech_leaderboard(player)
		end
	end
end

return tu_lib
