Bridge = Bridge or {}

local function detect(candidates, configured)
    if configured and configured ~= 'auto' then
        return configured
    end

    for i = 1, #candidates do
        if GetResourceState(candidates[i].resource) == 'started' then
            return candidates[i].name
        end
    end

    return nil
end

-- Order matters: qbx_core also provides qb-core.
function Bridge.DetectFramework()
    return detect({
        { name = 'qbx', resource = 'qbx_core' },
        { name = 'qb', resource = 'qb-core' },
        { name = 'esx', resource = 'es_extended' },
    }, Config.Framework) or 'standalone'
end

function Bridge.DetectInventory()
    return detect({
        { name = 'ox_inventory', resource = 'ox_inventory' },
        { name = 'qb-inventory', resource = 'qb-inventory' },
    }, Config.Inventory)
end