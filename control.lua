--#region Init

script.on_init(function()
    storage.platform_interfaces = storage.platform_interfaces or {}
end)

script.on_configuration_changed(function()
    storage.platform_interfaces = storage.platform_interfaces or {}
end)

--#endregion

--#region Functions

-- Configuration:
-- Frequency of the "freeze" pulse
local TICK_INTERVAL = settings.startup["spoil-update-tick-interval"].value
local INTERFACE_NAME = "space-refrigeration-interface"
local POWER_PER_SLOT = settings.startup["power-per-stack"].value
local BASE_POWER_USAGE = 50000

-- Creates the interface on the surface of the platform and caches it for future uses
local function get_or_create_interface(platform)
    local platform_index = platform.index
    local cached_entity = storage.platform_interfaces[platform_index]

    -- If cached and still valid, return it immediately
    if cached_entity and cached_entity.valid then
        return cached_entity
    end

    -- If not in cache or invalid, we do a one-time search/create
    local hub = platform.hub
    if not hub or not hub.valid then return nil end

    local surface = platform.surface
    local interface = surface.find_entities_filtered{
        name = INTERFACE_NAME, 
        position = hub.position,
        radius = 6,
        limit = 1
    }[1]

    -- Creates the interface for the platfrom if it doesn't exist
    if not interface then
        interface = surface.create_entity{
            name = INTERFACE_NAME,
            position = hub.position,
            force = hub.force,
            create_build_effect_smoke = false
        }
        interface.destructible = true
        interface.operable = false
    end

    -- Save to cache for next time
    storage.platform_interfaces[platform_index] = interface
    return interface
end

-- Resets the time for the stack
local function freeze_stack(stack)
    -- Resets time upto the maximum permissable by the item
    stack.spoil_tick = game.tick + math.min(stack.prototype.get_spoil_ticks(stack.quality),
                                            (stack.spoil_tick - game.tick) + TICK_INTERVAL)
end

-- Core Logic: Resets the spoilage timer for all items in a given inventory
-- The stacks in inventory (Cargo Bay/Hub) to process
local function freeze_active_list(inventory) 
    for i = 1, #inventory do
        freeze_stack(inventory[i])
    end
end

--- @param inventory LuaInventory?
-- Returns all the Item stacks in the inventory which are spoilable
local function spoilable_counting(inventory)
    local active_slots = {}

    if not inventory or not inventory.valid then return 0 end

    for i=1, #inventory do
        local stack = inventory[i]

        -- valid_for_read: slot is not empty
        -- spoil_percent > 0: item is actually capable of spoiling

        if stack and stack.valid_for_read and stack.spoil_percent > 0 then
            active_slots[#active_slots + 1] = stack
        end
    end

    return active_slots
end


tech_flag = (settings.startup["technology-required"].value == "none")
-- Main loop function
--- @param force LuaForce?
local function process_space_platforms(force)

    for _, platform in pairs(force.platforms) do
        local hub = platform.hub

        if hub and hub.valid then
            local interface = get_or_create_interface(platform)
            if not interface then goto continue end

            -- 1. Calculate the 'Cost' based on previous tick's inventory
            local inv_main = hub.get_inventory(defines.inventory.hub_main)
            local inv_trash = hub.get_inventory(defines.inventory.hub_trash)
            
            -- 2. Get all the item stacks which are spoilable from both invertories
            spoilable_list_inv_main = spoilable_counting(inv_main)
            spoilable_list_inv_trash = spoilable_counting(inv_trash)

            -- 3. Update the power drain dynamically
            local spoilable_count = 0
            spoilable_count = #spoilable_list_inv_main + #spoilable_list_inv_trash
            
            power_consumption = (spoilable_count * POWER_PER_SLOT) / 60 
            interface.power_usage = power_consumption
            interface.input_flow_limit = power_consumption
            interface.electric_buffer_size = power_consumption*1.1

            -- 4. Check if we have enough energy in the buffer
            -- If the buffer is empty, the platform is out of power
            if interface.energy >= (interface.power_usage) then
                freeze_active_list(spoilable_list_inv_main)
                freeze_active_list(spoilable_list_inv_trash)
            end

            ::continue::
        end

    end
end

--#endregion

--#region Script handlers

-- Register the logic to run every nth tick
script.on_nth_tick(TICK_INTERVAL, function ()
    for _, force in pairs(game.forces) do
        if tech_flag then
            process_space_platforms(force)
        else 
            if force.technologies["space-platfrom-refrigeration"].researched then 
                process_space_platforms(force)
            end
        end
    end
end)

--#endregion