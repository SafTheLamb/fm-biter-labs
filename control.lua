local handler = require("__core__.lualib.event_handler")
local utibl = require("scripts.bitlab-util")

local tq_lib = require("scripts.tech-queue-lib")
local altar_lib = require("scripts.science-altar-lib")
local ts_lib = require("scripts.tech-souls-lib")
local tu_lib = require("scripts.tech-ui-lib")

handler.add_lib(tq_lib)
handler.add_lib(altar_lib)
handler.add_lib(ts_lib)
handler.add_lib(tu_lib)

local function on_science_altar_destroyed(e)
	if not e.cause then return end

	local souls = e.entity.get_fluid_count("bitlab-souls")
	if souls > 0 then
		local player_altar_data = altar_lib.get_altar_data(e.cause)
		if player_altar_data then
			player_altar_data:add_souls(souls)
		end
	end
end

------------------------------------------------------------------------------- Death event

local function on_entity_died(e)
	if not (e.force and e.force.research_enabled) then return end

	if e.entity.name == "bitlab-tank" then
		on_science_altar_destroyed(e)
		return
	end

	local soul_scale = 1

	local force_override = false
	-- "Edible" fish give souls
	if e.entity.type == "fish" then
		local fish_scale = prototypes.mod_data["bitlab-fish-with-souls"].data[e.entity.name.."-kill"]
		if fish_scale then
			force_override = true
			soul_scale = fish_scale
			goto continue
		end
	end
	::continue::

	if force_override or (not e.force.is_friend(e.entity.force) and e.entity.is_military_target) then
		local damage_scale = e.damage_type == "explosion" and 0.5 or 1
		ts_lib.add_souls_from_kill(e.force, e.cause, e.entity, damage_scale * soul_scale)
	end
end

------------------------------------------------------------------------------- Event hooks

script.on_event(defines.events.on_entity_died, on_entity_died, {
	{filter="type", type="unit"},
	{filter="type", type="character"},
	{filter="type", type="unit-spawner"},
	{filter="type", type="turret"},
	{filter="type", type="segmented-unit"},
	{filter="type", type="spider-unit"},
	{filter="type", type="storage-tank"},
	{filter="type", type="combat-robot"},
	{filter="type", type="construction-robot"},
	{filter="type", type="logistic-robot"},
	{filter="type", type="ammo-turret"},
	{filter="type", type="fluid-turret"},
	{filter="type", type="electric-turret"},
	{filter="type", type="artillery-turret"},
	{filter="type", type="car"},
	{filter="type", type="fish"}
})

script.on_event(defines.events.on_pre_player_mined_item, function(e)
	altar_lib.on_pre_mined_tank(e.entity, game.get_player(e.player_index), defines.inventory.character_main)
end, {{filter="name", name="bitlab-tank"}})
script.on_event(defines.events.on_robot_pre_mined, function(e)
	altar_lib.on_pre_mined_tank(e.entity, e.robot, defines.inventory.robot_cargo)
end, {{filter="name", name="bitlab-tank"}})
script.on_event(defines.events.on_space_platform_pre_mined, function(e)
	altar_lib.on_pre_mined_tank(e.entity, e.platform.hub, defines.inventory.hub_main)
end, {{filter="name", name="bitlab-tank"}})
