local tq_lib = {
	events = {}
}

-------------------------------------------------------------------------------
-- Initialization

tq_lib.on_init = function()
	storage.tech_queue = {}
	for _,force in pairs(game.forces) do
		tq_lib.init_force(force)
	end
end

function tq_lib.init_force(force)
	storage.tech_queue[force.index] = {}
	local tech_queue = storage.tech_queue[force.index]

	for _,tech in pairs(prototypes.technology) do
		if not next(tech.prerequisites) and tq_lib.is_valid_tech(tech.name) then
			table.insert(tech_queue, {name=tech.name, kills=0})
		end
	end
end

tq_lib.events[defines.events.on_force_created] = function(e)
	tq_lib.init_force(e.force)
end

------------------------------------------------------------------------------- Queue

function tq_lib.is_valid_tech(tech_name)
	assert(type(tech_name) == "string")
	local tech_prototype = prototypes.technology[tech_name]
	assert(tech_prototype)
	if tech_prototype.research_trigger then
		return false
	end
	return true
end

function tq_lib.try_queue_tech(tech)
	assert(tech)
	local tech_queue = storage.tech_queue[tech.force.index]

	if not tq_lib.is_valid_tech(tech.name) then
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

------------------------------------------------------------------------------- Researching
-- Blips

function tq_lib.get_random_tech_index(force)
	local tech_queue = storage.tech_queue[force.index]
	if #tech_queue > 0 then
		return math.random(#tech_queue)
	end
	return nil
end

function tq_lib.get_tech(force, tech_id)
	if type(tech_id) == "number" then
		local tech_queue = storage.tech_queue[force.index]
		return force.technologies[tech_queue[tech_id].name]
	elseif type(tech_id) == "string" then
		return force.technologies[tech_id]
	else
		assert(type(tech_id) ~= "nil")
		return tech_id
	end
end

function tq_lib.progress_tech(tech, blips)
	local new_progress = tech.saved_progress + blips

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
		if kills == 1 then
			player_force.print({"biter-labs-ui.technology-researched-one", tech.name}, {tech.name})
		else
			player_force.print({"biter-labs-ui.technology-researched", tech.name, kills})
		end
	end

	tech.saved_progress = 0
	tech.researched = true
	for _,successor in pairs(tech.successors or {}) do
		tq_lib.try_queue_tech(successor)
	end
end

-------------------------------------------------------------------------------

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
end

tq_lib.events[defines.events.on_research_reversed] = function(e)
	for _,successor in pairs(e.research.successors or {}) do
		tq_lib.try_dequeue_tech(successor)
	end
	tq_lib.try_queue_tech(e.research)
end

return tq_lib
