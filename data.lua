local BASE_POWER_USAGE = "50kW" -- Minimum power to keep the system "on"

data:extend({
  {
    type = "electric-energy-interface",
    name = "space-refrigeration-interface",
    icon = "__base__/graphics/icons/accumulator.png",
    icon_size = 64,
    flags = { "not-blueprintable", "not-deconstructable", "placeable-off-grid"},
    hidden = true,
    max_health = 1,
    collision_mask = {layers={}},

    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      -- Large buffer to allow for scaling drain
      buffer_capacity = "10MJ", 
      input_flow_limit = "5MW",
      render_no_power_icon = false
    }
  }
})