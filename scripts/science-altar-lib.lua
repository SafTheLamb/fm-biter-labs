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
	for _,player in pairs(game.forces) do
		storage.science_altars.players[player.index] = {
			souls = 0,
			kills = 0
		}
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
		if altar.player ~= nil then
			return storage.science_altars.players[altar.player.index],1
		end
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
	for _,force in pairs(game.forces) do
		if not force.research_enabled then goto continue end
		local force_altars = storage.science_altars[force.index]

		for _,surface in pairs(game.surfaces) do
			for unit_number,altar_data in pairs(force_altars[surface.index]) do
				local altar = game.get_entity_by_unit_number(unit_number)
				if not altar then
					force_altars[surface.index][unit_number] = nil
					break
				end
				altar_lib.update_altar(altar_data, altar)
			end
		end

		::continue::
	end
end

function altar_lib.update_altar(altar_data, altar)
	local souls_per_blip = tq_lib.get_souls_per_blip(altar.force)
	local blips = altar_data.souls / souls_per_blip
	-- BUG: blips always go towards the lower-ingredient techs... slow down updates to fix

	local tech_id = tq_lib.get_random_tech_index(altar)
	if tech_id then
		local tech_data = tq_lib.get_tech_data(altar.force, tech_id)
		local tech = altar.force.technologies[tech_data.name]
		local tech_blips = 0
		for _,ingredient in pairs(tech.research_unit_ingredients) do
			tech_blips = tech_blips + ingredient.amount
		end
		tech_blips = math.max(tech_blips, 0.01)
		blips = blips * (10*second / tech.research_unit_energy)

		if blips >= tech_blips then
			local unit_amount = blips / tech_blips
			for _,ingredient in pairs(tech.research_unit_ingredients) do
				unit_amount = math.min(unit_amount, altar.get_item_count(ingredient.name) / ingredient.amount)
			end
			unit_amount = math.floor(unit_amount)
			if unit_amount == 0 then return end

			local units_left = math.max(1, (1 - tech.saved_progress) * tech.research_unit_count)
			if unit_amount > units_left then
				unit_amount = math.floor(units_left)
			end

			local kills = altar_data.kills * unit_amount * tech_blips / blips
			tech_data.kills = tech_data.kills + kills
			tq_lib.progress_tech(tech, unit_amount)
			altar_data.kills = altar_data.kills - kills
			altar_data.souls = altar_data.souls - unit_amount * tech_blips * souls_per_blip

			for _,ingredient in pairs(tech.research_unit_ingredients) do
				altar.remove_item({name=ingredient.name, amount=unit_amount * ingredient.amount})
			end
			return true
		end
	end
end

return altar_lib
