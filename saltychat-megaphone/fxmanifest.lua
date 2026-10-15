-- https://saltyhub.net
-- Megaphone Script for saltychat. Keep in mind that we can't help you with implementation!
author 'https://myprofile.lol/alva98'
fx_version 'cerulean'

game 'gta5'
lua54 'yes'

version '1.0.0'

shared_scripts {
  "config.lua"
}

client_scripts {
  'client/main.lua'
}

escrow_ignore {
  "config.lua",
}

dependency '/assetpacks'