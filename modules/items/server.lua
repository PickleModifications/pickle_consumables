Players = {}

function EquipItem(source, item, refund)
    if Players[source] then 
        if refund then
            Inventory.AddItem(source, item.itemKey, 1, {itemKey = item.itemKey, uses = item.uses}, item.slot)
        end
        return
    end
    Players[source] = item
    TriggerClientEvent("pickle_consumables:equipItem", source, item.itemKey, item)
end

function GiveRewards(source, rewards)
    for i=1, #rewards do 
        local reward = rewards[i]
        local amount = (type(reward.amount) == "table" and math.random(reward.amount[1], reward.amount[2]) or reward.amount)
        if not reward.type or reward.type == "item" then
            Inventory.AddItem(source, reward.name, amount)
        elseif reward.type == "money" then
            AddMoney(source, amount)
        end
    end
end

CreateThread(function()
    Wait(1000)
    for k,v in pairs(Config.Items) do 
        RegisterUsableItem(k, function(source, metadata, slot)
            if Players[source] then return end
            local metadata = metadata or {}
            if not metadata.itemKey then
                metadata.itemKey = k 
                metadata.uses = v.uses
                metadata.slot = slot
            end
            Inventory.RemoveItem(source, metadata.itemKey, 1, slot)
            EquipItem(source, metadata, false)
        end)
    end
end)

lib.callback.register("pickle_consumables:useItem", function(source)
    if not Players[source] then return end
    local metadata = Players[source]
    local cfg = Config.Items[metadata.itemKey]
    if metadata.uses < 1 then 
        ShowNotification(source, _L("no_uses_left"))
        return false, metadata.uses
    end
    metadata.uses = metadata.uses - 1
    if metadata.uses < 1 then 
        Players[source] = nil
    end
    if cfg then
        if cfg.rewards then
            GiveRewards(source, cfg.rewards)
        end
        if cfg.status then
            ExecuteStatus(source, cfg.status)
        end
    end
    return true, metadata.uses
end)

RegisterNetEvent("pickle_consumables:returnItem", function(destroy)
    local source = source
    if not Players[source] then return end
    local item = Players[source]
    if not destroy then
        Inventory.AddItem(source, item.itemKey, 1, {itemKey = item.itemKey, uses = item.uses}, item.slot)
    end
    Players[source] = nil
end)

-- CLIENT
-- lib.callback("pickle_consumables:canUseItem", "", function(game_id, games)
-- end)

-- lib.callback("pickle_consumables:useItem", "", function(game_id, games)
-- end)