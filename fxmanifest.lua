fx_version 'cerulean'
game 'gta5'

description 'TS Scripts - Radio in React Typescript with Mantine V7'
author 'TS Scripts - Thomas'
version '1.0.0'

ui_page 'web/build/index.html'

shared_scripts {
  'shared/**/*',
  '@ox_lib/init.lua',
  '@qb-core/shared/locale.lua',  -- Replace with the QBCore shared library
  'locales/en.lua',              -- Add if you use localization (adjust accordingly)
  'config.lua'                   -- Assuming there's a config.lua file used for configuration
}

client_scripts {
  '@qb-core/client/player.lua',   -- Replace with the QBCore player module
  'client/**/*'
}

server_script 'server/**/*'

files {
  'web/build/index.html',
  'web/build/**/*',
}

dependency 'pma-voice'

lua54 'yes'
use_experimental_fxv2_oal 'yes'
