fx_version 'cerulean'
games { 'gta5' }
author 'maku#5434'
description 'garage script using polyzones'
lua54 'yes'

client_scripts {
    'client/cl_main.lua',
    'client/cl_menus.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_commands.lua',
    'server/sv_main.lua'
}
