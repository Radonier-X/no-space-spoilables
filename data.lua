local BASE_POWER_USAGE = "50kW" -- Minimum power to keep the system "on"
local PREREQUISITE_TECH = settings.startup["nss-technology-required"].value


local RESEARCH_REQUIREMENT_LIST = 
{
  ["space-platform"] = {
    count = 1000,
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"space-science-pack", 1}
    },
    time = 60
  },
  ["agricultural-science-pack"] = {
    count = 1000,
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"space-science-pack", 1},
      {"agricultural-science-pack",1}
    },
    time = 60
  },
  ["cryogenic-science-pack"] = {
    count = 1000,
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"space-science-pack", 1},
      {"agricultural-science-pack",1},
      {"cryogenic-science-pack",1}
    },
    time = 60
  },
  ["none"] = {
    count = 10,
    ingredients =
    {
      {"space-science-pack", 1}
    },
    time = 10
  }
}

local PREREQUISITES = {}
if not (PREREQUISITE_TECH == "none") then
  PREREQUISITES = {PREREQUISITE_TECH}
end

data:extend({
  {
  type = "technology",
  name = "nss-space-platfrom-refrigeration",
  icon = "__no-space-spoilables__/graphics/space-platform-freezing.png",
  icon_size = 256,
---@diagnostic disable-next-line: assign-type-mismatch
  prerequisites = PREREQUISITES,
  unit = RESEARCH_REQUIREMENT_LIST[PREREQUISITE_TECH],
  essential = false,
  hidden = (PREREQUISITE_TECH == "none")
}
})

data:extend({
  {
    type = "electric-energy-interface",
    name = "nss-space-refrigeration-interface",
    icon = "__no-space-spoilables__/graphics/space-platform-freezing-icon.png",
    icon_size = 256,
    flags = { "not-blueprintable", "not-deconstructable", "placeable-off-grid"},
    hidden = true,
    max_health = 1,
    collision_mask = {layers={}},

    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      render_no_power_icon = false,
      output_flow_limit = "0W"
    }
  }

})