name "Jim_Bridge"
author "Jimathy"
version "2.1.03"
description "Framework Bridge By Jimathy"
fx_version "cerulean"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
games { 'gta5', 'rdr3' }
lua54 'yes'

files {
    'starter.lua',
    'shared/*.lua',
    'shared/make/*.lua',
    'shared/scaleforms/*.lua',
}

-- Version checker
server_scripts {
    'frameworkCache.lua',
    '_versioncheck.lua',
}

client_scripts {
    'clientFrameworkCache.lua',
    'ui_modules/*.lua',
}

suppress_updates 'false'   -- set to 'true' to disable update pings