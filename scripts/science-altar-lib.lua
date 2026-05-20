local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")

local altar_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Forces

altar_lib.on_init = function()
	storage.science_altars = {}
	storage.player_souls = {}
	for _,force in pairs(game.forces) do
		altar_lib.init_force(force)
	end
	for _,player in pairs(game.players) do
		altar_lib.init_player(player)
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

function altar_lib.init_player(player)
	assert(player)
	assert(not storage.player_souls[player.index])
	storage.player_souls[player.index] = {
		souls = 0
	}
end

altar_lib.events[defines.events.on_player_created] = function(e)
	altar_lib.init_player(game.get_player(e.player_index))
end

altar_lib.events[defines.events.on_player_died] = function(e)
	local soul_storage = storage.player_souls[e.player_index]
	soul_storage.souls = 0
end

------------------------------------------------------------------------------- Altar data

local function get_souls_from_altar(self)
	local altar_storage = storage.science_altars[self.altar.force.index][self.altar.surface.index]
	local storage_tank = game.get_entity_by_unit_number(altar_storage.altars[self.altar.unit_number].storage_tank)
	return storage_tank.get_fluid_count("bitlab-souls")
end

local function add_souls_to_altar(self, amount)
	local altar_storage = storage.science_altars[self.altar.force.index][self.altar.surface.index]
	local storage_tank = game.get_entity_by_unit_number(altar_storage.altars[self.altar.unit_number].storage_tank)
	if amount > 0 then
		return storage_tank.insert_fluid({name="bitlab-souls", amount=amount * (self.scalar or 1)})
	else
		return storage_tank.remove_fluid{name="bitlab-souls", amount=amount}
	end
end

local function get_souls_from_player(self)
	local player_storage = storage.player_souls[self.player_index]
	return player_storage.souls
end

local function add_souls_to_player(self, amount)
	local player_storage = storage.player_souls[self.player_index]
	local old_souls = player_storage.souls
	player_storage.souls = math.max(0, player_storage.souls + amount * (amount > 0 and self.scalar or 1))
	return (player_storage.souls - old_souls)
end

-- returns: {:get_souls() -> amount, :add_souls(amount) -> actual_amount}
function altar_lib.get_altar_data(altar)
	if altar then
		if altar.type == "lab" then
			-- return storage.science_altars[altar.force.index][altar.surface.index][altar.unit_number],1
			return {
				altar = altar,
				get_souls = get_souls_from_altar,
				add_souls = add_souls_to_altar
			}
		elseif altar.type == "character" then
			if altar.player ~= nil then
				return {
					player_index = altar.player.index,
					get_souls = get_souls_from_player,
					add_souls = add_souls_to_player
				}
			end
		elseif altar.type == "car" or altar.type == "spider-vehicle" then
			-- Use the driver if the gunner is automatic (idk if that's possible but who cares)
			local killer = not altar.driver_is_gunner and altar.get_passenger() or altar.get_driver()
			-- only give souls to players physically inside the vehicle
			if not killer or killer.is_player() or killer.type ~= "character" then
				return nil
			end
			return {
				player_index = killer.player.index,
				get_souls = get_souls_from_player,
				add_souls = add_souls_to_player,
				scalar = 0.5
			}
		end
	end
	return nil
end

function altar_lib.add_altar(altar, storage_tank)
	local altar_storage = storage.science_altars[altar.force.index][altar.surface.index]
	altar_storage.altars[altar.unit_number] = {
		storage_tank = storage_tank.unit_number
	}
	altar_storage.storage_tanks[storage_tank.unit_number] = {
		altar = altar.unit_number
	}
end

altar_lib.events[defines.events.on_script_trigger_effect] = function(e)
	if e.effect_id == "bitlab-science-altar-created" then
		-- The event is actually triggered by the 
		local surface = game.get_surface(e.surface_index)
		local altar = surface.create_entity{
			name = "science-altar",
			position = e.source_entity.position,
			force = e.source_entity.force,
			player = e.source_entity.last_user
		}
		altar_lib.add_altar(altar, e.entity)
		script.register_on_object_destroyed(e.source_entity)
		script.register_on_object_destroyed(altar)
	end
end

function altar_lib.remove_altar(altar)
	local altar_storage = storage.science_altars[altar.force.index][altar.surface.index]
	altar_storage[altar.unit_number] = nil
end

altar_lib.events[defines.events.on_object_destroyed] = function(e)
	if e.type ~= defines.target_type.entity then return end
	local entity = game.get_entity_by_unit_number(e.useful_id)
	if entity.name == "science-altar" then
		altar_lib.remove_altar(entity)
		local storage_tank = entity.surface.find_entity("science-altar-storage-tank")
		storage_tank.destroy()
	elseif entity.name == "science-altar-storage-tank" then
		local altar = entity.surface.find_entity("science-altar", entity.position)
		altar_lib.remove_altar(altar)
		altar.destroy()
	end
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
	local blips = altar_data:get_souls() / souls_per_blip
	-- BUG: blips always go towards the lower-ingredient techs... slow down updates as a bandaid

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

			local souls_used = -altar_data:add_souls(-unit_amount * tech_blips * souls_per_blip)
			tq_lib.progress_tech(tech, unit_amount)
			tech_data.souls = tech_data.souls + souls_used

			for _,ingredient in pairs(tech.research_unit_ingredients) do
				altar.remove_item({name=ingredient.name, amount=unit_amount * ingredient.amount})
			end
			return true
		end
	end
end

return altar_lib
