fx_version 'cerulean'
games { 'gta5' }
author 'maku#5434'
description 'garage script using polyzones'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'configs/sh_config.lua'
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_menus.lua',
    'client/cl_impound.lua',
    'client/cl_esx.lua',
    'client/cl_ox.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'configs/sv_import.lua',
    'server/sv_commands.lua',
    'server/sv_main.lua',
    'server/sv_impound.lua'
}

dependency {
    'ox_lib'
}
