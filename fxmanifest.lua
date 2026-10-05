fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'CB Studios'
description 'Wearable backpacks with persistent ox_inventory containers, illenium-appearance clothing and rpemotes animations.'
version '1.0.0'

repository 'https://github.com/Pichirin-CB/cb-backpacks'

dependencies {
    'ox_lib',
    'ox_inventory',
    'illenium-appearance',
    'rpemotes-reborn'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
