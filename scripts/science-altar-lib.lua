local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")

local altar_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Forces

altar_lib.on_init = function()
	storage.science_altars = {
		players = {}
	}
	for _,force in pairs(game.forces) do
		altar_lib.init_force(force)
	end
end

function altar_lib.init_force(force)
	storage.science_altars[force.index] = {}
	for _,surface in pairs(game.surfaces) do
		altar_lib.init_surface(force, surface)
	end
end

altar_lib.events[defines.events.on_force_created] = function(e)
	altar_lib.init_force(e.force)
end

------------------------------------------------------------------------------- Surfaces

function altar_lib.init_surface(force, surface)
	local altar_storage = storage.science_altars[force.index]
	altar_storage[surface.index] = {}
	local altars = surface.find_entities_filtered({force=force, type="lab", name="science-altar"})
	for _,altar in pairs(altars or {}) do
		altar_lib.add_altar(altar)
	end
end


altar_lib.events[defines.events.on_surface_created] = function(e)
	local surface = game.get_surface(e.surface_index)
	for _,force in pairs(game.forces) do
		altar_lib.init_surface(force, surface)
	end
end

altar_lib.events[defines.events.on_surface_imported] = function(e)
	local surface = game.get_surface(e.surface_index)
	for _,force in pairs(game.forces) do
		altar_lib.init_surface(force, surface)
	end
end

altar_lib.events[defines.events.on_surface_cleared] = function(e)
	local surface = game.get_surface(e.surface_index)
	for _,force in pairs(game.forces) do
		altar_lib.init_surface(force, surface)
	end
end

altar_lib.events[defines.events.on_surface_deleted] = function(e)
	for _,force in pairs(game.forces) do
		storage.science_altars[force.index][e.surface_index] = nil
	end
end

------------------------------------------------------------------------------- Players

altar_lib.events[defines.events.on_player_created] = function(e)
	storage.science_altars.players[e.player_index] = {
		souls = 0,
		kills = 0
	}
end

altar_lib.events[defines.events.on_player_died] = function(e)
	storage.science_altars.players[e.player_index].souls = 0
end

------------------------------------------------------------------------------- Altar data

-- returns: altar_data (can be null), altar_scale (null if altar is lab)
function altar_lib.get_altar_data(altar)
	if altar.type == "lab" then
		return storage.science_altars[altar.force.index][altar.surface.index][altar.unit_number]
	elseif altar.type == "character" then
		return storage.science_altars.players[altar.player.index],1
	elseif altar.type == "car" or altar.type == "spider-vehicle" then
		-- Use the driver if the gunner is automatic (idk if that's possible but who cares)
		local killer = not altar.driver_is_gunner and altar.get_passenger() or altar.get_driver()
		-- only give souls to players physically inside the vehicle
		if not killer or killer.is_player() or killer.type ~= "character" then
			return nil
		end
		return storage.science_altars.players[killer.player.index],0.5
	end
end

function altar_lib.add_altar(altar)
	local altar_storage = storage.science_altars[altar.force.index][altar.surface.index]
	altar_storage[altar.unit_number] = {
		souls = 0,
		kills = 0
	}
end

function altar_lib.remove_altar(altar)
	local altar_storage = storage.science_altars[altar.force.index][altar.surface.index]
	altar_storage[altar.unit_number] = nil
end

------------------------------------------------------------------------------- Updating

altar_lib.on_nth_tick[60] = function(e)
	for _,player in pairs(game.players) do
		if player.character then
			altar_lib.update_altar(storage.science_altars.players[player.index], player.character)
		end
	end

	for _,force in pairs(game.forces) do
		if not force.research_enabled then goto continue end
		local force_altars = storage.science_altars[force.index]

		for _,surface in pairs(game.surfaces) do
			for unit_number,altar_data in pairs(force_altars[surface.index]) do
				altar_lib.update_altar(altar_data, game.get_entity_by_unit_number(unit_number))
			end
		end

		::continue::
	end
end

function altar_lib.update_altar(altar_data, altar)
	local souls_per_blip = tq_lib.get_souls_per_blip(altar.force)
	local blips = altar_data.souls / souls_per_blip
	-- BUG: blips always go towards the lower-ingredient techs... slow down updates to fix
	if blips > 0 then
		local tech_id = tq_lib.get_random_tech_index(altar)
		if tech_id then
			local tech = tq_lib.get_tech(altar.force, tech_id)
			local tech_blips = #tech.research_unit_ingredients
			if blips >= tech_blips then
				-- TODO: track kills?
				tq_lib.progress_tech(tech, 1 / tech.research_unit_count, 0)
				for _,ingredient in pairs(tech.research_unit_ingredients) do
					-- BUG: blip cost does not account for ingredients with >1... it's used very rarely anyway
					altar.remove_item({name=ingredient.name, amount=1})
				end
				altar_data.souls = altar_data.souls - tech_blips * souls_per_blip
			end
		end
	end
end

return altar_lib
