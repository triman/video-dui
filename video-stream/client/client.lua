local scale = 1.5
local screenWidth = math.floor(1280 / scale)
local screenHeight = math.floor(720 / scale)

local endpoint = SplitHostPort(GetCurrentServerEndpoint())

-- use client connecting endpoint
local streamURL = string.format("http://%s:3000/dui/index.html", endpoint)
local streamOfflineURL = string.format("http://%s:3000/dui/off.html", endpoint)

local duiURL

local txd = CreateRuntimeTxd('video')
local duiObj = CreateDui(streamOfflineURL, screenWidth, screenHeight)
local dui = GetDuiHandle(duiObj)
local tx = CreateRuntimeTextureFromDuiHandle(txd, 'test', dui)
local streamOnline = false

-- Receive status event
RegisterNetEvent('video-stream:status')
AddEventHandler('video-stream:status', function (active)
	if active then
		print('[video-stream] stream online')
		streamOnline = true
	else
		print('[video-stream] stream offline')
		streamOnline = false
	end
end)

function getDuiURL () return duiURL end

function setDuiURL (url)
	duiURL = url

	SetDuiUrl(duiObj, url)
end

local screenPositions = {}

function CreateScreen()
    local screenModel = GetHashKey('v_ilev_cin_screen')
    local playerPed = PlayerPedId()
	local screenCoords = GetEntityCoords(playerPed)
    local handle = CreateNamedRenderTargetForModel('cinscreen', screenModel)
   
    -- create screen at player coords
	LoadModel(screenModel)
	screenEntity = CreateObjectNoOffset(screenModel, screenCoords.x, screenCoords.y, screenCoords.z, 0, true, false)
	SetEntityHeading(screenEntity, GetEntityHeading(playerPed))
	SetEntityCoords(screenEntity, GetEntityCoords(screenEntity))
	SetModelAsNoLongerNeeded(screenModel)
    screenPositions[#screenPositions + 1] = screenCoords;

    CreateThread(function ()
        
        local playerPed
        local playerCoords
        local inRange = false

        
        -- Give time for resource to start
        Wait(3500)
    
        -- Check stream status
        TriggerServerEvent('video-stream:status')    
        while true do
            playerPed = PlayerPedId()
            playerCoords = GetEntityCoords(playerPed)
            
            inRange = false

            for i = 1, #screenPositions do
                if GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, screenPositions[i].x, screenPositions[i].y, screenPositions[i].z, true) < 30 then
                    inRange = true
                end
            end
    
            

            if streamOnline and inRange then
                if getDuiURL() ~= streamURL then
                    setDuiURL(streamURL)
                    Wait(1000)
                end
            else
                if getDuiURL() ~= streamOfflineURL then
                    setDuiURL(streamOfflineURL)
                end
            end
    
            -- Check distance between player and screen
            if inRange then
                -- Draw screen in range
                SetTextRenderId(handle)
                Set_2dLayer(4)
                SetScriptGfxDrawBehindPausemenu(1)
                DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)
                DrawSprite("video", "test", 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId()) -- reset
                SetScriptGfxDrawBehindPausemenu(0)
            else
                if getDuiURL() ~= streamOfflineURL then
                    setDuiURL(streamOfflineURL)
                end
            end
    
            Wait(0)
        end
    end)

end

-- Command
RegisterCommand('video-stream', function (source, arg, rawInput)
	CreateScreen()
end)

-- Cleanup
AddEventHandler('onResourceStop', function (resource)
	if resource == GetCurrentResourceName() then
		SetDuiUrl(duiObj, 'about:blank')
		DestroyDui(duiObj)
		ReleaseNamedRendertarget('tvscreen')

        for i = 1, #screenPositions do
            entity = GetClosestObjectOfType(screenPositions[i].x, screenPositions[i].y, screenPositions[i].z, 10.0, screenModel, false, false, false)
            SetEntityAsMissionEntity(entity, false, true)
		    DeleteObject(entity)
        end
	end
end)