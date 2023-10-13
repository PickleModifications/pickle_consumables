if GetResourceState('qs-inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.CanCarryItem = function(source, name, count)
    return exports['qs-inventory']:CanCarryItem(source, name, count)
end

Inventory.GetInventory = function(source)
    local items = {}
    local data = exports['qs-inventory']:GetInventory(source)
    for slot, item in pairs(data) do 
        items[#items + 1] = {
            name = item.name,
            label = item.label,
            count = item.amount,
            weight = item.weight,
            slot = item.slot,
            metadata = item.info
        }
    end
    return items
end

Inventory.AddItem = function(source, name, count, metadata, slot) -- Metadata is not required.
    exports['qs-inventory']:AddItem(source, name, count, slot, metadata)
end

Inventory.RemoveItem = function(source, name, count, slot)
    exports['qs-inventory']:RemoveItem(source, name, count, slot)
end

Inventory.SetMetadata = function(source, slot, metadata)
    exports['qs-inventory']:SetItemMetadata(source, slot, metadata)
end

Inventory.GetItemCount = function(source, name)
    return exports['qs-inventory']:GetItemTotalAmount(source, name) or 0
end

function InitializeInventory()
    lib.callback.register("pickle_consumables:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)
    
    for item, data in pairs(exports['qs-inventory']:GetItemList()) do
        Inventory.Items[item] = {label = data.label}
    end
    
    Inventory.Ready = true
end

if Framework == "ESX" then
    function UsableItem(name, cb)
        ESX.RegisterUsableItem(name, function(source, item, data) 
            cb(source, data.metadata, data.slot)
        end)
    end
elseif Framework == "QB" or Framework == "QBOX" then
    function UsableItem(name, cb)
        QBCore.Functions.CreateUseableItem(name, function(source, data)
            local item = data
            if item.info then
                item.metadata = data.info
                item.info = nil
            end
            cb(source, item.metadata, item.slot)
        end)
    end
end