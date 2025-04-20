name "Jim_Bridge"
author "Jimathy"
version "2.0"
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

-- NUI Menu Loading
client_scripts { 'nui/*.lua' }
ui_page 'nui/index.html'
files { 'nui/index.html', 'nui/script.js', 'nui/style.css' }