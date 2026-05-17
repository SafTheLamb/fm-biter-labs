local biter_labs_util = {}

function biter_labs_util.print(player, message)
	if player or rcon then
		player.print(message)
	end
end

local function get_child_or_children(table, child_name)
	if table[child_name] and not table[child_name].type then
		return table[child_name]
	else
		return {table[child_name]}
	end
end

function biter_labs_util.get_food_delivery(capsule_action)
	local ammo_type = capsule_action.attack_parameters.ammo_type
	for _,action in pairs(get_child_or_children(ammo_type, "action")) do
		if action.type == "direct" then
			for _,delivery in pairs(get_child_or_children(action, "action_delivery")) do
				if delivery.type == "instant" then
					for _,target_effect in pairs(get_child_or_children(delivery, "target_effects")) do
						if target_effect.type == "damage" and target_effect.damage.amount < 0 then
							return delivery
						end
					end
				end
			end
		end
	end
	return nil
end

return biter_labs_util
