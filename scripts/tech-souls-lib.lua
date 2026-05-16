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
		return altar_data.souls
	else
		return entity.max_health ^ 0.9
	end
end

function ts_lib.spawn_souls_leaving(entity, count)
	for i=1,count do
		entity.surface.create_particle{
			name = "soul-leaving",
			position = entity.position,
			height = 0,
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
	local altar_data,altar_scale = killer and altar_lib.get_altar_data(killer) or nil,1
	local altar = killer
	if not altar_data then
		local altars = entity.surface.find_entities_filtered{force=force, position=(killer or entity).position, radius=32, type="lab", name="science-altar"}
		if next(altars) then
			altar = altars[math.random(#altars)]
			altar_data = altar_lib.get_altar_data(altar)
		end
	end

	local souls = ts_lib.get_soul_value(entity)
	local num_particles = math.max(math.sqrt(souls / tq_lib.get_souls_per_blip(force)), 1)
	ts_lib.spawn_souls_leaving(entity, num_particles)

	if altar and altar_data then
		ts_lib.give_souls_from_kill(altar_data, souls * damage_scale * altar_scale)
		ts_lib.spawn_souls_collecting(altar, num_particles)
	end
end

ts_lib.on_nth_tick[6] = function(e)
	for _,player in pairs(game.players) do
		local player_altar_data = storage.science_altars.players[player.index]
		if player.character and player_altar_data.souls > 0 then
			local altars = player.character.surface.find_entities_filtered{force=player.force, position=player.character.position, radius=32, type="lab", name="science-altar"}
			if next(altars) then
				local altar = altars[math.random(#altars)]
				local altar_data = altar_lib.get_altar_data(altar)
				local soul_transfer = math.max(math.min(1, player_altar_data.souls), math.sqrt(player_altar_data.souls))
				local num_particles = math.max(math.sqrt(soul_transfer / tq_lib.get_souls_per_blip(player.force)), 1)

				player_altar_data.souls = player_altar_data.souls - soul_transfer
				ts_lib.spawn_souls_leaving(player, num_particles)

				altar_data.souls = altar_data.souls + soul_transfer
				ts_lib.spawn_souls_collecting(altar, num_particles)
			end
		end
	end
end

return ts_lib
