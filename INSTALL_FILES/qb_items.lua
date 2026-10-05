-- qb-inventory items. Add them to qb-core/shared/items.lua (inside QBShared.Items).
-- `unique = true` is required: the backpack id is stored in `info`.
-- Images must exist in qb-inventory/html/images (<name>.png).

return {
    ['backpack1'] = {
        name = 'backpack1',
        label = 'Mochila Común',
        weight = 0,
        type = 'item',
        image = 'backpack1.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Una mochila sencilla para transportar suministros básicos.',
    },

    ['backpack2'] = {
        name = 'backpack2',
        label = 'Mochila de Supervivencia',
        weight = 0,
        type = 'item',
        image = 'backpack2.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Mochila resistente diseñada para transportar suministros de supervivencia.',
    },

    ['backpack3'] = {
        name = 'backpack3',
        label = 'Mochila Táctica',
        weight = 0,
        type = 'item',
        image = 'backpack3.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Mochila táctica con espacio adicional para equipo y suministros.',
    },

    ['backpack4'] = {
        name = 'backpack4',
        label = 'Mochila Militar',
        weight = 0,
        type = 'item',
        image = 'backpack4.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Mochila militar robusta diseñada para transportar una gran cantidad de equipo.',
    },

    ['backpack5'] = {
        name = 'backpack5',
        label = 'Mochila de Explorador',
        weight = 0,
        type = 'item',
        image = 'backpack5.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Mochila de gran capacidad ideal para largas expediciones y exploración.',
    },

    ['duffle1'] = {
        name = 'duffle1',
        label = 'Mochila de Supervivencia',
        weight = 0,
        type = 'item',
        image = 'duffle1.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Bolso resistente y práctico para transportar suministros esenciales.',
    },

    ['bigcamperbag'] = {
        name = 'bigcamperbag',
        label = 'Mochila Camper Grande',
        weight = 0,
        type = 'item',
        image = 'bigcamperbag.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Mochila de gran tamaño diseñada para campamentos, viajes y largas expediciones.',
    },

    ['techbackpack'] = {
        name = 'techbackpack',
        label = 'Mochila Tecnológica',
        weight = 0,
        type = 'item',
        image = 'techbackpack.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Mochila equipada con dispositivos y componentes electrónicos para comunicaciones y supervivencia.',
    },
}
