local Core = require("script.core")

--#region GUI

local TOGGLE_FRAME_NAME = "nss-space-refrigeration-toggle-frame"
local TOGGLE_SWITCH_NAME = "nss-space-refrigeration-toggle-switch"
local CIRCUIT_CHECKBOX_NAME = "nss-space-refrigeration-circuit-checkbox"
local CIRCUIT_FLOW_NAME = "nss-space-refrigeration-circuit-flow"
local SIGNAL_BUTTON_NAME = "nss-space-refrigeration-circuit-signal"
local COMPARATOR_DROPDOWN_NAME = "nss-space-refrigeration-circuit-comparator"
local CONSTANT_FIELD_NAME = "nss-space-refrigeration-circuit-constant"

local COMPARATOR_ITEMS = {"<", "≤", "=", "≥", ">", "≠"}

script.on_event(defines.events.on_gui_opened, function(event)
    local entity = event.entity
    if not (entity and entity.valid and entity.type == "space-platform-hub") then return end

    local platform = entity.surface.platform
    if not platform then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    if player.gui.relative[TOGGLE_FRAME_NAME] then
        player.gui.relative[TOGGLE_FRAME_NAME].destroy()
    end

    if not Core.tech_researched(entity.force) then
        return
    end

    local frame = player.gui.relative.add{
        type = "frame",
        name = TOGGLE_FRAME_NAME,
        caption = {"gui-nss-space-refrigeration.frame-title"},
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.space_platform_hub_gui,
            position = defines.relative_gui_position.left
        }
    }

    local platform_settings = storage.platform_settings[platform.index] or {}

    frame.add{
        type = "switch",
        name = TOGGLE_SWITCH_NAME,
        switch_state = Core.is_interface_enabled(platform) and "right" or "left",
        left_label_caption = {"gui-nss-space-refrigeration.switch-off"},
        right_label_caption = {"gui-nss-space-refrigeration.switch-on"}
    }

    frame.add{
        type = "checkbox",
        name = CIRCUIT_CHECKBOX_NAME,
        state = platform_settings.use_circuit_condition or false,
        caption = {"gui-nss-space-refrigeration.circuit-checkbox"}
    }

    if platform_settings.use_circuit_condition then
        local condition = platform_settings.circuit_condition or {}
        local flow = frame.add{type = "flow", name = CIRCUIT_FLOW_NAME, direction = "horizontal"}

        flow.add{
            type = "choose-elem-button",
            name = SIGNAL_BUTTON_NAME,
            elem_type = "signal",
            signal = condition.first_signal
        }

        local comparator_dropdown = flow.add{
            type = "drop-down",
            name = COMPARATOR_DROPDOWN_NAME,
            items = COMPARATOR_ITEMS
        }
        for i, c in ipairs(COMPARATOR_ITEMS) do
            if c == (condition.comparator or ">") then
                comparator_dropdown.selected_index = i
            end
        end

        flow.add{
            type = "textfield",
            name = CONSTANT_FIELD_NAME,
            text = tostring(condition.constant or 0),
            numeric = true,
            allow_negative = true
        }
    end
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    if event.element.name ~= TOGGLE_SWITCH_NAME then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local entity = player.opened
    if not (entity and entity.valid and entity.object_name == "LuaEntity" and entity.type == "space-platform-hub") then
        return
    end

    local platform = entity.surface.platform
    if not platform then return end

    Core.set_interface_state(platform, event.element.switch_state == "right")
end)

-- Toggling this rebuilds the relative GUI so the condition row appears/disappears
script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    if event.element.name ~= CIRCUIT_CHECKBOX_NAME then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local entity = player.opened
    if not (entity and entity.valid and entity.object_name == "LuaEntity" and entity.type == "space-platform-hub") then
        return
    end

    local platform = entity.surface.platform
    if not platform then return end

    storage.platform_settings[platform.index] = storage.platform_settings[platform.index] or {}
    storage.platform_settings[platform.index].use_circuit_condition = event.element.state

    -- Reopen to rebuild the frame with (or without) the condition row
    player.opened = nil
    player.opened = entity
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    if event.element.name ~= SIGNAL_BUTTON_NAME then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local entity = player.opened
    if not (entity and entity.valid and entity.object_name == "LuaEntity" and entity.type == "space-platform-hub") then
        return
    end

    local platform = entity.surface.platform
    if not platform then return end

    local settings = storage.platform_settings[platform.index]
    if not settings then return end

    settings.circuit_condition = settings.circuit_condition or {}
    settings.circuit_condition.first_signal = event.element.elem_value
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    if event.element.name ~= COMPARATOR_DROPDOWN_NAME then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local entity = player.opened
    if not (entity and entity.valid and entity.object_name == "LuaEntity" and entity.type == "space-platform-hub") then
        return
    end

    local platform = entity.surface.platform
    if not platform then return end

    local settings = storage.platform_settings[platform.index]
    if not settings then return end

    settings.circuit_condition = settings.circuit_condition or {}
    settings.circuit_condition.comparator = COMPARATOR_ITEMS[event.element.selected_index]
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if event.element.name ~= CONSTANT_FIELD_NAME then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local entity = player.opened
    if not (entity and entity.valid and entity.object_name == "LuaEntity" and entity.type == "space-platform-hub") then
        return
    end

    local platform = entity.surface.platform
    if not platform then return end

    local settings = storage.platform_settings[platform.index]
    if not settings then return end

    settings.circuit_condition = settings.circuit_condition or {}
    settings.circuit_condition.constant = tonumber(event.element.text) or 0
end)

--#endregion