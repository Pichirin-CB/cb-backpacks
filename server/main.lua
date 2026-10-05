local BackpackItems = Config.Backpacks

local function debug(...)
    if Config.Debug then
        print('[cb-backpacks]', ...)
    end
end

CreateThread(function()
    for itemName, backpack in pairs(BackpackItems) do
        exports.ox_inventory:setContainerProperties(itemName, {
            slots = backpack.slots,
            maxWeight = backpack.maxWeight,
        })
        debug(('Registered container %s: %s slots / %s g'):format(
            itemName, backpack.slots, backpack.maxWeight
        ))
    end
end)

local function generateContainerId(source)
    return ('cb_backpack_%s_%s_%s'):format(
        source,
        os.time(),
        math.random(100000, 999999)
    )
end

lib.callback.register('cb-backpacks:server:prepareBackpack', function(source, slot)
    slot = tonumber(slot)
    if not slot then return false end

    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item or not BackpackItems[item.name] then
        return false
    end

    local metadata = item.metadata or {}

    if metadata.container then
        return metadata.container
    end

    metadata.container = generateContainerId(source)
    metadata.size = {
        BackpackItems[item.name].slots,
        BackpackItems[item.name].maxWeight
    }

    local success = exports.ox_inventory:SetMetadata(source, slot, metadata)
    if not success then
        return false
    end

    debug(('Prepared %s for player %s, container=%s'):format(
        item.name, source, metadata.container
    ))

    return metadata.container
end)

lib.callback.register('cb-backpacks:server:getBackpackSlot', function(source, slot)
    slot = tonumber(slot)
    if not slot then return false end

    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item or not BackpackItems[item.name] then
        return false
    end

    return {
        name = item.name,
        slot = item.slot,
        metadata = item.metadata or {},
    }
end)
