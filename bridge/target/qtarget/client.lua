if GetResourceState('ox_target') == 'started' or GetResourceState('qtarget') ~= 'started' or not Config.UseTarget then return end

local Zones = {}

function AddTargetModel(models, radius, options)
    local optionsNames = {}
    for i=1, #options do 
        optionsNames[i] = options[i].name
    end
    RemoveTargetModel(models, optionsNames)
    exports['qtarget']:AddTargetModel(models, {options = options, distance = 2.5})
end

function RemoveTargetModel(models, optionsNames)
    exports['qtarget']:RemoveTargetModel(models, optionsNames)
end

function AddTargetZone(coords, radius, options)
    local index
    repeat
        index = "lottery_coord_" .. math.random(1, 999999999)
    until not Zones[index]
    exports['qtarget']:AddBoxZone(index, coords, radius, radius, {
        name = index,
        heading = 0.0,
        minZ = coords.z,
        maxZ = coords.z + radius,
    }, {
        options = options,
    })
    return index
end

function RemoveTargetZone(index)
    Zones[index] = nil
    exports['qtarget']:RemoveZone(index)
end