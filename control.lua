local handler = require("__core__.lualib.event_handler")

local tq_lib = require("scripts.tech-queue-lib")

handler.add_lib(tq_lib)

------------------------------------------------------------------------------- Researching

local function research_tech(force, tech)
	-- local queue_storage = storage.queued[force.index]
	tech.researched = true
end

local function progress_tech(tech, amount)
	local new_progress = tech.saved_progress + amount

	if new_progress >= 1 then
		tq_lib.research_tech(tech)
		tech.saved_progress = 0
	else
		tech.saved_progress = new_progress
	end
end

local function on_entity_died(e)
	local player_force = e.force
	if player_force and player_force.research_enabled and not player_force.is_friend(e.entity.force) then
		local tech_id = tq_lib.get_random_tech_index(player_force)
		if tech_id then
			local tech = tq_lib.get_tech(player_force, tech_id)
			progress_tech(tech, 1 / tech.research_unit_count)
		end
		--print(#player_force.technologies)
		-- player_force.technologies
	end
end

------------------------------------------------------------------------------- Event hooks

-- script.on_init(on_init)
-- script.on_event(defines.events.on_force_created, on_force_created)

script.on_event(defines.events.on_entity_died, on_entity_died, {{filter="type", type="unit"}})
