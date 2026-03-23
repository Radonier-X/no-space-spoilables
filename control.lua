script.on_init(function()
    storage.platform_interfaces = storage.platform_interfaces or {}
end)

script.on_configuration_changed(function()
    storage.platform_interfaces = storage.platform_interfaces or {}
end)


-- Configuration: Frequency of the "freeze" pulse
local TICK_INTERVAL = settings.startup["spoil-update-tick-interval"].value

local INTERFACE_NAME = "space-refrigeration-interface"
local POWER_PER_SLOT = 5000
local BASE_POWER = 50000


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

    if not interface then
        interface = surface.create_entity{
            name = INTERFACE_NAME,
            position = hub.position,
            force = hub.force,
            create_build_effect_smoke = false
        }
        interface.destructible = false
        interface.operable = false
    end

    -- Save to cache for next time
    storage.platform_interfaces[platform_index] = interface
    return interface
end



--- Core Logic: Resets the spoilage timer for all items in a given inventory
--- @param inventory LuaInventory? The inventory (Cargo Bay/Hub) to process
local function freeze_inventory(inventory)
    
    if not inventory or not inventory.valid then return end
    
    for i = 1, #inventory do
        local stack = inventory[i]

        -- valid_for_read: slot is not empty
        -- spoil_percent > 0: item is actually capable of spoiling
        if stack and stack.valid_for_read and stack.spoil_percent > 0 then
            local time_left = stack.spoil_tick - game.tick
            local max_life = stack.prototype.get_spoil_ticks(stack.quality)
            
            -- Set the new spoil tick to: Current Time + (Remaining Time + Interval)
            -- math.min ensures we never exceed the item's maximum possible freshness
            stack.spoil_tick = game.tick + math.min(max_life, time_left + TICK_INTERVAL)
        end
    end
end

local function spoilable_counting(inventory)
    local active_slots = 0

    if not inventory or not inventory.valid then return 0 end

    for i=1, #inventory do
        local stack = inventory[i]

        -- valid_for_read: slot is not empty
        -- spoil_percent > 0: item is actually capable of spoiling

        if stack and stack.valid_for_read and stack.spoil_percent > 0 then
            active_slots = active_slots + 1
        end
    end

    return active_slots
end

--- Main Loop Function: Scans all existing space platforms
--[[
local function process_space_platforms()
    -- Platforms are categorized by the Force (Team) they belong to
    for _, force in pairs(game.forces) do
        for _, platform in pairs(force.platforms) do

            -- TO DO: Implement a electric energy interface check
            

            
            -- The 'hub' is the master entity for any platform and inventory
            local hub = platform.hub
            if hub and hub.valid then
                -- inventory of the Hub and all attached Cargo Bays.
                local cargo_inventory = hub.get_inventory(defines.inventory.hub_main)
                freeze_inventory(cargo_inventory)
                -- For trash slots too
                local cargo_inventory_trash = hub.get_inventory(defines.inventory.hub_trash)
                freeze_inventory(cargo_inventory_trash)
            end
        end
    end
end
]]--

--- Main Loop Function: Scans all existing space platforms
local function process_space_platforms()
    -- Platforms are categorized by the Force (Team) they belong to
    for _, force in pairs(game.forces) do
        for _, platform in pairs(force.platforms) do

            -- The 'hub' is the master entity for any platform and inventory
            local hub = platform.hub
            if hub and hub.valid then
                local interface = get_or_create_interface(platform)
                
                if interface and interface.valid then
                    -- 1. Calculate the cost based on the number of spoilable item stacks
                    local inv_main = hub.get_inventory(defines.inventory.hub_main)
                    local inv_trash = hub.get_inventory(defines.inventory.hub_trash)
                    
                    
                    local spoilable_count = 0
                    if inv_main then spoilable_count = spoilable_count + spoilable_counting(inv_main) end
                    if inv_trash then spoilable_count = spoilable_count + spoilable_counting(inv_trash) end

                    -- 2. Update the power demand (Watts)
                    local required_power = BASE_POWER + (spoilable_count * POWER_PER_SLOT)
                    interface.power_usage = required_power
                    
                    -- 3. Energy check: interface.energy is in Joules. 
                    -- At 60 FPS, 1 Watt = 1/60 Joules per tick.
                    -- We check if we have enough for at least one "pulse"
                    local energy_needed_this_pulse = (required_power / 60) * TICK_INTERVAL
                    
                    if interface.energy >= energy_needed_this_pulse then
                        freeze_inventory(inv_main)
                        freeze_inventory(inv_trash)
                    end

                    log(interface.energy)
                    log(energy_needed_this_pulse)
                end
            end
        end
    end
end

-- Register the logic to run every nth tick
script.on_nth_tick(TICK_INTERVAL, process_space_platforms)