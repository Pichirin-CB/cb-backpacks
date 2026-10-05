local Inventory = Bridge.Inventory

local Backpacks = Config.Backpacks

local function debug(...)
    if not Config.Debug then
        return
    end

    print('[cb-backpacks]', ...)
end

local function generateBackpackId()
    return ('%s%s_%s_%s'):format(
        Config.Stash.prefix,
        os.time(),
        math.random(100000, 999999),
        math.random(100000, 999999)
    )
end

local function registerBackpackStash(backpackId, backpack)
    if not backpackId or not backpack then
        return false
    end

    if not Inventory then
        return false
    end

    Inventory.RegisterStash(
        backpackId,
        backpack.label,
        backpack.slots,
        backpack.maxWeight
    )

    debug(('Registered stash %s (%s slots / %s g)'):format(
        backpackId,
        backpack.slots,
        backpack.maxWeight
    ))

    return true
end

local function createDatabase()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `owner` VARCHAR(100) NOT NULL,
            `backpack_id` VARCHAR(120) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `component_id` TINYINT UNSIGNED NOT NULL DEFAULT 5,
            `base_drawable` SMALLINT NOT NULL DEFAULT 0,
            `base_texture` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                ON UPDATE CURRENT_TIMESTAMP,

            PRIMARY KEY (`owner`),
            UNIQUE KEY `cb_backpacks_backpack_id` (`backpack_id`)
        ) ENGINE=InnoDB
        DEFAULT CHARSET=utf8mb4
        COLLATE=utf8mb4_unicode_ci;
    ]]):format(Config.Database.table))

    -- Migrate tables created with the old schema (container_id -> backpack_id).
    local function hasColumn(name)
        return MySQL.scalar.await([[
            SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
        ]], { Config.Database.table, name }) > 0
    end

    if not hasColumn('backpack_id') and hasColumn('container_id') then
        MySQL.query.await(([[
            ALTER TABLE `%s`
            DROP INDEX `cb_backpacks_container_id`,
            CHANGE `container_id` `backpack_id` VARCHAR(120) NOT NULL,
            ADD UNIQUE KEY `cb_backpacks_backpack_id` (`backpack_id`)
        ]]):format(Config.Database.table))
        print('[cb-backpacks] Migrated column container_id -> backpack_id.')
    end

    print('[cb-backpacks] Database ready.')
end

local function saveEquipped(
    source,
    backpackId,
    itemName,
    componentId,
    baseDrawable,
    baseTexture
)
    local owner = Bridge.GetIdentifier(source)

    if not owner then
        return false
    end

    MySQL.insert.await(([[
        INSERT INTO `%s`
        (
            owner,
            backpack_id,
            item_name,
            component_id,
            base_drawable,
            base_texture
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            backpack_id = VALUES(backpack_id),
            item_name = VALUES(item_name),
            component_id = VALUES(component_id),
            base_drawable = VALUES(base_drawable),
            base_texture = VALUES(base_texture)
    ]]):format(Config.Database.table), {
        owner,
        backpackId,
        itemName,
        componentId,
        baseDrawable,
        baseTexture
    })

    debug(('Saved equipped backpack: owner=%s id=%s item=%s'):format(
        owner,
        backpackId,
        itemName
    ))

    return true
end

local function clearEquipped(source)
    local owner = Bridge.GetIdentifier(source)

    if not owner then
        return false
    end

    MySQL.query.await(
        ('DELETE FROM `%s` WHERE owner = ?'):format(Config.Database.table),
        { owner }
    )

    debug(('Cleared equipped backpack for %s'):format(owner))

    return true
end

local function getEquipped(source)
    local owner = Bridge.GetIdentifier(source)

    if not owner then
        return nil
    end

    return MySQL.single.await(
        ('SELECT * FROM `%s` WHERE owner = ? LIMIT 1'):format(Config.Database.table),
        { owner }
    )
end

lib.callback.register('cb-backpacks:server:prepare', function(source, slot)
    slot = tonumber(slot)

    if not slot then
        return false
    end

    local item = (Inventory and Inventory.GetSlot(source, slot))

    if not item then
        return false
    end

    local backpack = Backpacks[item.name]

    if not backpack then
        return false
    end

    local metadata = item.metadata or {}
    local backpackId = metadata[Config.Metadata.id]

    if not backpackId then
        backpackId = generateBackpackId()

        metadata[Config.Metadata.id] = backpackId

        local success = Inventory.SetMetadata(
            source,
            slot,
            metadata
        )

        if not success then
            debug(('SetMetadata failed for %s slot %s'):format(
                item.name,
                slot
            ))

            return false
        end

        debug(('Created backpack ID %s for %s slot %s'):format(
            backpackId,
            item.name,
            slot
        ))
    end

    registerBackpackStash(backpackId, backpack)

    return {
        id = backpackId,
        name = item.name,
        label = backpack.label,
        slots = backpack.slots,
        maxWeight = backpack.maxWeight,
        metadata = metadata,
    }
end)

lib.callback.register('cb-backpacks:server:getEquipped', function(source)
    return getEquipped(source)
end)

lib.callback.register('cb-backpacks:server:equip', function(
    source,
    slot,
    backpackId,
    itemName,
    componentId,
    baseDrawable,
    baseTexture
)
    slot = tonumber(slot)

    if not slot or not backpackId or not itemName then
        return false
    end

    local item = (Inventory and Inventory.GetSlot(source, slot))

    if not item then
        return false
    end

    if item.name ~= itemName then
        return false
    end

    local metadata = item.metadata or {}

    if metadata[Config.Metadata.id] ~= backpackId then
        return false
    end

    if not Backpacks[itemName] then
        return false
    end

    return saveEquipped(
        source,
        backpackId,
        itemName,
        tonumber(componentId) or 5,
        tonumber(baseDrawable) or 0,
        tonumber(baseTexture) or 0
    )
end)

lib.callback.register('cb-backpacks:server:unequip', function(source)
    return clearEquipped(source)
end)

lib.callback.register('cb-backpacks:server:validate', function(
    source,
    backpackId
)
    if not backpackId then
        return false
    end

    local items = (Inventory and Inventory.GetItems(source))

    for slot, item in pairs(items or {}) do
        if item
            and Backpacks[item.name]
            and item.metadata
            and item.metadata[Config.Metadata.id] == backpackId
        then
            return {
                exists = true,
                slot = slot,
                name = item.name,
                metadata = item.metadata,
            }
        end
    end

    return {
        exists = false
    }
end)

CreateThread(function()
    math.randomseed(os.time())

    createDatabase()

    -- Re-register persisted backpack stashes after the inventory starts.
    Wait(1000)

    local rows = MySQL.query.await(([[
        SELECT backpack_id, item_name
        FROM `%s`
    ]]):format(Config.Database.table)) or {}

    for i = 1, #rows do
        local row = rows[i]
        local backpack = Backpacks[row.item_name]

        if backpack then
            registerBackpackStash(row.backpack_id, backpack)
        end
    end

    debug(('Loaded %s persisted backpack records.'):format(#rows))
end)

AddEventHandler('onServerResourceStart', function(resource)
    if not Inventory or resource ~= Inventory.resource then
        return
    end

    Wait(1000)

    local rows = MySQL.query.await(([[
        SELECT backpack_id, item_name
        FROM `%s`
    ]]):format(Config.Database.table)) or {}

    for i = 1, #rows do
        local row = rows[i]
        local backpack = Backpacks[row.item_name]

        if backpack then
            registerBackpackStash(row.backpack_id, backpack)
        end
    end
end)

-- Remove the equipped record if the exact backpack no longer exists.
-- This is a safety check used by the client as well.
RegisterNetEvent('cb-backpacks:server:verifyEquipped', function()
    local source = source

    local equipped = getEquipped(source)

    if not equipped then
        return
    end

    local items = (Inventory and Inventory.GetItems(source))

    local found = false

    for _, item in pairs(items or {}) do
        if item
            and item.metadata
            and item.metadata[Config.Metadata.id] == equipped.backpack_id
        then
            found = true
            break
        end
    end

    if not found then
        clearEquipped(source)

        TriggerClientEvent(
            'cb-backpacks:client:forceUnequip',
            source
        )
    end
end)

AddEventHandler('playerDropped', function()
    local source = source

    debug(('Player %s disconnected. Backpack state remains persistent.'):format(
        source
    ))
end)
if Inventory and Inventory.RegisterUseable then
    local names = {}

    for name in pairs(Backpacks) do
        names[#names + 1] = name
    end

    Inventory.RegisterUseable(names, function(source, name, slot)
        if slot then
            TriggerClientEvent('cb-backpacks:client:use', source, name, slot)
        end
    end)
end