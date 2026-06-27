data:extend({
    {
        type = "int-setting",
        name = "spoil-update-tick-interval",
        setting_type = "startup",
        default_value = 300,
        minimum_value = 1,
        maximum_value = 18000,
        order = "a"
    },
    {
        type = "double-setting",
        name = "power-per-stack",
        setting_type = "startup",
        default_value = 50000,
        minimum_value = 0,
        order = "b"
    },
    {
        type = "string-setting",
        name = "technology-required",
        setting_type = "startup",
        allowed_values = {"none","space-platform","agricultural-science-pack","cryogenic-science-pack"},
        default_value = "none",
        order = "c"
    }
})