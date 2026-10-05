fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'CB Studios'
description 'Wearable backpacks with persistent inventory stashes. Built-in framework/inventory bridge (ox_inventory). Optional: rpemotes-reborn.'
version '1.0.0'

repository 'https://github.com/Pichirin-CB/cb-backpacks'

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/init.lua',
    'locales/en.lua',
    'locales/es.lua',
    'locales/tr.lua',
    'bridge/shared.lua'
}

client_scripts {
    'bridge/framework_client.lua',
    'bridge/inventory_client.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/framework_server.lua',
    'bridge/inventory_server.lua',
    'server/main.lua'
}