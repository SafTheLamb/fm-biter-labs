local util = require("__core__.lualib.util")

local tq_lib = {
	events = {}
}

------------------------------------------------------------------------------- Initialization

tq_lib.on_init = function()
	storage.tech_queue = {}
	for _,force in pairs(game.forces) do
		tq_lib.init_force(force)
	end
end

function tq_lib.init_force(force)
	storage.tech_queue[force.index] = {
		souls_per_blip = 5,
		queue_sets = {}
	}
	local tech_queue = storage.tech_queue[force.index]

	for _,tech in pairs(prototypes.technology) do
		if not next(tech.prerequisites) and tq_lib.is_valid_tech(tech) then
			table.insert(tech_queue, {name=tech.name, kills=0})
		end
	end

	tq_lib.reinit_queue_sets(force)
end

tq_lib.events[defines.events.on_force_created] = function(e)
	tq_lib.init_force(e.force)
end

------------------------------------------------------------------------------- Queue

function tq_lib.is_valid_tech(tech)
	if prototypes.technology[tech.name].research_trigger then
		return false
	end
	return true
end

function tq_lib.try_queue_tech(tech)
	assert(tech)
	local tech_queue = storage.tech_queue[tech.force.index]

	if not tq_lib.is_valid_tech(tech) or tech.researched then
		return false
	end

	for _,prerequisite in pairs(tech.prerequisites) do
		if not prerequisite.researched then
			return false
		end
	end

	for _,queued_name in pairs(tech_queue) do
		if tech.name == queued_name then
			return false
		end
	end

	table.insert(tech_queue, {name=tech.name, kills=0})
	return true
end

function tq_lib.try_dequeue_tech(tech)
	local tech_queue = storage.tech_queue[tech.force.index]
	for i,tech_data in ipairs(tech_queue) do
		if tech_data.name == tech.name then
			local kills = tech_data.kills
			table.remove(tech_queue, i)
			return kills
		end
	end
	return false
end

------------------------------------------------------------------------------- Queue sets

function tq_lib.reinit_queue_sets(force)
	local tech_queue = storage.tech_queue[force.index]
	tech_queue.queue_sets = {}
	for tech_id,tech_data in ipairs(tech_queue) do
		local tech = force.technologies[tech_data.name]
		local key = ""
		for _,ingredient in pairs(tech.research_unit_ingredients) do
			key = key..ingredient.name..','
		end
		if not tech_queue.queue_sets[key] then
			tech_queue.queue_sets[key] = {tech_id}
		else
			table.insert(tech_queue.queue_sets[key], tech_id)
		end
	end
end

------------------------------------------------------------------------------- Researching

function tq_lib.get_random_tech_index(altar)
	-- TODO: Update to use queue sets
	local tech_queue = storage.tech_queue[altar.force.index]
	local valid_tech_ids = {}
	for set_ingredients,queue_set in pairs(tech_queue.queue_sets) do
		local ingredients = util.split(set_ingredients, ',')
		for _,ingredient_name in pairs(ingredients) do
			if altar.get_item_count(ingredient_name) == 0 then
				goto continue
			end
		end

		for _,tech_id in pairs(queue_set) do
			table.insert(valid_tech_ids, tech_id)
		end

		::continue::
	end

	if #valid_tech_ids > 0 then
		local tech_id = valid_tech_ids[math.random(#valid_tech_ids)]
		return tech_id
	end
	return nil
end

function tq_lib.get_top_tech_ids(force, count)
	local leaderboard = {}
	local queue_copy = util.table.deepcopy(storage.tech_queue[force.index])
	for i=1,count do
		local top_progress = 0
		local top_id = 0
		for tech_id,tech_data in pairs(queue_copy) do
			if type(tech_id) == "number" then
				local tech = force.technologies[tech_data.name]
				if tech.saved_progress > top_progress then
					top_progress = tech.saved_progress
					top_id = tech_id
				end
			end
		end
		if top_id > 0 then
			table.insert(leaderboard, top_id)
			queue_copy[top_id] = nil
		end
	end
	return leaderboard
end

function tq_lib.get_tech_data(force, tech_id)
	return storage.tech_queue[force.index][tech_id]
end

function tq_lib.progress_tech(tech, blips)
	-- TODO: Convert from blips to progress
	local new_progress = tech.saved_progress + blips / tech.research_unit_count

	local tech_queue = storage.tech_queue[tech.force.index]
	tech_queue.souls_per_blip = tech_queue.souls_per_blip + 0.01 * blips

	if new_progress >= 1 then
		tq_lib.research_tech(tech)
		tech.saved_progress = 0
	else
		tech.saved_progress = new_progress
	end
end

function tq_lib.research_tech(tech)
	local player_force = tech.force

	local kills = tq_lib.try_dequeue_tech(tech)
	if type(kills) == "number" then
		local print_settings = {
			sound_path = "utility/research_completed"
		}
		kills = math.max(math.floor(kills + 0.5), 1)
		if kills == 1 then
			player_force.print({"biter-labs-ui.technology-researched-one", tech.name}, print_settings)
		else
			player_force.print({"biter-labs-ui.technology-researched", tech.name, kills}, print_settings)
		end
	end

	tech.saved_progress = 0
	tech.researched = true
	for _,successor in pairs(tech.successors or {}) do
		tq_lib.try_queue_tech(successor)
	end
end

function tq_lib.get_souls_per_blip(force)
	return storage.tech_queue[force.index].souls_per_blip
end

------------------------------------------------------------------------------- Events

tq_lib.events[defines.events.on_research_started] = function(e)
	-- Never let players queue technologies
	local player_force = e.research.force
	player_force.research_queue = nil
	player_force.print({"biter-labs-ui.research-queue-disabled"})
end

tq_lib.events[defines.events.on_research_queued] = function(e)
	-- Never let players queue technologies
	e.force.research_queue = nil
end

tq_lib.events[defines.events.on_research_finished] = function(e)
	tq_lib.try_dequeue_tech(e.research)
	for _,successor in pairs(e.research.successors or {}) do
		tq_lib.try_queue_tech(successor)
	end
	tq_lib.reinit_queue_sets(e.research.force)
end

tq_lib.events[defines.events.on_research_reversed] = function(e)
	for _,successor in pairs(e.research.successors or {}) do
		tq_lib.try_dequeue_tech(successor)
	end
	tq_lib.try_queue_tech(e.research)
	tq_lib.reinit_queue_sets(e.research.force)
end

tq_lib.on_configuration_changed = function(e)
	for _,force in pairs(game.forces) do
		local tech_queue = storage.tech_queue[force.index]
		local old_kills = {}
		for _,tech_data in ipairs(tech_queue) do
			old_kills[tech_data.name] = tech_data.kills
		end

		tech_queue = {
			souls_per_blip = 5,
			queue_sets = {}
		}

		for _,tech in pairs(force.technologies) do
			if tq_lib.is_valid_tech(tech) then
				if tech.researched then
					tech_queue.souls_per_blip = tech_queue.souls_per_blip + 0.01 * tech.research_unit_count
					goto continue
				end
				for _,prerequisite in pairs(tech.prerequisites or {}) do
					if not prerequisite.researched then
						-- This would cause tracked kills to be lost
						tech.saved_progress = 0
						goto continue
					end
				end
				tech_queue.souls_per_blip = tech_queue.souls_per_blip + 0.01 * tech.saved_progress * tech.research_unit_count
				table.insert(tech_queue, {
					name = tech.name,
					kills = old_kills[tech.name] or 0
				})
			end
			::continue::
		end
		tq_lib.reinit_queue_sets(force)
	end
end

-- TODO: Handle technologies being added/removed via on_configuration_changed (use e.migrations?)

return tq_lib
