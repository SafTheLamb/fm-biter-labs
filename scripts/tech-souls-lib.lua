local altar_lib = require("__biter-labs__.scripts.science-altar-lib")

local ts_lib = {
	events = {}
}

------------------------------------------------------------------------------- Initialization

-- ts_lib.on_init = function()
-- 	storage.tech_souls = {}
-- 	for _,force in pairs(game.forces) do
-- 		ts_lib.init_force(force)
-- 	end
-- end

-- function ts_lib.init_force(force)
-- 	storage.tech_souls[force.index] = {
-- 		total_science = 0,
-- 		science_scale = 1
-- 	}
-- end

-- ts_lib.events[defines.events.on_force_created] = function(e)
-- 	ts_lib.init_force(e.force)
-- end

------------------------------------------------------------------------------- Death

function ts_lib.give_souls_from_kill(altar_data, souls)
	altar_data.souls = altar_data.souls + souls
	altar_data.kills = altar_data.kills + 1
end

-- Add souls to force
function ts_lib.add_souls_from_kill(force, killer, entity, damage_scale)
	local altar_data,altar_scale = killer and altar_lib.get_altar_data(killer) or nil,1
	if not altar_data then
		local altars = entity.surface.find_entities_filtered{force=force, position=entity.position, radius=32, type="lab", name="science-altar"}
		if next(altars) then
			local altar = altars[math.random(#altars)]
			altar_data = altar_lib.get_altar_data(altar)
		end
	end
	if altar_data then
		local souls = math.sqrt(entity.max_health)
		ts_lib.give_souls_from_kill(altar_data, souls * damage_scale * altar_scale)
	end
end

return ts_lib
