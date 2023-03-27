fx_version 'cerulean'
game 'gta5'
ui_page 'html/index.html'
lua54 'on'

shared_scripts {
	'@ox_lib/init.lua',
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',	
	'config.lua',
	'data/config_vehicles.lua',
	'locale/*.lua',
	'framework/sv_wrapper.lua',
	"server/server.lua"
}
client_scripts {
	'config.lua',
	'data/config_vehicles.lua',
	'locale/*.lua',
	'framework/cl_wrapper.lua',
	"client/client.lua",
}

files {
	'html/index.html',
	'html/fonts/*',
	'html/brands/*.png',
	'html/parts/*.png',
	'html/style.css',
	'html/script.js',
	'html/audio/*.ogg',
}