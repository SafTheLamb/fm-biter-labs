local handler = require("__core__.lualib.event_handler")

local tq_lib = require("scripts.tech-queue-lib")
local altar_lib = require("scripts.science-altar-lib")
local ts_lib = require("scripts.tech-souls-lib")
local tu_lib = require("scripts.tech-ui-lib")

handler.add_lib(tq_lib)
handler.add_lib(altar_lib)
handler.add_lib(ts_lib)
handler.add_lib(tu_lib)

local function on_lab_created(e)
	if e.entity.name == "science-altar" then
		altar_lib.add_altar(e.entity)
	end
end

local function on_lab_destroyed(e)
	if e.entity.name ~= "science-altar" then return end

	if e.cause then
		local altar_data = altar_lib.get_altar_data(e.entity)
		if altar_data then
			local player_altar_data = altar_lib.get_altar_data(e.cause)
			if player_altar_data then
				ts_lib.give_souls_from_kill(player_altar_data, altar_data.souls)
			end
		end
	end
	altar_lib.remove_altar(e.entity)
end

------------------------------------------------------------------------------- Death event

local function on_entity_died(e)
	if not (e.force and e.force.research_enabled) then return end

	if e.entity.type == "lab" then
		on_lab_destroyed(e)
		return
	end

	if not e.force.is_friend(e.entity.force) and e.entity.is_military_target then
		local damage_scale = e.damage_type == "explosion" and 0.5 or 1
		ts_lib.add_souls_from_kill(e.force, e.cause, e.entity, 1)
	end
end

------------------------------------------------------------------------------- Event hooks

script.on_event(defines.events.on_built_entity, on_lab_created, {{filter="type", type="lab"}})
script.on_event(defines.events.on_robot_built_entity, on_lab_created, {{filter="type", type="lab"}})
script.on_event(defines.events.on_space_platform_built_entity, on_lab_created, {{filter="type", type="lab"}})

script.on_event(defines.events.on_player_mined_entity, on_lab_destroyed, {{filter="type", type="lab"}})
script.on_event(defines.events.on_robot_mined_entity, on_lab_destroyed, {{filter="type", type="lab"}})
script.on_event(defines.events.on_space_platform_mined_entity, on_lab_destroyed, {{filter="type", type="lab"}})

script.on_event(defines.events.on_entity_died, on_entity_died, {
	{filter="type", type="unit"},
	{filter="type", type="character"},
	{filter="type", type="unit-spawner"},
	{filter="type", type="turret"},
	{filter="type", type="segmented-unit"},
	{filter="type", type="spider-unit"},
	{filter="type", type="lab"},
	{filter="type", type="combat-robot"},
	{filter="type", type="construction-robot"},
	{filter="type", type="logistic-robot"},
	{filter="type", type="ammo-turret"},
	{filter="type", type="fluid-turret"},
	{filter="type", type="electric-turret"},
	{filter="type", type="artillery-turret"},
	{filter="type", type="car"}
})
