local handler = require("__core__.lualib.event_handler")

local tq_lib = require("scripts.tech-queue-lib")
local altar_lib = require("scripts.science-altar-lib")

handler.add_lib(tq_lib)
handler.add_lib(altar_lib)

local function on_lab_created(e)
	if e.entity.name ~= "science-altar" then return end
end

local function on_lab_destroyed(e)
	if e.entity.name ~= "science-altar" then return end

	if e.entity.force ~= e.force then
		if e.cause and e.cause.type == "character" then
			-- TODO: Give the killing player the stored souls
		end

	end
end

------------------------------------------------------------------------------- Death event

local function on_entity_died(e)
	local player_force = e.force
	if not (player_force and player_force.research_enabled) then return end

	if e.entity.type == "lab" then
		on_lab_destroyed(e)
		return
	end

	if not player_force.is_friend(e.entity.force) then
		local tech_id = tq_lib.get_random_tech_index(player_force)
		if tech_id then
			local tech = tq_lib.get_tech(player_force, tech_id)
			tq_lib.progress_tech(tech, 1 / tech.research_unit_count)
		end
		return
	end
end

------------------------------------------------------------------------------- Event hooks

-- script.on_init(on_init)
-- script.on_event(defines.events.on_force_created, on_force_created)

script.on_event(defines.events.on_built_entity, on_lab_created, {{filter="type", type="lab"}})
script.on_event(defines.events.on_robot_built_entity, on_lab_created, {{filter="type", type="lab"}})
script.on_event(defines.events.on_space_platform_built_entity, on_lab_created, {{filter="type", type="lab"}})

script.on_event(defines.events.on_player_mined_entity, on_lab_destroyed, {{filter="type", type="lab"}})
script.on_event(defines.events.on_robot_mined_entity, on_lab_destroyed, {{filter="type", type="lab"}})
script.on_event(defines.events.on_space_platform_mined_entity, on_lab_destroyed, {{filter="type", type="lab"}})

script.on_event(defines.events.on_entity_died, on_entity_died, {
	{filter="type", type="unit"},
	{filter="type", type="unit-spawner"},
	{filter="type", type="segmented-unit"},
	{filter="type", type="spider-unit"},
	{filter="type", type="turret"},
	{filter="type", type="lab"},
})
