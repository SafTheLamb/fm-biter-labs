local tq_lib = require("__biter-labs__.scripts.tech-queue-lib")

local altar_lib = {
	events = {},
	on_nth_tick = {}
}

------------------------------------------------------------------------------- Initialization

altar_lib.on_init = function()
	storage.science_altars = {}
	storage.altar_objects = {}
	storage.player_souls = {}
	for _,player in pairs(game.players) do
		altar_lib.init_player(player)
	end
end

-- migrations
altar_lib.on_configuration_changed = function(e)
	if e.mod_changes["biter-labs"] and helpers.compare_versions(e.mod_changes["biter-labs"].old_version, "0.3.0") < 0 then
		local old_altar_storage = storage.science_altars
		storage.science_altars = {}
		storage.altar_objects = {}
		storage.player_souls = {}

		for player_id,player_data in pairs(old_altar_storage.players) do
			storage.player_souls[player_id] = {
				souls = player_data.souls
			}
		end

		for _,surface in pairs(game.surfaces) do
			altar_lib.init_surface(surface)
			local altars = surface.find_entities_filtered({type="lab", name="bitlab-altar"})
			for _,altar in pairs(altars) do
				local altar_data = altar_lib.get_altar_data(altar)
				local old_altar_data = old_altar_storage[altar.force.index]
					and old_altar_storage[altar.force.index][altar.surface.index]
					and old_altar_storage[altar.force.index][altar.surface.index][altar.unit_number] or nil
				if altar_data and old_altar_data then
					altar_data:add_souls(old_altar_data.souls)
				end
			end
		end
	end
end

------------------------------------------------------------------------------- Surfaces

function altar_lib.init_surface(surface)
	local altars = surface.find_entities_filtered({type="lab", name="bitlab-altar"})
	for _,altar in pairs(altars) do
		local tank = surface.find_entity("bitlab-tank", altar.position)
		if not tank then
			tank = surface.create_entity{
				name = "bitlab-tank",
				position = altar.position,
				player = altar.last_user,
				force = altar.force,
				quality = altar.quality
			}
		end
		altar.destructible = false
		storage.science_altars[altar.unit_number] = {tank_id = tank.unit_number}
		storage.altar_objects[altar.unit_number] = {tank_id = tank.unit_number}
		storage.altar_objects[tank.unit_number] = {altar_id = altar.unit_number}
	end
	local tanks = surface.find_entities_filtered({type="storage-tank", name="bitlab-tank"})
	for _,tank in pairs(tanks) do
		assert(storage.altar_objects[tank.unit_number])
	end
end

altar_lib.events[defines.events.on_surface_created] = function(e)
	local surface = game.get_surface(e.surface_index)
	altar_lib.init_surface(surface)
end

altar_lib.events[defines.events.on_surface_imported] = function(e)
	local surface = game.get_surface(e.surface_index)
	altar_lib.init_surface(surface)
end

function altar_lib.cleanup_surface(surface)
	local altars = surface.find_entities_filtered({type="lab", name="bitlab-altar"})
	for _,altar in pairs(altars) do
		storage.science_altars[altar.unit_number] = nil
		storage.altar_objects[altar.unit_number] = nil
	end
	local tanks = surface.find_entities_filtered({type="storage-tank", name="bitlab-tank"})
	for _,tank in pairs(tanks) do
		storage.altar_objects[tank.unit_number] = nil
	end
end

altar_lib.events[defines.events.on_pre_surface_cleared] = function(e)
	local surface = game.get_surface(e.surface_index)
	altar_lib.cleanup_surface(surface)
end

altar_lib.events[defines.events.on_pre_surface_deleted] = function(e)
	local surface = game.get_surface(e.surface_index)
	altar_lib.cleanup_surface(surface)
end

------------------------------------------------------------------------------- Players

function altar_lib.init_player(player)
	assert(player)
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

local function get_souls_from_tank(self)
	local tank = game.get_entity_by_unit_number(self.tank_id)
	return tank.get_fluid_count("bitlab-souls")
end

local function add_souls_to_tank(self, amount)
	local tank = game.get_entity_by_unit_number(self.tank_id)
	if amount >= 1 then
		return tank.insert_fluid({name="bitlab-souls", amount=amount * (self.scalar or 1)})
	elseif amount <= -1 then
		return -tank.remove_fluid{name="bitlab-souls", amount=-amount}
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

-- returns: {:get_souls() -> amount, :add_souls(amount) -> added_amount}
function altar_lib.get_altar_data(entity)
	if entity then
		if entity.name == "bitlab-tank" then
			return {
				tank_id = entity.unit_number,
				get_souls = get_souls_from_tank,
				add_souls = add_souls_to_tank
			}
		elseif entity.name == "bitlab-altar" then
			return {
				tank_id = storage.altar_objects[entity.unit_number].tank_id,
				get_souls = get_souls_from_tank,
				add_souls = add_souls_to_tank
			}
		elseif entity.type == "character" then
			if entity.player ~= nil then
				return {
					player_index = entity.player.index,
					get_souls = get_souls_from_player,
					add_souls = add_souls_to_player
				}
			end
		elseif entity.type == "car" or entity.type == "spider-vehicle" then
			-- Use the driver if the gunner is automatic (idk if that's possible but who cares)
			local killer = not entity.driver_is_gunner and entity.get_passenger() or entity.get_driver()
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

altar_lib.events[defines.events.on_script_trigger_effect] = function(e)
	-- The event is handled by the souls tank since it's the entity with collision
	if e.effect_id == "bitlab-tank-created" then
		-- Make sure this wasn't spawned due to a legacy science altar
		local surface = game.get_surface(e.surface_index)
		local altar = surface.find_entity("bitlab-altar", e.source_entity.position)
		if not altar then
			altar = surface.create_entity{
				name = "bitlab-altar",
				position = e.source_entity.position,
				force = e.source_entity.force,
				player = e.source_entity.last_user,
				quality = e.source_entity.quality
			}
		end
		altar.destructible = false
		storage.altar_objects[e.source_entity.unit_number] = {altar_id=altar.unit_number}
		storage.altar_objects[altar.unit_number] = {tank_id=e.source_entity.unit_number}
		storage.science_altars[altar.unit_number] = {tank_id=e.source_entity.unit_number}

		assert(surface.find_entity("bitlab-tank", altar.position))
		assert(surface.find_entity("bitlab-altar", altar.position))

		script.register_on_object_destroyed(e.source_entity)
		script.register_on_object_destroyed(altar)
	end
end

altar_lib.events[defines.events.on_object_destroyed] = function(e)
	if e.type ~= defines.target_type.entity then return end
	local object_data = storage.altar_objects[e.useful_id]
	if object_data then
		if object_data.altar_id then
			local altar = game.get_entity_by_unit_number(object_data.altar_id)
			if altar then altar.destroy() end
			storage.altar_objects[object_data.altar_id] = nil
			storage.science_altars[object_data.altar_id] = nil
		elseif object_data.tank_id then
			local tank = game.get_entity_by_unit_number(object_data.tank_id)
			if tank then
				tank.destroy()
			end
			storage.altar_objects[object_data.tank_id] = nil
			storage.science_altars[e.useful_id] = nil
		end
	end
	storage.altar_objects[e.useful_id] = nil
end

------------------------------------------------------------------------------- Updating

function altar_lib.update_altar(altar, altar_data)
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

altar_lib.on_nth_tick[60] = function(e)
	for altar_id,altar_metadata in pairs(storage.science_altars) do
		local altar = game.get_entity_by_unit_number(altar_id)
		altar_lib.update_altar(altar, {
			tank_id = altar_metadata.tank_id,
			get_souls = get_souls_from_tank,
			add_souls = add_souls_to_tank
		})
	end
end

return altar_lib
