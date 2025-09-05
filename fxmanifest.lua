fx_version 'cerulean'
game 'gta5'
name 'Romeo'
author 'Cascade'
version '1.0.0'
description 'NPC relationship system using ox_lib'
dependency 'ox_lib'
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
client_scripts {
    'client.lua'
}
server_scripts {
    'server.lua'
}
