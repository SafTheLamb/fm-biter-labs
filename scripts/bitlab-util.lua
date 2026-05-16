local biter_labs_util = {}

function biter_labs_util.print(player, message)
	if player or rcon then
		player.print(message)
	end
end

return biter_labs_util
