local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")
local ts_lib = require("__biter-labs__.scripts.tech-souls-lib")

local tu_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Initialization

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

------------------------------------------------------------------------------- Leaderboard 

function tu_lib.get_tech_name(tech)
	if tech.localised_name then
		return tech.localised_name
	end
	local tokens = util.split(tech.name, '-')
	if tonumber(tokens[#tokens], 10) then
		local tech_name = tokens[1]
		for i=2,#tokens-1 do
			tech_name = tech_name..'-'..tokens[i]
		end
		return {"", {"technology-name."..tech_name}, " "..tokens[#tokens]}
	end
	return {"technology-name."..tech.name}
end

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
		local tech_name = tu_lib.get_tech_name(tech)
		local label = leaderboard.add{type="label", name="tech-"..i, caption={"biter-labs-ui.leaderboard-tech", i, tech_data.name, tech_name, math.max(0.1 * math.floor(1000 * tech.saved_progress), 0.1)}}
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

------------------------------------------------------------------------------- Soul scouter

function tu_lib.scout_souls(e)
	if not next(e.entities) then return end
	local player = game.get_player(e.player_index)
	if not player.force.technologies["biter-labs-soul-scouter"].researched then return end

	local souls = 0
	for _,entity in pairs(e.entities) do
		souls = souls + ts_lib.get_soul_value(entity)
	end

	player.print({"biter-labs-ui.soul-scouter-reading", #e.entities, math.floor(souls)},
		{color={1,0,1}, sound=defines.print_sound.never, skip=defines.print_skip.never, game_state=false})
end

function tu_lib.on_player_selected_area(e)
	if e.item == "biter-labs-soul-scouter" then
		tu_lib.scout_souls(e)
	end
end

tu_lib.events[defines.events.on_player_selected_area] = tu_lib.on_player_selected_area
tu_lib.events[defines.events.on_player_alt_selected_area] = tu_lib.on_player_selected_area
tu_lib.events[defines.events.on_player_reverse_selected_area] = tu_lib.on_player_selected_area
tu_lib.events[defines.events.on_player_alt_reverse_selected_area] = tu_lib.on_player_selected_area

tu_lib.events[defines.events.on_player_cursor_stack_changed] = function(e)
	local player = game.get_player(e.player_index)
	if not player.force.technologies["biter-labs-soul-scouter"].researched then
		if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "biter-labs-soul-scouter" then
			player.cursor_stack.clear()
		end
	end
end

return tu_lib
