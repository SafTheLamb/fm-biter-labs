local altar_lib = require("__biter-labs__.scripts.science-altar-lib")

local ts_lib = {
	events = {}
}

------------------------------------------------------------------------------- Death

function ts_lib.give_souls_from_kill(altar_data, souls)
	altar_data.souls = altar_data.souls + souls
	altar_data.kills = altar_data.kills + 1
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

	local souls = entity.max_health ^ 0.75
	if altar and altar_data then
		local offset = {
			x = 1.5 - 3 * math.random(),
			y = 1.5 - 3 * math.random()
		}
		altar.surface.create_particle{
			name = "soul-collecting",
			position = {altar.position.x + offset.x, altar.position.y + offset.y},
			height = 2,
			movement = {-offset.x * 0.05, -offset.y * 0.05},
			vertical_speed = 0,
			frame_speed = 0.8 + math.random()
		}
		ts_lib.give_souls_from_kill(altar_data, souls * damage_scale * altar_scale)
	end
end

return ts_lib
