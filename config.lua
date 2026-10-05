Config = {}

Config.Debug = false

-- Component 5 is the GTA V bag/parachute clothing component.
-- Put your REAL clothing drawable/texture values here.
-- Do not use these example values until you verify them in your clothing pack.
Config.Backpacks = {
    ['backpack1'] = {
        label = 'Mochila Común',
        slots = 12,
        maxWeight = 15000,
        drawable = 118, -- CHANGE
        texture = 0,    -- CHANGE
        component = 5,
    },
    ['backpack2'] = {
        label = 'Mochila de Supervivencia',
        slots = 18,
        maxWeight = 22000,
        drawable = 114, -- CHANGE
        texture = 0,  -- CHANGE
        component = 5,
    },
    ['backpack3'] = {
        label = 'Mochila Táctica',
        slots = 24,
        maxWeight = 30000,
        drawable = 115, -- CHANGE
        texture = 0,  -- CHANGE
        component = 5,
    },
    ['backpack4'] = {
        label = 'Mochila Militar',
        slots = 30,
        maxWeight = 38000,
        drawable = 116, -- CHANGE
        texture = 0,  -- CHANGE
        component = 5,
    },
    ['backpack5'] = {
        label = 'Mochila de Explorador',
        slots = 36,
        maxWeight = 45000,
        drawable = 112, -- CHANGE
        texture = 0,  -- CHANGE
        component = 5,
    },
    ['duffle1'] = {
        label = 'Mochila de Supervivencia',
        slots = 18,
        maxWeight = 25000,
        drawable = 117, -- CHANGE
        texture = 0,  -- CHANGE
        component = 5,
    },
    ['bigcamperbag'] = {
        label = 'Mochila Camper Grande',
        slots = 36,
        maxWeight = 45000,
        drawable = 119, -- CHANGE
        texture = 0,    -- CHANGE
        component = 5,
    },
    ['techbackpack'] = {
        label = 'Mochila Tecnológica',
        slots = 12,
        maxWeight = 15000,
        drawable = 113, -- CHANGE
        texture = 0,    -- CHANGE
        component = 5,
    },
}

Config.Animation = {
    -- rpemotes-reborn contains an emote named "backpack".
    -- The resource starts it and immediately removes its prop, because the
    -- actual backpack is the clothing component managed by illenium-appearance.
    emote = 'backpack',
    enabled = true,
    propCleanupDelay = 75,
    duration = 900,
}

Config.Restore = {
    -- Restore the backpack clothing after the character is loaded.
    enabled = true,
    delay = 1500,
}

Config.Command = {
    enabled = true,
    name = 'backpack',
}
