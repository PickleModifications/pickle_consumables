local Throwables = {}
local Drops = {}

-- Throwing

RegisterNetEvent("pickle_consumables:throwing:throwObject", function(data)
    local source = source
    local throwID = nil
    repeat
        throwID = os.time() .. "_" .. math.random(1000, 9999)
    until not Throwables[throwID] 
    Throwables[throwID] = data
    TriggerClientEvent("pickle_consumables:throwing:setObjectData", -1, throwID, data)
    SetTimeout(1000 * Config.Options.throwing.despawnTime, function()
        DeleteEntity(NetworkGetEntityFromNetworkId(Throwables[throwID].net_id))
        Throwables[throwID] = nil
        TriggerClientEvent("pickle_consumables:throwing:setObjectData", -1, throwID, nil)
    end)
end)

-- Drops

function CreateDrop(coords, data)
    local dropID = nil
    repeat
        dropID = os.time() .. "_" .. math.random(1000, 9999)
    until not Drops[dropID] 
    Drops[dropID] = data
    Drops[dropID].coords = coords
    Drops[dropID].heading = 0.0
    Drops[dropID].model = Config.Items[data.itemKey].prop.model
    TriggerClientEvent("pickle_consumables:drop:addDrop", -1, dropID, data)
    if Config.Options.drop.despawnTime and Config.Options.drop.despawnTime > 0 then
        SetTimeout(1000 * Config.Options.drop.despawnTime, function()
            RemoveDrop(dropID)
        end)
    end
end

function RemoveDrop(dropID)
    Drops[dropID] = nil
    TriggerClientEvent("pickle_consumables:drop:removeDrop", -1, dropID)
end

RegisterNetEvent("pickle_consumables:drop:collectDrop", function(dropID)
    local source = source
    local drop = Drops[dropID]
    if not drop then return end
    RemoveDrop(dropID)
    EquipItem(source, drop, true)
end)

RegisterNetEvent("pickle_consumables:drop:createDrop", function(coords)
    local source = source
    local item = Players[source]
    if not item then return end
    if #(GetEntityCoords(GetPlayerPed(source)) - coords) > 100.0 then return end
    Players[source] = nil
    TriggerClientEvent("pickle_consumables:removeItem", source)
    CreateDrop(coords, item)
end)

-- Giving

RegisterNetEvent("pickle_consumables:giveItem", function(target, amount)
    local source = source
    local item = Players[source]
    if not item or target < 1 then return end
    local amount = amount
    local uses = item.uses
    if amount >= uses then
        amount = uses
        Players[source] = nil
        TriggerClientEvent("pickle_consumables:removeItem", source)
    else
        Players[source].uses = Players[source].uses - amount
        TriggerClientEvent("pickle_consumables:updateUses", source, Players[source].uses)
    end
    local targetItem = Players[target]
    if targetItem and targetItem.itemKey == item.itemKey then
        Players[target].uses = Players[target].uses + amount
        TriggerClientEvent("pickle_consumables:updateUses", target, Players[target].uses)
    else
        EquipItem(target, {itemKey = item.itemKey, uses = amount}, true)
    end
end)