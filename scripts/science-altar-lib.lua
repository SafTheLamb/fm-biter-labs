local altar_lib = {
	events = {}
}

-------------------------------------------------------------------------------
-- Initialization

altar_lib.on_init = function()
	storage.science_altars = {}
	for _,force in pairs(game.forces) do
		altar_lib.init_force(force)
	end
end

function altar_lib.init_force(force)
	storage.science_altars[force.index] = {}
	local altar_storage = storage.science_altars[force.index]
	-- for _,surface in pairs()
end

altar_lib.events[defines.events.on_force_created] = function(e)
	altar_lib.init_force(e.force)
end

altar_lib.events[defines.events.on_surface_created] = function(e)

end

altar_lib.events[defines.events.on_surface_imported] = function(e)

end

altar_lib.events[defines.events.on_surface_cleared] = function(e)
	
end

altar_lib.events[defines.events.on_surface_deleted] = function(e)
	
end

altar_lib.events[defines.events.on_surface_renamed] = function(e)
	
end

return altar_lib
