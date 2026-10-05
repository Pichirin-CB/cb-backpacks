local equipped = nil
local baseComponent = nil
local actionBusy = false
local lastUsed = {}

local function debug(...)
    if Config.Debug then
        print('[cb-backpacks]', ...)
    end
end

local function notify(description, type)
    lib.notify({
        title = 'Mochilas',
        description = description,
        type = type or 'inform',
    })
end

local function isBackpack(itemName)
    return itemName and Config.Backpacks[itemName] ~= nil
end

local function getCurrentComponents()
    local ped = cache.ped
    local components = {}

    for componentId = 0, 11 do
        components[#components + 1] = {
            component_id = componentId,
            drawable = GetPedDrawableVariation(ped, componentId),
            texture = GetPedTextureVariation(ped, componentId),
        }
    end

    return components
end

local function getCurrentProps()
    local ped = cache.ped
    local props = {}

    for propId = 0, 7 do
        local drawable = GetPedPropIndex(ped, propId)
        local texture = drawable >= 0 and GetPedPropTextureIndex(ped, propId) or 0

        props[#props + 1] = {
            prop_id = propId,
            drawable = drawable,
            texture = texture,
        }
    end

    return props
end

local function getAppearanceModel()
    local model = GetEntityModel(cache.ped)

    if model == joaat('mp_f_freemode_01') then
        return 'mp_f_freemode_01'
    end

    if model == joaat('mp_m_freemode_01') then
        return 'mp_m_freemode_01'
    end

    return nil
end

local function applyAppearanceComponents(components, props)
    local model = getAppearanceModel()

    -- illenium-appearance's public changeOutfit event is used so the
    -- appearance resource remains the authority for clothing changes.
    if not model then
        notify('Este personaje no usa un modelo freemode compatible.', 'error')
        return false
    end

    TriggerEvent('illenium-appearance:client:changeOutfit', {
        model = model,
        components = components,
        props = props,
        disableSave = true,
    })

    return true
end

local function playBackpackAnimation()
    if not Config.Animation.enabled then return end

    if GetResourceState('rpemotes-reborn') ~= 'started' then
        debug('rpemotes-reborn is not started; skipping animation')
        return
    end

    -- backpack is a PropEmote in rpemotes-reborn, so use its native
    -- EmoteMenuStart handler with the correct emote type.
    local started = false

    if EmoteMenuStart and EmoteType and EmoteType.PROP_EMOTES then
        started = pcall(function()
            EmoteMenuStart(Config.Animation.emote, nil, EmoteType.PROP_EMOTES)
        end)
    end

    if not started then
        return
    end

    -- The rpemotes backpack emote has a prop. The real backpack is the
    -- clothing component, so remove only the temporary emote prop.
    if Config.Animation.propCleanupDelay then
        SetTimeout(Config.Animation.propCleanupDelay, function()
            if DestroyAllProps then
                pcall(DestroyAllProps)
            end
        end)
    end

    SetTimeout(Config.Animation.duration, function()
        if IsInAnimation and EmoteCancel then
            pcall(EmoteCancel, true)
        end
    end)
end

local function stopBackpackAnimation()
    if GetResourceState('rpemotes-reborn') ~= 'started' then return end

    pcall(function()
        exports['rpemotes-reborn']:EmoteCancel()
    end)
end

local function buildComponentsWithBackpack(backpack)
    local components = getCurrentComponents()
    local target = backpack.component or 5

    for i = 1, #components do
        if components[i].component_id == target then
            components[i].drawable = backpack.drawable
            components[i].texture = backpack.texture
            break
        end
    end

    return components
end

local function equipBackpack(itemName, slot)
    local backpack = Config.Backpacks[itemName]
    if not backpack then return false end

    if actionBusy then return false end
    actionBusy = true

    local prepared = lib.callback.await('cb-backpacks:server:prepareBackpack', false, slot)
    if not prepared then
        actionBusy = false
        notify('No se pudo preparar esta mochila.', 'error')
        return false
    end

    if equipped and equipped.slot == slot then
        -- Toggle off.
        pcall(function()
            exports.ox_inventory:closeInventory()
        end)
        stopBackpackAnimation()

        if baseComponent then
            local components = getCurrentComponents()
            local target = backpack.component or 5

            for i = 1, #components do
                if components[i].component_id == target then
                    components[i].drawable = baseComponent.drawable
                    components[i].texture = baseComponent.texture
                    break
                end
            end

            applyAppearanceComponents(components, getCurrentProps())
        end

        equipped = nil
        baseComponent = nil
        actionBusy = false
        notify('Mochila retirada.', 'success')
        return true
    end

    -- Switching from one backpack to another keeps the original clothing
    -- underneath, instead of permanently setting component 5 to zero.
    if not equipped then
        local componentId = backpack.component or 5
        baseComponent = {
            drawable = GetPedDrawableVariation(cache.ped, componentId),
            texture = GetPedTextureVariation(cache.ped, componentId),
        }
    end

    if equipped then
        stopBackpackAnimation()
    end

    local components = buildComponentsWithBackpack(backpack)
    if not applyAppearanceComponents(components, getCurrentProps()) then
        actionBusy = false
        return false
    end

    equipped = {
        name = itemName,
        slot = slot,
        container = prepared,
    }

    playBackpackAnimation()

    actionBusy = false
    notify(('Equipaste %s.'):format(backpack.label), 'success')
    return true
end

local function handleUsedItem(name, slot)
    if not isBackpack(name) then return end

    local key = ('%s:%s'):format(slot, name)
    local now = GetGameTimer()

    -- Protect against duplicate use notifications/events.
    if lastUsed[key] and now - lastUsed[key] < 750 then
        return
    end

    lastUsed[key] = now

    CreateThread(function()
        Wait(50)
        equipBackpack(name, slot)
    end)
end

-- First use of an old backpack without metadata.container comes through the
-- client export. Later uses are handled directly by ox_inventory's container
-- path and arrive here through ox_inventory:usedItem.
exports('useBackpack', function(data, slot)
    local itemName = data and data.name or slot and slot.name
    local slotId = slot and slot.slot or data and data.slot

    if not isBackpack(itemName) or not slotId then return end

    local container = lib.callback.await(
        'cb-backpacks:server:prepareBackpack',
        false,
        slotId
    )

    if not container then
        notify('No se pudo preparar el inventario de la mochila.', 'error')
        return
    end

    lastUsed[('%s:%s'):format(slotId, itemName)] = GetGameTimer()
    equipBackpack(itemName, slotId)

    -- The metadata update is sent back by ox_inventory. Give it a moment
    -- before opening the container so the client has the generated ID.
    SetTimeout(100, function()
        exports.ox_inventory:openInventory('container', slotId)
    end)
end)

AddEventHandler('ox_inventory:usedItem', function(name, slotId)
    handleUsedItem(name, slotId)
end)

AddEventHandler('ox_inventory:updateInventory', function(changes)
    if not equipped then return end

    local changed = changes and changes[equipped.slot]
    if changed == false or (changed and changed.name ~= equipped.name) then
        -- Backpack was moved/removed from its equipped slot. We cannot safely
        -- keep the clothing item equipped if that exact slot changed.
        CreateThread(function()
            Wait(100)
            local items = exports.ox_inventory:GetPlayerItems()
            local slot = items and items[equipped.slot]

            if not slot or slot.name ~= equipped.name then
                stopBackpackAnimation()

                if baseComponent then
                    local components = getCurrentComponents()
                    local target = Config.Backpacks[equipped.name].component or 5

                    for i = 1, #components do
                        if components[i].component_id == target then
                            components[i].drawable = baseComponent.drawable
                            components[i].texture = baseComponent.texture
                            break
                        end
                    end

                    applyAppearanceComponents(components, getCurrentProps())
                end

                equipped = nil
                baseComponent = nil
            end
        end)
    end
end)

RegisterCommand(Config.Command.name, function()
    if not Config.Command.enabled then return end

    if equipped then
        equipBackpack(equipped.name, equipped.slot)
        return
    end

    local items = exports.ox_inventory:GetPlayerItems()
    for slot, item in pairs(items or {}) do
        if item and isBackpack(item.name) then
            equipBackpack(item.name, slot)
            return
        end
    end

    notify('No tienes una mochila.', 'error')
end, false)

AddEventHandler('illenium-appearance:client:appearanceLoaded', function()
    if not Config.Restore.enabled then return end

    CreateThread(function()
        Wait(Config.Restore.delay)

        -- We intentionally do not guess which backpack was equipped after a
        -- hard character/resource restart. The item remains persistent in
        -- ox_inventory and can be equipped normally by using it.
    end)
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if not Config.Restore.enabled then return end
    -- Qbox keeps this compatibility event for QB resources.
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopBackpackAnimation()
end)

exports('getEquippedBackpack', function()
    return equipped
end)

exports('isEquipped', function()
    return equipped ~= nil
end)
