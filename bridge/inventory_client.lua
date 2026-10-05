-- Inventory adapters (client). Every adapter must implement:
--   GetItems()          -> table of the player's items
--   UseItem(data, cb)   -> asks the inventory to validate the use
--   OpenStash(id)       -> opens the backpack inventory
--   Close()             -> closes the open inventory
--   OnUpdate(cb)        -> calls cb when the player's inventory changes

Bridge.Inventories = Bridge.Inventories or {}

Bridge.Inventories.ox_inventory = {
    resource = 'ox_inventory',

    GetItems = function()
        return exports.ox_inventory:GetPlayerItems()
    end,

    UseItem = function(data, cb)
        exports.ox_inventory:useItem(data, cb)
    end,

    OpenStash = function(id)
        return exports.ox_inventory:openInventory('stash', { id = id, owner = id })
    end,

    Close = function()
        exports.ox_inventory:closeInventory()
    end,

    OnUpdate = function(cb)
        AddEventHandler('ox_inventory:updateInventory', cb)
    end,
}

-- qb-inventory: items are read from the framework player data, `info` is
-- exposed as `metadata`. Use is validated by qb-inventory itself and the
-- server notifies the client (see RegisterUseable on the server bridge).
Bridge.Inventories['qb-inventory'] = {
    resource = 'qb-inventory',

    GetItems = function()
        local data = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
        local items = {}

        for slot, item in pairs(data and data.items or {}) do
            items[slot] = {
                name = item.name,
                slot = item.slot,
                metadata = item.info or {},
            }
        end

        return items
    end,

    UseItem = function(_, cb)
        cb(true)
    end,

    OpenStash = function(id)
        TriggerServerEvent('cb-backpacks:server:qbOpen', id)
    end,

    Close = function()
        TriggerEvent('qb-inventory:client:closeInv')
        TriggerServerEvent('cb-backpacks:server:qbClose')
    end,

    OnUpdate = function(cb)
        local pending = false

        local function debounced()
            if pending then
                return
            end

            pending = true

            SetTimeout(500, function()
                pending = false
                cb()
            end)
        end

        AddEventHandler('qb-inventory:client:updateInventory', debounced)
        AddEventHandler('QBCore:Player:SetPlayerData', debounced)
    end,
}
Bridge.InventoryName = Bridge.DetectInventory()
Bridge.Inventory = Bridge.InventoryName and Bridge.Inventories[Bridge.InventoryName] or nil

if not Bridge.Inventory then
    print('[cb-backpacks] No supported inventory found. Supported: ox_inventory, qb-inventory.')
end