if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function ShowNotification(text)
	ESX.ShowNotification(text)
end

function GetPlayersInArea(coords, radius)
    local coords = coords or GetEntityCoords(PlayerPedId())
    local radius = radius or 3.0
    local list = ESX.Game.GetPlayersInArea(coords, radius)
    local players = {}
    for _, player in pairs(list) do 
        if player ~= PlayerId() then
            players[#players + 1] = player
        end
    end
    return players
end

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
    TriggerServerEvent("pickle_consumables:initializePlayer")
end)

RegisterNetEvent("pickle_consumables:executeStatus", function(status, value)
    if value >= 0 then
        TriggerEvent('esx_status:add', status, value)
    else
        TriggerEvent('esx_status:remove', status, -value)
    end
end)

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.
    print("The only supported inventory for ESX is ox_inventory and qs-inventory, if you would like to port to a different inventory, please use the example shown in the inventory folder.")
end)