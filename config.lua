-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ═════  ██████╗ ██████╗     ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗ ███████╗ ═════
-- ═════ ██╔════╝ ██╔══██╗    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗██╔════╝ ═════
-- ═════ ██║      ██████╔╝    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║███████╗ ═════
-- ═════ ██║      ██╔══██╗    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║╚════██║ ═════
-- ═════ ╚██████╗ ██████╔╝    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝███████║ ═════
-- ═════  ╚═════╝ ╚═════╝     ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝ ═════
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ═════            CB │ STUDIOS - DISCORD:https://discord.gg/hsx6AvBg5s             ═════
-- ═══════════════════════════════════════════════════════════════════════════════════════

Config = {}

-- ═════════════════════════════════════════════════════════════════════
--  GENERAL
-- ═════════════════════════════════════════════════════════════════════

Config.Debug  = false  -- Print debug messages in the console.
Config.Locale = 'es'   -- Notification language: 'es', 'en' or 'tr' (see locales/).

-- ═════════════════════════════════════════════════════════════════════
--  BRIDGE  (see bridge/)
--  Framework : 'auto', 'qbx', 'qb', 'esx' or 'standalone'.
--  Inventory : 'auto', 'ox_inventory' or 'qb-inventory'.
-- ═════════════════════════════════════════════════════════════════════

Config.Framework = 'auto'
Config.Inventory = 'auto'

-- ═════════════════════════════════════════════════════════════════════
--  VERSION CHECK
--  Prints in the server console whether a newer version is published.
--  Only reads a public JSON file. It never sends server data.
--  enabled : false disables the check.
--  url     : metadata file (resource, version, changelog, store).
--  delay   : ms to wait after start before printing.
-- ═════════════════════════════════════════════════════════════════════

Config.VersionCheck = {
    enabled = true,
    url = 'https://raw.githubusercontent.com/Pichirin-CB/cb-studios-versions/main/versions/cb-backpacks.json',
    delay = 5000,
}
-- ═════════════════════════════════════════════════════════════════════
--  BACKPACKS
--
--  Key        Item name (must exist in ox_inventory/data/items.lua).
--  label      Name shown in the stash and notifications.
--  slots      Number of inventory slots.
--  maxWeight  Maximum weight in grams.
--  collection Clothing collection name (name of the clothing pack).
--  localDrawable  Drawable index inside that collection (0-8).
--                 The global index is resolved at runtime.
--  drawable   Fallback global drawable, only used without localDrawable.
--  texture    Texture variation.
--  component  Ped component (5 = bags).
--
--  NOTE: local index 1 of velxor_backpack_pack has no visible model.
-- ═════════════════════════════════════════════════════════════════════

local CLOTHING_PACK = 'velxor_backpack_pack'

Config.Backpacks = {

    -- ── Small ────────────────────────────────────────────────────────
    ['backpack1'] = {
        label         = 'Mochila Común',
        slots         = 12,
        maxWeight     = 15000,
        collection    = CLOTHING_PACK,
        localDrawable = 7,
        drawable      = 118,
        texture       = 0,
        component     = 5,
    },

    ['techbackpack'] = {
        label         = 'Mochila Tecnológica',
        slots         = 12,
        maxWeight     = 15000,
        collection    = CLOTHING_PACK,
        localDrawable = 2,
        drawable      = 113,
        texture       = 0,
        component     = 5,
    },

    -- ── Medium ───────────────────────────────────────────────────────
    ['backpack2'] = {
        label         = 'Mochila de Supervivencia',
        slots         = 18,
        maxWeight     = 22000,
        collection    = CLOTHING_PACK,
        localDrawable = 3,
        drawable      = 114,
        texture       = 0,
        component     = 5,
    },

    ['duffle1'] = {
        label         = 'Mochila de Supervivencia',
        slots         = 18,
        maxWeight     = 25000,
        collection    = CLOTHING_PACK,
        localDrawable = 6,
        drawable      = 117,
        texture       = 0,
        component     = 5,
    },

    -- ── Large ────────────────────────────────────────────────────────
    ['backpack3'] = {
        label         = 'Mochila Táctica',
        slots         = 24,
        maxWeight     = 30000,
        collection    = CLOTHING_PACK,
        localDrawable = 4,
        drawable      = 115,
        texture       = 0,
        component     = 5,
    },

    ['backpack4'] = {
        label         = 'Mochila Militar',
        slots         = 30,
        maxWeight     = 38000,
        collection    = CLOTHING_PACK,
        localDrawable = 5,
        drawable      = 116,
        texture       = 0,
        component     = 5,
    },

    -- ── Extra large ──────────────────────────────────────────────────
    ['backpack5'] = {
        label         = 'Mochila de Explorador',
        slots         = 36,
        maxWeight     = 45000,
        collection    = CLOTHING_PACK,
        localDrawable = 0,
        drawable      = 112,
        texture       = 0,
        component     = 5,
    },

    ['bigcamperbag'] = {
        label         = 'Mochila Camper Grande',
        slots         = 36,
        maxWeight     = 45000,
        collection    = CLOTHING_PACK,
        localDrawable = 8,
        drawable      = 119,
        texture       = 0,
        component     = 5,
    },
}

-- ═════════════════════════════════════════════════════════════════════
--  STORAGE
--  Do not change these on a server that already has backpacks.
-- ═════════════════════════════════════════════════════════════════════

Config.Metadata = {
    id = 'cb_backpack_id',  -- Item metadata key that stores the backpack ID.
}

Config.Stash = {
    prefix = 'cb_backpack_', -- Prefix of the generated stash IDs.
}

Config.Database = {
    table = 'cb_backpacks',  -- SQL table with the equipped state.
}

-- ═════════════════════════════════════════════════════════════════════
--  ANIMATION  (rpemotes-reborn)
-- ═════════════════════════════════════════════════════════════════════

Config.Animation = {
    enabled          = true,
    emote            = 'backpack',
    duration         = 900,  -- ms before the emote is cancelled.
    propCleanupDelay = 75,   -- ms (currently unused).
}

-- ═════════════════════════════════════════════════════════════════════
--  RESTORE  (re-equip after reconnect / resource restart)
-- ═════════════════════════════════════════════════════════════════════

Config.Restore = {
    enabled = true,
    delay   = 1500,  -- ms to wait before restoring.
}

-- ═════════════════════════════════════════════════════════════════════
--  COMMAND
-- ═════════════════════════════════════════════════════════════════════

Config.Command = {
    enabled = true,
    name    = 'backpack',
}