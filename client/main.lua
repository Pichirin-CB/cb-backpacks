local equipped = nil
local baseComponent = nil
local busy = false

local function debug(...)
    if not Config.Debug then
        return
    end

    print('[cb-backpacks]', ...)
end

local function notify(description, type)
    lib.notify({
        title = L('title'),
        description = description,
        type = type or 'inform',
    })
end
local function isBackpack(name)
    return name and Config.Backpacks[name] ~= nil
end

local function getBackpackId(item)
    if not item or not item.metadata then
        return nil
    end

    return item.metadata[Config.Metadata.id]
end

local function getPlayerItems()
    local items = Bridge.Inventory and Bridge.Inventory.GetItems()

    return items or {}
end

local function findBackpackById(backpackId)
    if not backpackId then
        return nil
    end

    local items = getPlayerItems()

    for slot, item in pairs(items) do
        if item
            and isBackpack(item.name)
            and getBackpackId(item) == backpackId
        then
            return slot, item
        end
    end

    return nil
end

local function getComponentState(component)
    local ped = PlayerPedId()

    return {
        drawable = GetPedDrawableVariation(ped, component),
        texture = GetPedTextureVariation(ped, component),
    }
end

local function isValidDrawable(component, drawable)
    local ped = PlayerPedId()

    local count = GetNumberOfPedDrawableVariations(
        ped,
        component
    )

    return drawable >= 0 and drawable < count
end

-- Addon clothes get a global drawable index that depends on load order, so it
-- is resolved from collection name + local index (documented FiveM natives).
local resolvedCollection = nil

local function collectionsAvailable()
    return GetPedCollectionsCount
        and GetPedCollectionName
        and GetNumberOfPedCollectionDrawableVariations
        and GetPedDrawableGlobalIndexFromCollection
end

local function findCollection(ped, component, backpack)
    local wanted = backpack.collection

    if wanted and GetNumberOfPedCollectionDrawableVariations(ped, component, wanted) > 0 then
        return wanted
    end

    -- Configured name does not match: look for a collection that has this
    -- component and whose name looks like the backpack pack.
    for i = 0, GetPedCollectionsCount(ped) - 1 do
        local name = GetPedCollectionName(ped, i)

        if name ~= ''
            and name:lower():find('backpack', 1, true)
            and GetNumberOfPedCollectionDrawableVariations(ped, component, name) > 0
        then
            debug(('Collection "%s" not found, using "%s" instead.'):format(
                tostring(wanted),
                name
            ))

            return name
        end
    end

    return nil
end

local function resolveDrawable(ped, component, backpack)
    resolvedCollection = nil
    if not backpack.localDrawable or not collectionsAvailable() then
        return backpack.drawable or 0
    end

    local collection = findCollection(ped, component, backpack)
    resolvedCollection = collection

    if not collection then
        debug(('No clothing collection with component %s found for this ped model.'):format(component))
        return nil
    end

    local count = GetNumberOfPedCollectionDrawableVariations(ped, component, collection)

    if backpack.localDrawable >= count then
        debug(('Collection "%s" only has %s drawables for component %s (wanted local %s).'):format(
            collection,
            count,
            component,
            backpack.localDrawable
        ))

        return nil
    end

    local global = GetPedDrawableGlobalIndexFromCollection(
        ped,
        component,
        collection,
        backpack.localDrawable
    )

    debug(('Resolved "%s" local %s -> global drawable %s'):format(
        collection,
        backpack.localDrawable,
        global
    ))

    if global == nil or global < 0 then
        return nil
    end

    return global
end
local function applyBackpackClothing(backpack)
    local ped = PlayerPedId()

    local component = backpack.component or 5
    local drawable = resolveDrawable(ped, component, backpack)
    local texture = backpack.texture or 0

    if not drawable then
        notify(L('clothing_not_found'), 'error')
        return false
    end

    local drawableCount = GetNumberOfPedDrawableVariations(
        ped,
        component
    )

    local textureCount = 0

    if isValidDrawable(component, drawable) then
        textureCount = GetNumberOfPedTextureVariations(
            ped,
            component,
            drawable
        )
    end

    debug(('Applying clothing: component=%s drawable=%s texture=%s'):format(
        component,
        drawable,
        texture
    ))

    debug(('Available drawables=%s textures=%s'):format(
        drawableCount,
        textureCount
    ))

    if not isValidDrawable(component, drawable) then
        notify(
            L('drawable_invalid', drawable, drawableCount),
            'error'
        )

        return false
    end

    if texture < 0 or texture >= textureCount then
        notify(
            L('texture_invalid', texture, drawable, textureCount),
            'error'
        )

        return false
    end

    if resolvedCollection and backpack.localDrawable then
        SetPedCollectionComponentVariation(ped, component, resolvedCollection, backpack.localDrawable, texture, 0)
    else
        SetPedComponentVariation(ped, component, drawable, texture, 0)
    end

    Wait(50)

    local appliedDrawable = GetPedDrawableVariation(
        ped,
        component
    )

    local appliedTexture = GetPedTextureVariation(
        ped,
        component
    )

    debug(('Applied clothing result: drawable=%s texture=%s'):format(
        appliedDrawable,
        appliedTexture
    ))

    return appliedDrawable == drawable
        and appliedTexture == texture
end

local function restoreBaseClothing()
    if not baseComponent then
        return
    end

    local ped = PlayerPedId()

    SetPedComponentVariation(
        ped,
        baseComponent.component,
        baseComponent.drawable,
        baseComponent.texture,
        0
    )

    debug(('Restored base clothing: component=%s drawable=%s texture=%s'):format(
        baseComponent.component,
        baseComponent.drawable,
        baseComponent.texture
    ))

    baseComponent = nil
end

local function startAnimation()
    if not Config.Animation.enabled then
        return
    end

    if GetResourceState('rpemotes-reborn') ~= 'started' then
        debug('rpemotes-reborn not started.')
        return
    end

    CreateThread(function()
        pcall(function()
            exports['rpemotes-reborn']:EmoteCommandStart(
                Config.Animation.emote,
                nil
            )
        end)

        Wait(Config.Animation.duration)

        pcall(function()
            exports['rpemotes-reborn']:EmoteCancel(true)
        end)
    end)
end

local function stopAnimation()
    if GetResourceState('rpemotes-reborn') ~= 'started' then
        return
    end

    pcall(function()
        exports['rpemotes-reborn']:EmoteCancel(true)
    end)
end

local function saveEquipped(item, slot, backpackId)
    local backpack = Config.Backpacks[item.name]

    if not backpack then
        return false
    end

    local component = backpack.component or 5

    local saved = lib.callback.await(
        'cb-backpacks:server:equip',
        false,

        slot,
        backpackId,
        item.name,
        component,

        baseComponent.drawable,
        baseComponent.texture
    )

    return saved == true
end

local function openBackpackStash(backpackId)
    -- The item was used from the open inventory; reopen it on the stash.
    pcall(function()
        Bridge.Inventory.Close()
    end)

    Wait(250)

    local opened = Bridge.Inventory.OpenStash(backpackId)

    if opened == false then
        notify(
            L('open_failed'),
            'error'
        )
    end
end

local function equipItem(item, slot, backpackId, openInventory)
    if busy then
        return false
    end

    local backpack = Config.Backpacks[item.name]

    if not backpack then
        return false
    end

    busy = true

    local component = backpack.component or 5

    if not equipped then
        baseComponent = {
            component = component,
            drawable = GetPedDrawableVariation(
                PlayerPedId(),
                component
            ),
            texture = GetPedTextureVariation(
                PlayerPedId(),
                component
            ),
        }

        debug(('Saved base clothing: drawable=%s texture=%s'):format(
            baseComponent.drawable,
            baseComponent.texture
        ))
    end

    if not applyBackpackClothing(backpack) then
        baseComponent = nil
        busy = false
        return false
    end

    if not saveEquipped(item, slot, backpackId) then
        restoreBaseClothing()

        busy = false

        notify(
            L('save_failed'),
            'error'
        )

        return false
    end

    equipped = {
        id = backpackId,
        name = item.name,
        slot = slot,
    }

    startAnimation()

    busy = false

    notify(
        L('equipped', backpack.label),
        'success'
    )

    if openInventory then
        openBackpackStash(backpackId)
    end

    return true
end

local function unequip()
    if busy then
        return false
    end

    if not equipped then
        return false
    end

    busy = true

    pcall(function()
        Bridge.Inventory.Close()
    end)

    stopAnimation()

    restoreBaseClothing()

    lib.callback.await(
        'cb-backpacks:server:unequip',
        false
    )

    local oldName = equipped.name

    equipped = nil

    busy = false

    notify(
        L('unequipped', Config.Backpacks[oldName].label),
        'success'
    )

    return true
end

local function useBackpack(data, slotData)
    if busy then
        return
    end

    local itemName = data and data.name

    local slot = slotData and slotData.slot

    if not itemName or not slot then
        return
    end

    if not isBackpack(itemName) then
        return
    end

    debug(('useBackpack called: %s slot=%s'):format(
        itemName,
        slot
    ))

    -- The inventory validates the use server-side.
    Bridge.Inventory.UseItem(
        data,
        function(verified)
            if not verified then
                debug('The inventory rejected the backpack use.')
                return
            end

            CreateThread(function()
                local prepared = lib.callback.await(
                    'cb-backpacks:server:prepare',
                    false,
                    slot
                )

                if not prepared then
                    notify(
                        L('prepare_failed'),
                        'error'
                    )

                    return
                end

                debug(('Backpack prepared: id=%s'):format(
                    prepared.id
                ))

                -- Same physical backpack.
                if equipped and equipped.id == prepared.id then
                    openBackpackStash(prepared.id)
                    return
                end

                -- Different backpack.
                if equipped then
                    stopAnimation()
                    restoreBaseClothing()

                    lib.callback.await(
                        'cb-backpacks:server:unequip',
                        false
                    )

                    equipped = nil
                end

                equipItem(
                    {
                        name = prepared.name,
                        metadata = prepared.metadata,
                    },
                    prepared.slot or slot,
                    prepared.id,
                    true
                )
            end)
        end
    )
end

exports('useBackpack', useBackpack)

-- Inventories without a client use export (e.g. qb-inventory) notify the client.
RegisterNetEvent('cb-backpacks:client:use', function(name, slot)
    useBackpack({ name = name }, { slot = slot })
end)

local restoring = false

local function restoreBackpack()
    if not Config.Restore.enabled or equipped or busy or restoring then
        return
    end

    restoring = true

    CreateThread(function()
        Wait(Config.Restore.delay)
        restoring = false

        local state = lib.callback.await(
            'cb-backpacks:server:getEquipped',
            false
        )

        if not state then
            debug('No persisted equipped backpack.')
            return
        end

        debug(('Persisted backpack found: %s'):format(
            state.backpack_id
        ))

        local slot, item = findBackpackById(
            state.backpack_id
        )

        if not slot or not item then
            debug('Persisted backpack no longer exists.')

            TriggerServerEvent(
                'cb-backpacks:server:verifyEquipped'
            )

            return
        end

        local backpack = Config.Backpacks[item.name]

        if not backpack then
            return
        end

        local ped = PlayerPedId()

        baseComponent = {
            component = state.component_id or 5,
            drawable = tonumber(state.base_drawable) or 0,
            texture = tonumber(state.base_texture) or 0,
        }

        if not applyBackpackClothing(backpack) then
            baseComponent = nil
            return
        end

        equipped = {
            id = state.backpack_id,
            name = item.name,
            slot = slot,
        }

        debug(('Restored backpack %s from slot %s'):format(
            item.name,
            slot
        ))
    end)
end

local function verifyEquippedItem()
    if not equipped then
        return
    end

    local slot, item = findBackpackById(
        equipped.id
    )

    if slot and item then
        -- Slot changed. Keep equipped.
        if slot ~= equipped.slot then
            debug(('Backpack moved %s -> %s'):format(
                equipped.slot,
                slot
            ))

            equipped.slot = slot
        end

        return
    end

    debug('Equipped backpack no longer exists.')

    stopAnimation()

    restoreBaseClothing()

    equipped = nil

    lib.callback.await(
        'cb-backpacks:server:unequip',
        false
    )

    notify(
        L('item_lost'),
        'error'
    )
end

RegisterNetEvent(
    'cb-backpacks:client:forceUnequip',
    function()
        if not equipped then
            return
        end

        stopAnimation()
        restoreBaseClothing()

        equipped = nil
    end
)

if Bridge.Inventory then
    Bridge.Inventory.OnUpdate(function()
        CreateThread(function()
            Wait(150)

            verifyEquippedItem()
        end)
    end)
end

RegisterCommand(
    Config.Command.name,
    function()
        if not Config.Command.enabled then
            return
        end

        if busy then
            return
        end

        if equipped then
            openBackpackStash(equipped.id)
            return
        end

        local state = lib.callback.await(
            'cb-backpacks:server:getEquipped',
            false
        )

        if state then
            local slot, item = findBackpackById(
                state.backpack_id
            )

            if slot and item then
                local backpack = Config.Backpacks[item.name]

                if backpack then
                    baseComponent = {
                        component = state.component_id or 5,
                        drawable = tonumber(state.base_drawable) or 0,
                        texture = tonumber(state.base_texture) or 0,
                    }

                    if applyBackpackClothing(backpack) then
                        equipped = {
                            id = state.backpack_id,
                            name = item.name,
                            slot = slot,
                        }

                        startAnimation()

                        Bridge.Inventory.OpenStash(state.backpack_id)

                        return
                    end
                end
            end
        end

        local items = getPlayerItems()

        for slot, item in pairs(items) do
            if item and isBackpack(item.name) then
                local metadata = item.metadata or {}
                local backpackId = metadata[Config.Metadata.id]

                local prepared = lib.callback.await(
                    'cb-backpacks:server:prepare',
                    false,
                    slot
                )

                if prepared then
                    equipItem(
                        {
                            name = item.name,
                            metadata = prepared.metadata,
                        },
                        slot,
                        prepared.id,
                        true
                    )

                    return
                end
            end
        end

        notify(
            L('no_backpack'),
            'error'
        )
    end,
    false
)

Bridge.OnPlayerLoaded(restoreBackpack)

CreateThread(function()
    Wait(5000)

    restoreBackpack()
end)

AddEventHandler(
    'onResourceStop',
    function(resource)
        if resource ~= GetCurrentResourceName() then
            return
        end

        stopAnimation()
    end
)

exports('getEquippedBackpack', function()
    return equipped
end)

exports('isEquipped', function()
    return equipped ~= nil
end)
