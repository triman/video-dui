--resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af938'
fx_version 'cerulean'
game 'gta5'

dependency 'yarn'

client_scripts {	
	'client/utils.lua',
	'client/client.lua'
}

server_scripts {
	'server.js'
}