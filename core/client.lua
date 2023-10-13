function CreateBlip(data)
    local x,y,z = table.unpack(data.coords)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, data.id or 1)
    SetBlipDisplay(blip, data.display or 4)
    SetBlipScale(blip, data.scale or 1.0)
    SetBlipColour(blip, data.color or 1)
    if (data.rotation) then 
        SetBlipRotation(blip, math.ceil(data.rotation))
    end
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

function CreateVeh(modelHash, ...)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    local veh = CreateVehicle(modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    if Config.GiveKeys then 
        Config.GiveKeys(veh)
    end
    return veh
end

function CreateNPC(modelHash, ...)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    local ped = CreatePed(26, modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    return ped
end

function CreateProp(modelHash, ...)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    local obj = CreateObject(modelHash, ...)
    SetModelAsNoLongerNeeded(modelHash)
    return obj
end

function PlayAnim(ped, dict, ...)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, ...)
end

function PlayEffect(dict, particleName, entity, off, rot, scale, networked)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
    UseParticleFxAssetNextCall(dict)
    local off = off or vector3(0.0, 0.0, 0.0)
    local rot = rot or vector3(0.0, 0.0, 0.0)
    local handle = StartParticleFxLoopedOnEntity(particleName, entity, off.x, off.y, off.z, rot.x, rot.y, rot.z, scale or 1.0)
    if networked then 
        TriggerServerEvent("pickle_consumables:startEffect", ObjToNet(entity), dict, particleName, off, rot, scale)
    end
    return handle
end

function GetClosestVehicleDoor(vehicle, coords)
    local coords = coords or GetEntityCoords(PlayerPedId())
    local bones = {
        "door_dside_f",
        "door_dside_r",
        "door_pside_f",
        "door_pside_r",
        "bonnet",
        "boot"
    }
    local doors = {
        0,
        2,
        1,
        3,
        4,
        5
    }
    local closest
    for i=1, #bones do 
        local boneID = GetEntityBoneIndexByName(vehicle, bones[i])
        if boneID ~= -1 then
            local vcoords = GetWorldPositionOfEntityBone(vehicle, boneID)
            local dist = #(coords - vcoords) 
            if (not closest or closest.dist > dist) and dist < 3.0 then
                closest = {door = doors[i], coords = vcoords, dist = dist}
            end
        end
    end
    if closest then 
        return closest.door, closest.dist
    end
end

function GetNearestEntity(pool, coords, radius, model) 
    local coords = coords or GetEntityCoords(PlayerPedId())
    local radius = radius or 3.0
    local pool = GetGamePool(pool)
    local closest
    for i=1, #pool do 
        local vcoords = GetEntityCoords(pool[i]) 
        local dist = #(coords - vcoords) 
        if (not closest or closest.dist > dist) and (not model or GetEntityModel(pool[i]) == model) then
            closest = {entity = pool[i], dist = dist}
        end
    end
    if closest then 
        return closest.entity, closest.dist
    end
end

function GetNearestVehicle(coords, radius) 
    return GetNearestEntity('CVehicle', coords, radius)
end

function GetNearestEntityModel(model, coords, radius) 
    local entity = GetNearestEntity('CVehicle', coords, radius, model)
    if entity then return entity end
    local entity = GetNearestEntity('CPed', coords, radius, model)
    if entity then return entity end
    local entity = GetNearestEntity('CObject', coords, radius, model)
    if entity then return entity end
end

function GetClosestPlayer(coords, radius)
    local coords = coords or GetEntityCoords(PlayerPedId())
    local radius = radius or 3.0
    local players = GetPlayersInArea(coords, radius)
    local closest
    for i=1, #players do 
        local pcoords = GetEntityCoords(GetPlayerPed(players[i])) 
        local dist = #(coords - pcoords) 
        if not closest or closest.dist > dist then 
            closest = {id = GetPlayerServerId(players[i]), dist = dist}
        end
    end
    if closest then 
        return closest.id, closest.dist
    end
end

local interactTick = 0
local interactCheck = false
local interactText = nil

function ShowInteractText(text)
    local timer = GetGameTimer()
    interactTick = timer
    if interactText == nil or interactText ~= text then 
        interactText = text
        lib.showTextUI(text)
    end
    if interactCheck then return end
    interactCheck = true
    CreateThread(function()
        Wait(150)
        local timer = GetGameTimer()
        interactCheck = false
        if timer ~= interactTick then 
            lib.hideTextUI()
            interactText = nil
            interactTick = 0
        end
    end)
end

local Interactions = {}
EnableInteraction = true

function FormatOptions(index, data)
    local options = data.options
    local list = {}
    if not options or #options < 2 then
        list[1] = ((options and options[1]) and options[1] or { label = data.label })
        list[1].name = GetCurrentResourceName() .. "_option_" .. math.random(1,999999999)
        list[1].onSelect = function(data)
            SelectInteraction(index, 1, data)
        end
        return list
    end
    for i=1, #options do
        list[i] = options[i] 
        list[i].name = GetCurrentResourceName() .. "_option_" .. math.random(1,999999999)
        list[i].onSelect = function(data)
            SelectInteraction(index, i, data)
        end
    end
    return list
end

function EnsureInteractionModel(index)
    local data = Interactions[index] 
    if not data or data.entity then return end
    local entity
    if not data.model and not data.hiddenKeypress and Config.UseTarget and Config.NoModelTargeting then 
        entity = CreateProp(`ng_proc_brick_01a`, data.coords.x, data.coords.y, data.coords.z, false, true, false)
        SetEntityAlpha(entity, 0, false)
    elseif data.model and (not data.model.modelType or data.model.modelType == "ped") then
        local offset = data.model.offset or vector3(0.0, 0.0, 0.0)
        entity = CreateNPC(data.model.hash, data.coords.x + offset.x, data.coords.y + offset.y, (data.coords.z - 1.0) + offset.z, data.heading, false, true)
        SetEntityInvincible(entity, true)
        SetBlockingOfNonTemporaryEvents(entity, true)
    elseif data.model and data.model.modelType == "prop" then
        local offset = data.model.offset or vector3(0.0, 0.0, 0.0)
        entity = CreateProp(data.model.hash, data.coords.x + offset.x, data.coords.y + offset.y, (data.coords.z - 1.0) + offset.z, false, true, false)
    else
        return
    end
    FreezeEntityPosition(entity, true)
    SetEntityHeading(entity, data.heading)
    Interactions[index].entity = entity
    return entity
end

function DeleteInteractionEntity(index)
    local data = Interactions[index] 
    if not data or not data.entity then return end
    DeleteEntity(data.entity)
    Interactions[index].entity = nil
end

function SelectInteraction(index, selection, targetData)
    if not EnableInteraction then return end
    local pcoords = GetEntityCoords(PlayerPedId())
    local data = Interactions[index]
    if not data.target and #(data.coords - pcoords) > Config.InteractDistance then 
        return ShowNotification(_L("interact_far"))
    end
    Interactions[index].selected(selection, targetData)
end

function CreateInteraction(data, selected)
    local index
    repeat
        index = math.random(1, 999999999)
    until not Interactions[index]
    local options = FormatOptions(index, data)
    Interactions[index] = {
        selected = selected,
        options = options,
        label = data.label,
        model = data.model,
        coords = data.coords,
        target = data.target,
        offset = data.offset,
        radius = data.radius or 1.0,
        heading = data.heading,
        hiddenKeypress = data.hiddenKeypress
    }
    if Config.UseTarget then
        if data.target then
            AddTargetModel(data.target, Interactions[index].radius, Interactions[index].options)
        else
            Interactions[index].zone = AddTargetZone(Interactions[index].coords, Interactions[index].radius, Interactions[index].options)
        end
    end
    return index
end

function UpdateInteraction(index, data, selected)
    if not Interactions[index] then return end 
    Interactions[index].selected = selected
    for k,v in pairs(data) do 
        Interactions[index][k] = v
    end
    if data.options then 
        Interactions[index].options = FormatOptions(index, data)
    end
    if Config.UseTarget then
        if Interactions[index].target then 
            RemoveTargetZone(Interactions[index].zone)
            Interactions[index].zone = AddTargetZone(Interactions[index].coords, Interactions[index].radius, Interactions[index].options)
        else
            RemoveTargetModel(Interactions[index].target, Interactions[index].options)
            AddTargetModel(Interactions[index].target, Interactions[index].radius, Interactions[index].options)
        end
    end
end

function DeleteInteraction(index)
    local data = Interactions[index] 
    if not data then return end
    if (data.entity) then 
        DeleteInteractionEntity(index)
    end
    if Config.UseTarget then
        if data.target then 
            RemoveTargetModel(data.target, data.options)
        else
            RemoveTargetZone(data.zone)
        end
    end
    Interactions[index] = nil
end

Citizen.CreateThread(function()
    while true do 
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local wait = 1500
        for k,v in pairs(Interactions) do 
            local coords = v.coords
            if coords then
                local dist = #(pcoords-coords)
                if (dist < Config.RenderDistance) then 
                    EnsureInteractionModel(k)
                    if not Config.UseTarget or v.hiddenKeypress then
                        if not Config.UseTarget and not v.hiddenKeypress and not v.model and Config.Marker and Config.Marker.enabled then
                            wait = 0
                            DrawMarker(Config.Marker.id, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                            Config.Marker.scale, Config.Marker.scale, Config.Marker.scale, Config.Marker.color[1], 
                            Config.Marker.color[2], Config.Marker.color[3], Config.Marker.color[4], false, true)
                        end
                        if dist < Config.InteractDistance then
                            wait = 0 
                            if not ShowInteractText("[E] - " .. v.label) and IsControlJustPressed(1, 51) then
                                if not v.options or #v.options < 2 then 
                                    SelectInteraction(k, 1)
                                else 
                                    lib.registerContext({
                                        id = 'lottery_'..k,
                                        title = v.title or "Options",
                                        options = v.options
                                    })
                                    lib.showContext('lottery_'..k)
                                end
                            end
                        end
                    end
                elseif v.entity then
                    DeleteInteractionEntity(k)
                end
            elseif not Config.UseTarget and v.target then
                local entity = GetNearestEntityModel(v.target)
                if entity then
                    local offset = v.offset or vector3(0.0, 0.0, 0.0)
                    local coords = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
                    local dist = #(pcoords-coords)
                    if dist < v.radius then
                        wait = 0 
                        if not ShowInteractText("[E] - " .. v.label) and IsControlJustPressed(1, 51) then
                            if not v.options or #v.options < 2 then 
                                SelectInteraction(k, 1, {entity = entity, coords = coords, dist = dist})
                            else 
                                lib.registerContext({
                                    id = 'lottery_'..k,
                                    title = v.title or "Options",
                                    options = v.options
                                })
                                lib.showContext('lottery_'..k)
                            end
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for k,v in pairs(Interactions) do 
        DeleteInteraction(k)
    end
end)