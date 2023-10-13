if GetResourceState('qs-inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

RegisterNetEvent("pickle_consumables:setupInventory", function(data)
    Inventory.Items = data.items
    Inventory.Ready = true
end)

function InitializeInventory()
end