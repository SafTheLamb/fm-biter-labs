local util = require("__core__.lualib.util")
local utibl = require("__biter-labs__.scripts.bitlab-util")

local altar_lib = require("__biter-labs__.scripts.science-altar-lib")
local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")

local ts_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Death

function ts_lib.give_souls_from_kill(altar_data, souls)
	altar_data.souls = altar_data.souls + souls
	altar_data.kills = altar_data.kills + 1
end

function ts_lib.get_soul_value(entity)
	local altar_data = altar_lib.get_altar_data(entity)
	if altar_data then
		return math.max(altar_data.souls, 0)
	elseif entity.max_health > 0 then
		return math.max(entity.max_health, 0) ^ 0.9
	end
	return 0
end

function ts_lib.spawn_souls_leaving(entity, count)
	count = math.min(count, 1000)
	for i=1,count do
		entity.surface.create_particle{
			name = "soul-leaving",
			position = entity.position,
			height = 1,
			movement = {
				0.1 - 0.2 * math.random(),
				0
			},
			vertical_speed = 0.1,
			frame_speed = 0.8 + math.random()
		}
	end
end

function ts_lib.spawn_souls_collecting(entity, count)
	count = math.min(count, 1000)
	for i=1,count do
		local offset = {
			x = 1.5 - 3 * math.random(),
			y = 1.5 - 3 * math.random()
		}
		entity.surface.create_particle{
			name = "soul-collecting",
			position = {entity.position.x + offset.x, entity.position.y + offset.y},
			height = 2,
			movement = {-offset.x * 0.05, -offset.y * 0.05},
			vertical_speed = 0,
			frame_speed = 0.8 + math.random()
		}
	end
end

-- Add souls to force
function ts_lib.add_souls_from_kill(force, killer, entity, damage_scale)
	local altar_data,altar_scale = altar_lib.get_altar_data(killer)
	local altar = killer
	if not altar_data then
		local altars = entity.surface.find_entities_filtered{force=force, position=(killer or entity).position, radius=32, type="lab", name="science-altar"}
		if next(altars) then
			altar = altars[math.random(#altars)]
			altar_data = altar_lib.get_altar_data(altar)
		end
	end

	local souls = ts_lib.get_soul_value(entity)
	local num_particles = math.max(math.sqrt(math.max(souls / tq_lib.get_souls_per_blip(force), 0)), 1)
	ts_lib.spawn_souls_leaving(entity, num_particles)

	if altar and altar_data then
		ts_lib.give_souls_from_kill(altar_data, souls * damage_scale * altar_scale)
		ts_lib.spawn_souls_collecting(altar, num_particles)
	end
end

ts_lib.events[defines.events.on_script_trigger_effect] = function(e)
	local event_prefix = "bitlab-fish-eaten-"
	if util.string_starts_with(e.effect_id, event_prefix) then
		local fish_name = string.sub(e.effect_id, #event_prefix + 1)
		local altar = e.target_entity
		local altar_data = altar and altar_lib.get_altar_data(altar)
		if altar_data then
			local souls = prototypes.mod_data["bitlab-fish-with-souls"].data[fish_name.."-eat"]
			ts_lib.give_souls_from_kill(altar_data, souls)
			ts_lib.spawn_souls_collecting(altar, 1)
		end
	end
end

------------------------------------------------------------------------------- Player souls

ts_lib.on_nth_tick[6] = function(e)
	for _,player in pairs(game.players) do
		local player_altar_data = storage.science_altars.players[player.index]
		if player.character and player_altar_data.souls > 0 then
			local altars = player.character.surface.find_entities_filtered{force=player.force, position=player.character.position, radius=32, type="lab", name="science-altar"}
			if next(altars) then
				local altar = altars[math.random(#altars)]
				local altar_data = altar_lib.get_altar_data(altar)
				local soul_transfer = math.min(player_altar_data.souls, math.sqrt(math.max(player_altar_data.souls, 0)))
				local num_particles = math.max(math.sqrt(soul_transfer / tq_lib.get_souls_per_blip(player.force)), 1)
				local kill_transfer = player_altar_data.kills * soul_transfer / player_altar_data.souls

				player_altar_data.souls = math.max(player_altar_data.souls - soul_transfer, 0)
				player_altar_data.kills = math.max(player_altar_data.kills - kill_transfer, 0)
				ts_lib.spawn_souls_leaving(player, num_particles)

				altar_data.souls = altar_data.souls + soul_transfer
				altar_data.kills = altar_data.kills + kill_transfer
				ts_lib.spawn_souls_collecting(altar, num_particles)
			end
		end
	end
end

commands.add_command("bitlab-reset-player-souls", {"biter-labs-ui.reset-player-souls-help"}, function(e)
	local player = game.get_player(e.player_index)
	if player and not player.admin then
		player.print({"biter-labs-ui.command-admin"})
		return
	end
	if e.parameter == "confirm" then
		if player then
			utibl.print(player, {"biter-labs-ui.reset-player-souls-warning"})
		end
		return
	elseif e.parameter == "CONFIRM!" then
		for _,player in pairs(game.players) do
			altar_lib.init_player(player)
		end
		game.print({"biter-labs-ui.reset-player-souls-confirmed"})
		return
	end
	utibl.print(player, {"biter-labs-ui.command-error", e.name})
end)

return ts_lib
