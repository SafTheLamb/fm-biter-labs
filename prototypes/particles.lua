-- Based on "__base__.prototypes.particles"
local function make_particle(params)

  if not params then error("No params given to make_particle function") end
  local name = params.name or error("No name given")

  local particle =
  {

    type = "optimized-particle",
    name = name,

    life_time = params.life_time or (60 * 15),
    fade_away_duration = params.fade_away_duration,

    render_layer = params.render_layer or "projectile",
    render_layer_when_on_ground = params.render_layer_when_on_ground or "corpse",
	draw_shadow_when_on_ground = false,

    regular_trigger_effect_frequency = params.regular_trigger_effect_frequency or 2,
    regular_trigger_effect = params.regular_trigger_effect,
    ended_in_water_trigger_effect = params.ended_in_water_trigger_effect,

    pictures = params.pictures,

    movement_modifier_when_on_ground = params.movement_modifier_when_on_ground,
    movement_modifier = params.movement_modifier,
    vertical_acceleration = params.vertical_acceleration,

    mining_particle_frame_speed = params.mining_particle_frame_speed,

  }

  return particle

end

local function get_soul_particle(tint)
	return {
		sheet = {
			filename = "__biter-labs__/graphics/particle/souls/soul.png",
			priority = "high",
			-- blend_mode = "additive",
			-- draw_as_light = true,
			width = 16,
			height = 16,
			frame_count = 1,
			tint = tint,
			scale = 0.5,
			variation_count = 1,
		}
	}
end

data:extend({
	make_particle{
		name = "soul-leaving",
		pictures = get_soul_particle({1,0,1}),
		life_time = 30,
		fade_away_duration = 15,
		vertical_acceleration = -0.003,
	},
	make_particle{
		name = "soul-collecting",
		pictures = get_soul_particle({1,0,1}),
		life_time = 30,
		fade_away_duration = 15,
		vertical_acceleration = -0.003,
		movement_modifier = 0.9
	}
})
