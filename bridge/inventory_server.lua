-- Inventory adapters (server). Every adapter must implement:
--   RegisterStash(id, label, slots, maxWeight)
--   GetSlot(source, slot)            -> item table or nil
--   SetMetadata(source, slot, meta)  -> boolean
--   GetItems(source)                 -> table of items
--   RegisterUseable(names, fn)       -> optional, for inventories without a
--                                       client use export. fn(source, name, slot)
-- ox_inventory is tested. qb-inventory was written from its source/docs and is
-- untested. To support another inventory, add an adapter here and its
-- detection in bridge/shared.lua.

Bridge.Inventories = Bridge.Inventories or {}

Bridge.Inventories.ox_inventory = {
    resource = 'ox_inventory',

    RegisterStash = function(id, label, slots, maxWeight)
        exports.ox_inventory:RegisterStash(id, label, slots, maxWeight, id)
    end,

    GetSlot = function(source, slot)
        return exports.ox_inventory:GetSlot(source, slot)
    end,

    SetMetadata = function(source, slot, metadata)
        return exports.ox_inventory:SetMetadata(source, slot, metadata)
    end,

    GetItems = function(source)
        return exports.ox_inventory:GetInventoryItems(source)
    end,
}

-- qb-inventory (qbcore-framework/qb-inventory, v2.x exports).
-- Items store their data in `info`; it is exposed here as `metadata`.
-- Backpack items must be `unique = true` so they never stack.
local function qbPlayerItems(source)
    local player = exports['qb-core']:GetPlayer(source)

    return player and player.PlayerData.items or {}
end

local function qbNormalize(item)
    if not item then
        return nil
    end

    return {
        name = item.name,
        slot = item.slot,
        metadata = item.info or {},
    }
end

Bridge.Inventories['qb-inventory'] = {
    resource = 'qb-inventory',

    RegisterStash = function(id, label, slots, maxWeight)
        pcall(function()
            exports['qb-inventory']:CreateInventory(id, {
                label = label,
                slots = slots,
                maxweight = maxWeight,
            })
        end)
    end,

    GetSlot = function(source, slot)
        return qbNormalize(exports['qb-inventory']:GetItemBySlot(source, slot))
    end,

    SetMetadata = function(source, slot, metadata)
        local item = exports['qb-inventory']:GetItemBySlot(source, slot)

        if not item then
            return false
        end

        return exports['qb-inventory']:SetItemData(
            source,
            item.name,
            'info',
            metadata,
            slot
        ) == true
    end,

    GetItems = function(source)
        local items = {}

        for slot, item in pairs(qbPlayerItems(source)) do
            items[slot] = qbNormalize(item)
        end

        return items
    end,

    -- qb-inventory has no client export on use: items are registered as
    -- useable through the framework and the client is notified.
    RegisterUseable = function(names, handler)
        local QBCore = exports['qb-core']:GetCoreObject()

        for i = 1, #names do
            local name = names[i]

            QBCore.Functions.CreateUseableItem(name, function(source, item)
                handler(source, name, item and item.slot)
            end)
        end
    end,
}

-- qb-inventory opens stashes from the server. The client asks for it and the
-- backpack must be in the player's own inventory.
RegisterNetEvent('cb-backpacks:server:qbOpen', function(backpackId)
    local src = source

    if Bridge.InventoryName ~= 'qb-inventory' or type(backpackId) ~= 'string' then
        return
    end

    for _, item in pairs(qbPlayerItems(src)) do
        local backpack = Config.Backpacks[item.name]

        if backpack
            and item.info
            and item.info[Config.Metadata.id] == backpackId
        then
            exports['qb-inventory']:OpenInventory(src, backpackId, {
                label = backpack.label,
                slots = backpack.slots,
                maxweight = backpack.maxWeight,
            })

            return
        end
    end
end)

RegisterNetEvent('cb-backpacks:server:qbClose', function()
    if Bridge.InventoryName == 'qb-inventory' then
        exports['qb-inventory']:CloseInventory(source)
    end
end)
Bridge.InventoryName = Bridge.DetectInventory()
Bridge.Inventory = Bridge.InventoryName and Bridge.Inventories[Bridge.InventoryName] or nil

if not Bridge.Inventory then
    print('[cb-backpacks] No supported inventory found. Supported: ox_inventory, qb-inventory.')
end