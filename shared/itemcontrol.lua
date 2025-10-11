--[[
    Usable Items & Inventory Utilities Module
    -------------------------------------------
    This module provides functions for:
      • Registering items as usable across different inventory systems (ESX, QBcore, QBX).
      • Retrieving an item's image as a NUI link.
      • Adding and removing items from a player's inventory.
      • Toggling items in inventory (with server event for exploit protection).
      • Checking for item duplication exploits.
      • Handling tool durability mechanics.
      • Checking item availability and retrieving inventory.
      • Granting random rewards from a reward pool.
      • Checking if a player can carry specific items based on weight.
]]
validTokens = {}

-- Function Compatability Table
local InvFunc = {
    {   invName = OXInv,
        removeItem =
            function(src, item, remamount)
                exports[OXInv]:RemoveItem(src, item, remamount, nil)
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                exports[OXInv]:AddItem(src, item, amountToAdd, info, slot)
            end,
        setItemMetadata =
            function(data, src)
                exports[OXInv]:SetMetadata(src, data.slot, data.metadata)
            end,
        hasItem =
            function(item, amount, src)
                if src then
                    local serverItemCheck = exports[OXInv]:GetItem(src, item, nil, true) or 0
                    return serverItemCheck >= amount, serverItemCheck
                else
                    local localItemCheck = exports[OXInv]:GetItemCount(item) or 0
                    return localItemCheck >= amount, localItemCheck
                end
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                for k, v in pairs(itemTable) do
                    resultTable[k] = exports[OXInv]:CanCarryItem(src, k, v)
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                return exports[OXInv]:GetPlayerMaxWeight()
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += v.weight
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = exports[OXInv]:GetInventoryItems(src)
                else
                    grabInv = exports[OXInv]:GetPlayerItems()
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..OXInv.."/web/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                exports[OXInv]:openInventory('shop', { type = name })
            end,
        serverOpenShop = function(shopName)
            --
        end,
        registerShop =
            function(name, label, items, society)
                exports[OXInv]:RegisterShop(name, {
                    name = label,
                    inventory = items,
                    society = society,
                })
            end,
        openStash =
            function(data)
                exports[OXInv]:openInventory('stash', data.stash)
            end,
        clearStash =
            function(stashId)
                exports[OXInv]:ClearInventory(stashId)
            end,
        getStash =
            function(stashName)
                local stash = exports[OXInv]:Inventory(stashName)
                -- Add fallback if ox can't find the stash and returns a boolean
                return type(stash) == "table" and stash.items or {}
            end,
        stashAddItem =
            function(stashItems, stashName, items)

            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                for k, v in pairs(items) do
                    for _, name in pairs(stashName) do
                        local success = exports[OXInv]:RemoveItem(name, k, v)
                        if success then
                            debugPrint("^6Bridge^7: ^2Removing ^3"..OXInv.." ^2Stash item^7:", k, v)
                            break
                        end
                    end
                end
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                exports[OXInv]:RegisterStash(name, label, slots or 50, weight or 4000000, owner or nil)
            end,
    },

    {   invName = CoreInv,
        removeItem =
            function(src, item, remamount)
                exports[CoreInv]:removeItem(src, item, remamount)
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                exports[CoreInv]:addItem(src, item, amountToAdd, info)
            end,
        setItemMetadata =
            function(data, src)
                exports[CoreInv]:setMetadata(src, data.slot, data.metadata)
            end,
        hasItem =
            function(item, amount, src)
                if src then
                    local serverItemCheck = exports[CoreInv]:getItemCount(src, item) or 0
                    return serverItemCheck >= amount, serverItemCheck
                else
                    local localItemCheck = exports[CoreInv]:getItemCount(item) or 0
                    return localItemCheck >= amount, localItemCheck
                end
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                for k, v in pairs(itemTable) do
                    resultTable[k] = exports[CoreInv]:canCarry(src, k, v)
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                return InventoryWeight
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = exports[CoreInv]:getInventory(src)
                else
                    grabInv = exports[CoreInv]:getInventory()
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..CoreInv.."/html/img/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                --
            end,
        serverOpenShop =
            function(shopName)
                --
            end,
        registerShop =
            function(name, label, items, society)
                --
            end,
        openStash =
            function(data)
                TriggerServerEvent('core_inventory:server:openInventory', data.stash, 'stash')
            end,
        clearStash =
            function(stashId)
                exports[CoreInv]:clearInventory("stash-"..stashId)
            end,
        getStash =
            function(stashName)
                return exports[CoreInv]:getInventory(stashName)
            end,
        stashAddItem =
            function(stashItems, stashName, items)
                --
            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                for k, v in pairs(items) do
                    exports[CoreInv]:removeItemExact(stashName[1], k, v)
                    debugPrint("^6Bridge^7: ^2Removing ^3"..CoreInv.." ^2Stash item^7:", k, v)
                end
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                --
            end,
    },

    {   invName = OrigenInv,
        removeItem =
            function(src, item, remamount)
                exports[OrigenInv]:removeItem(src, item, remamount)
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                exports[OrigenInv]:addItem(src, item, amountToAdd, info, slot)
            end,
        setItemMetadata =
            function(data, src)
                exports[OrigenInv]:setMetadata(src, data.slot, data.metadata)
            end,
        hasItem =
            function(item, amount, src)
                if src then
                    local serverItemCheck = exports[OrigenInv]:getItemCount(src, item, false, false) or 0
                    return serverItemCheck >= amount, serverItemCheck
                else
                    local localItemCheck = exports[OrigenInv]:Search('count', item) or 0
                    return localItemCheck >= amount, localItemCheck
                end
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                for k, v in pairs(itemTable) do
                    resultTable[k] = exports[OrigenInv]:canCarryItem(src, k, v)
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                return InventoryWeight
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = exports[OrigenInv]:GetInventoryItems(src)
                else
                    grabInv = exports[OrigenInv]:GetInventory()
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..OrigenInv.."/html/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                --
            end,
        serverOpenShop =
            function(shopName)
                --
            end,
        registerShop =
            function(name, label, items, society)
                --
            end,
        openStash =
            function(data)
                exports[OrigenInv]:openInventory('stash', data.stash, { label = data.label })
            end,
        clearStash =
            function(stashId)
                exports[OrigenInv]:ClearInventory(stashId)
            end,
        getStash =
            function(stashName)
                return exports[OrigenInv]:getInventory(stashName)
            end,
        stashAddItem =
            function(stashItems, stashName, items)
                --
            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                for k, v in pairs(items) do
                    exports[OrigenInv]:RemoveFromStash(stashName[1], k, v)
                    debugPrint("^6Bridge^7: ^2Removing ^3"..OrigenInv.." ^2Stash item^7:", k, v)
                end
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                exports[OrigenInv]:registerStash(name, label, slots or 50, weight or 4000000)
            end,
    },

    {   invName = CodeMInv,
        removeItem =
            function(src, item, remamount)
                exports[CodeMInv]:RemoveItem(src, item, remamount)
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                exports[CodeMInv]:AddItem(src, item, amountToAdd, slot, info)
            end,
        setItemMetadata =
            function(data, src)
                exports[CodeMInv]:SetItemMetadata(src, data.slot, data.metadata)
            end,
        hasItem =
            function(item, amount, src, invCache)
                local count = 0
                for _, itemData in pairs(invCache) do
                    if itemData and itemData.name == item then
                        count += (itemData.amount or 0)
                    end
                end
                return count >= amount, count
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                local items = getPlayerInv(src)
                local totalWeight = 0
                if not items then return false end
                for _, item in pairs(items) do
                    totalWeight += (item.weight * item.amount)
                end
                for k, v in pairs(itemTable) do
                    local itemInfo = Items[k]
                    if not itemInfo then
                        resultTable[k] = true
                    else
                        resultTable[k] = (totalWeight + (itemInfo.weight * v)) <= InventoryWeight
                    end
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                return InventoryWeight
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = exports[CodeMInv]:GetInventory(getPlayer(src).citizenId, src)
                else
                    grabInv = exports[CodeMInv]:GetClientPlayerInventory()
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..CodeMInv.."/html/itemimages/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                TriggerEvent("codem-inventory:openshop", name)
            end,
        serverOpenShop =
            function(shopName)
                --
            end,
        registerShop =
            function(name, label, items, society)
                --
            end,
        openStash =
            function(data)
                TriggerServerEvent('codem-inventory:server:openstash', data.stash, data.slots, data.maxWeight, data.label)
            end,
        clearStash =
            function(stashId)
                exports[CodeMInv]:ClearInventory(stashId)
            end,
        getStash =
            function(stashName)
                return exports[CodeMInv]:GetStashItems(stashName)
            end,
        stashAddItem =
            function(stashItems, stashName, items)
                --
            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                for k, v in pairs(items) do
                    for l in pairs(stashItems) do
                        if stashItems[l].name == k then
                            if (stashItems[l].amount - v) <= 0 then
                                stashItems[l] = nil
                            else
                                debugPrint("^6Bridge^7: ^2Removing ^3"..CodeMInv.." ^2Stash item^7:", k, v)
                                stashItems[l].amount -= v
                            end
                        end
                    end
                end
                exports[CodeMInv]:UpdateStash(stashName[1], stashItems)
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                --
            end,
    },

    {   invName = TgiannInv,
        removeItem =
            function(src, item, remamount)
                exports[TgiannInv]:RemoveItem(src, item, remamount)
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                exports[TgiannInv]:AddItem(src, item, amountToAdd, slot, info)
            end,
        setItemMetadata =
            function(data, src)
                exports[TgiannInv]:UpdateItemMetadata(src, data.item, data.slot, data.metadata)
            end,
        hasItem =
            function(item, amount, src)
                if src then
                    local serverItemCheck = exports[TgiannInv]:GetItemCount(src, item, nil, true) or 0
                    return serverItemCheck >= amount, serverItemCheck
                else
                    local localItemCheck = exports[TgiannInv]:GetItemCount(item) or 0
                    return localItemCheck >= amount, localItemCheck
                end
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                for k, v in pairs(itemTable) do
                    resultTable[k] = exports[TgiannInv]:CanCarryItem(src, k, v)
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                return InventoryWeight
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = exports[TgiannInv]:GetPlayerItems(src)
                else
                    grabInv = exports[TgiannInv]:GetPlayerItems()
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://inventory_images/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                TriggerServerEvent(getScript()..':server:openServerShop', name)
            end,
        serverOpenShop =
            function(shopName)
                exports[TgiannInv]:OpenShop(source, shopName)
            end,
        registerShop =
            function(name, label, items, society)
                exports[TgiannInv]:RegisterShop(name, items)
            end,
        openStash =
            function(data)
                TriggerServerEvent(getScript()..':server:openServerStash', {
                    stashName = data.stash,
                    label = data.label,
                    maxweight = data.maxWeight or 600000,
                    slots = data.slots or 40
                })
            end,
        clearStash =
            function(stashId)
                exports[TgiannInv]:DeleteInventory("stash", stashId)
            end,
        getStash =
            function(stashName)
                return exports[TgiannInv]:GetSecondaryInventoryItems("stash", stashName)
            end,
        stashAddItem =
            function(stashItems, stashName, items)
                --
            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                for k, v in pairs(items) do
                    local itemData = exports[TgiannInv]:GetItemByNameFromSecondaryInventory("stash", stashName[1], k)
                    exports[TgiannInv]:RemoveItemFromSecondaryInventory("stash", stashName[1], k, v, itemData.slot, nil)
                    debugPrint("^6Bridge^7: ^2Removing ^3"..TgiannInv.." ^2Stash item^7:", k, v)
                end
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                exports[TgiannInv]:RegisterStash(name, label, slots or 50, weight or 4000000)
            end,
    },

    {   invName = JPRInv,
        removeItem =
            function(src, item, remamount)
                while remamount > 0 do
                    if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, 1, slot) then
                        remamount -= 1
                    else
                        print("^1Error removing "..item.." Amount left: "..remamount)
                        break
                    end
                end
                if Config.Crafting ~= nil and Config.Crafting.showItemBox then
                    TriggerClientEvent("inventory:client:ItemBox", src, Items[item], "remove", amount or 1)
                end
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                if Core.Functions.GetPlayer(src).Functions.AddItem(item, amountToAdd, nil, info) then
                    if Config.Crafting ~= nil and Config.Crafting.showItemBox then
                        TriggerClientEvent("ps-inventory:client:ItemBox", src, Items[item], "add", amountToAdd)
                    end
                end
            end,
        setItemMetadata =
            function(data, src)
                local Player = Core.Functions.GetPlayer(src)
                Player.PlayerData.items[data.slot].info = data.metadata
                if data.metadata.durability then
                    Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
                end
                Player.Functions.SetInventory(Player.PlayerData.items)
            end,
        hasItem =
            function(item, amount, src, invCache)
                local count = 0
                for _, itemData in pairs(invCache) do
                    if itemData and itemData.name == item then
                        count += (itemData.amount or itemData.count or 1)
                    end
                end
                return count >= amount, count
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                local items = getPlayerInv(src)
                local totalWeight = 0
                if not items then return false end
                for _, item in pairs(items) do
                    totalWeight += (item.weight * item.amount)
                end
                for k, v in pairs(itemTable) do
                    local itemInfo = Items[k]
                    if not itemInfo then
                        resultTable[k] = true
                    else
                        resultTable[k] = (totalWeight + (itemInfo.weight * v)) <= InventoryWeight
                    end
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                if checkExportExists(JPRInv, "GetMaxWeight") then
                    return exports[JPRInv]:GetMaxWeight()
                else
                    return InventoryWeight
                end
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = Core.Functions.GetPlayer(src).PlayerData.items
                else
                    grabInv = Core.Functions.GetPlayerData().items
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..JPRInv.."/html/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                TriggerServerEvent(getScript()..':server:openServerShop', name)
                TriggerServerEvent("inventory:server:OpenInventory", "shop", label, items)
            end,
        serverOpenShop =
            function(shopName)
                if checkExportExists(JPRInv, "OpenShop") then
                    exports[JPRInv]:OpenShop(source, shopName)
                end
            end,
        registerShop =
            function(name, label, items, society)
                exports[JPRInv]:CreateShop({
                    name = name,
                    label = label,
                    slots = #items,
                    items = items
                })
            end,
        openStash =
            function(data)
                if QBInvNew then
                    TriggerServerEvent(getScript()..':server:openServerStash', {
                        stashName = data.stash,
                        label = data.label,
                        maxweight = data.maxWeight or 600000,
                        slots = data.slots or 40
                    })
                else
                    TriggerEvent("inventory:client:SetCurrentStash", data.stash)
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, {
                        slots = data.slots or 50,
                        maxWeight = data.maxWeight or 600000
                    })
                end
            end,
        clearStash =
            function(stashId)
                MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                    ['stash'] = stashId,
                    ['items'] = json.encode({})
                })
            end,
        getStash =
            function(stashName)
                if checkExportExists(JPRInv, "GetStashItems") then
                    return exports[JPRInv]:GetStashItems(stashName) or {}
                else
                    local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
                    return result and json.decode(result) or {}
                end
            end,
        stashAddItem =
            function(stashItems, stashName, items)
                --
            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                if not stashItems or not next(stashItems) then
                    stashItems = getStash(stashName[1])
                end
                for k, v in pairs(items) do
                    for l in pairs(stashItems) do
                        if stashItems[l].name == k then
                            if (stashItems[l].amount - v) <= 0 then
                                stashItems[l] = nil
                            else
                                debugPrint("^6Bridge^7: ^2Removing ^3"..JPRInv.." ^2Stash item^7:", k, v)
                                stashItems[l].amount -= v
                            end
                        end
                    end
                end
                debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3JPR^2 stash '^6"..stashName[1].."^7'")
                MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                    ['stash'] = stashName[1],
                    ['items'] = json.encode(stashItems)
                })
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                --
            end,
    },

    {   invName = QBInv,
        removeItem =
            function(src, item, remamount)
                if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, remamount, slot) then
                    TriggerClientEvent((isStarted(QBInv) and QBInvNew and "qb-" or "").."inventory:client:ItemBox", src, Items[item], "remove", amount or 1)
                else
                    print("^1Error removing "..item.." Amount left: "..remamount)
                end
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                if Core.Functions.GetPlayer(src).Functions.AddItem(item, amountToAdd, nil, info) then
                    TriggerClientEvent((isStarted(QBInv) and QBInvNew and "qb-" or "").."inventory:client:ItemBox", src, Items[item], "add", amountToAdd)
                end
            end,
        setItemMetadata =
            function(data, src)
                local Player = Core.Functions.GetPlayer(src)
                Player.PlayerData.items[data.slot].info = data.metadata
                if data.metadata.durability then
                    Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
                end
                Player.Functions.SetInventory(Player.PlayerData.items)
            end,
        hasItem =
            function(item, amount, src, invCache)
                local count = 0
                for _, itemData in pairs(invCache) do
                    if itemData and itemData.name == item then
                        count += (itemData.amount or itemData.count or 1)
                    end
                end
                return count >= amount, count
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                if checkExportExists(QBInv, "CanAddItem") then
                    for k, v in pairs(itemTable) do
                        resultTable[k] = exports[QBInv]:CanAddItem(src, k, v)
                    end
                else
                    local items = getPlayerInv(src)
                    local totalWeight = 0
                    if not items then return false end
                    for _, item in pairs(items) do
                        totalWeight += (item.weight * item.amount)
                    end
                    for k, v in pairs(itemTable) do
                        local itemInfo = Items[k]
                        if not itemInfo then
                            resultTable[k] = true
                        else
                            resultTable[k] = (totalWeight + (itemInfo.weight * v)) <= InventoryWeight
                        end
                    end
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                if checkExportExists(QBInv, "GetMaxWeight") then
                    return exports[QBInv]:GetMaxWeight()
                else
                    return InventoryWeight
                end
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = Core.Functions.GetPlayer(src).PlayerData.items
                else
                    grabInv = Core.Functions.GetPlayerData().items
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..QBInv.."/html/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                TriggerServerEvent(getScript()..':server:openServerShop', name)
                TriggerServerEvent("inventory:server:OpenInventory", "shop", label, items)
            end,
        serverOpenShop =
            function(shopName)
                if checkExportExists(QBInv, "OpenShop") then
                    exports[QBInv]:OpenShop(source, shopName)
                end
            end,
        registerShop =
            function(name, label, items, society)
                if checkExportExists(QBInv, "CreateShop") then
                    exports[QBInv]:CreateShop({
                        name = name,
                        label = label,
                        slots = #items,
                        items = items,
                        society = society,
                    })
                end
            end,
        openStash =
            function(data)
                if QBInvNew then
                    TriggerServerEvent(getScript()..':server:openServerStash', {
                        stashName = data.stash,
                        label = data.label,
                        maxweight = data.maxWeight or 600000,
                        slots = data.slots or 40
                    })
                else
                    TriggerEvent("inventory:client:SetCurrentStash", data.stash)
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, {
                        slots = data.slots or 50,
                        maxWeight = data.maxWeight or 600000
                    })
                end
            end,
        clearStash =
            function(stashId)
                if checkExportExists(QBInv, "ClearStash") then
                    exports[QBInv]:ClearStash(stashId)
                else
                    MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                        ['stash'] = stashId,
                        ['items'] = json.encode({})
                    })
                end
            end,
        getStash =
            function(stashName)
                if QBInvNew then
                    local result = exports[QBInv]:GetInventory(stashName) or {}
                    return result.items or {}
                else
                    local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
                    if result then
                        return json.decode(result)
                    else
                        return {}
                    end
                end
            end,
        stashAddItem =
            function(stashItems, stashName, items)
                --
            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                if checkExportExists(QBInv, "RemoveItem") then
                    for k, v in pairs(items) do
                        exports[QBInv]:RemoveItem(stashName[1], k, v, false, 'crafting')
                        debugPrint("^6Bridge^7: ^2Removing ^3"..QBInv.." ^2Stash item^7:", k, v)
                    end
                else
                    if not stashItems or not next(stashItems) then
                        stashItems = getStash(stashName[1])
                    end
                    for k, v in pairs(items) do
                        for l in pairs(stashItems) do
                            if stashItems[l].name == k then
                                if (stashItems[l].amount - v) <= 0 then
                                    stashItems[l] = nil
                                else
                                    debugPrint("^6Bridge^7: ^2Removing ^3"..QBInv.." ^2Stash item^7:", k, v)
                                    stashItems[l].amount -= v
                                end
                            end
                        end
                    end
                    debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash '^6"..stashName[1].."^7'")
                    MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                        ['stash'] = stashName[1],
                        ['items'] = json.encode(stashItems)
                    })
                end
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                --
            end,
    },

    {   invName = PSInv,
        removeItem =
            function(src, item, remamount)
                while remamount > 0 do
                    if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, 1, slot) then
                        remamount -= 1
                    else
                        print("^1Error removing "..item.." Amount left: "..remamount)
                        break
                    end
                end
                if Config.Crafting ~= nil and Config.Crafting.showItemBox then
                    TriggerClientEvent("inventory:client:ItemBox", src, Items[item], "remove", amount or 1)
                end
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                if Core.Functions.GetPlayer(src).Functions.AddItem(item, amountToAdd, nil, info) then
                    if Config.Crafting ~= nil and Config.Crafting.showItemBox then
                        TriggerClientEvent("ps-inventory:client:ItemBox", src, Items[item], "add", amountToAdd)
                    end
                end
            end,
        setItemMetadata =
            function(data, src)
                --debugPrint(src, data.item, 1, data.slot)
                local Player = Core.Functions.GetPlayer(src)
                Player.PlayerData.items[data.slot].info = data.metadata
                if data.metadata.durability then
                    Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
                end
                Player.Functions.SetInventory(Player.PlayerData.items)
            end,
        hasItem =
            function(item, amount, src, invCache)
                local count = 0
                for _, itemData in pairs(invCache) do
                    if itemData and itemData.name == item then
                        count += (itemData.amount or itemData.count or 1)
                    end
                end
                return count >= amount, count
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                local items = getPlayerInv(src)
                local totalWeight = 0
                if not items then return false end
                for _, item in pairs(items) do
                    totalWeight += (item.weight * item.amount)
                end
                for k, v in pairs(itemTable) do
                    local itemInfo = Items[k]
                    if not itemInfo then
                        resultTable[k] = true
                    else
                        resultTable[k] = (totalWeight + (itemInfo.weight * v)) <= InventoryWeight
                    end
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                if checkExportExists(PSInv, "GetMaxWeight") then
                    return exports[PSInv]:GetMaxWeight()
                else
                    return InventoryWeight
                end
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = Core.Functions.GetPlayer(src).PlayerData.items
                else
                    grabInv = Core.Functions.GetPlayerData().items
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..PSInv.."/html/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                TriggerServerEvent(getScript()..':server:openServerShop', name)
                TriggerServerEvent("inventory:server:OpenInventory", "shop", label, items)
            end,
        serverOpenShop =
            function(shopName)
                if checkExportExists(PSInv, "OpenShop") then
                    exports[PSInv]:OpenShop(source, shopName)
                end
            end,
        registerShop =
            function(name, label, items, society)
                if checkExportExists(PSInv, "CreateShop") then
                    exports[PSInv]:CreateShop({
                        name = name,
                        label = label,
                        slots = #items,
                        items = items,
                        society = society,
                    })
                end
            end,
        openStash =
            function(data)
                if QBInvNew then
                    TriggerServerEvent(getScript()..':server:openServerStash', {
                        stashName = data.stash,
                        label = data.label,
                        maxweight = data.maxWeight or 600000,
                        slots = data.slots or 40
                    })
                else
                    TriggerEvent("ps-inventory:client:SetCurrentStash", data.stash)
                    TriggerEvent("inventory:client:SetCurrentStash", data.stash)
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, {
                        slots = data.slots or 50,
                        maxWeight = data.maxWeight or 600000
                    })
                end
            end,
        clearStash =
            function(stashId)
                MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                    ['stash'] = stashId,
                    ['items'] = json.encode({})
                })
            end,
        getStash =
            function(stashName)
                local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
                if result then
                    return json.decode(result)
                else
                    return {}
                end
            end,
        stashAddItem =
            function(stashItems, stashName, items)

            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                if not stashItems or not next(stashItems) then
                    stashItems = getStash(stashName[1])
                end
                for k, v in pairs(items) do
                    for l in pairs(stashItems) do
                        if stashItems[l].name == k then
                            if (stashItems[l].amount - v) <= 0 then
                                stashItems[l] = nil
                            else
                                debugPrint("^6Bridge^7: ^2Removing ^3"..PSInv.." ^2Stash item^7:", k, v)
                                stashItems[l].amount -= v
                            end
                        end
                    end
                end
                debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3PS^2 stash ^7'^6"..stashName[1].."^7'")
                MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                    ['stash'] = stashName[1],
                    ['items'] = json.encode(stashItems)
                })
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                --
            end,
    },

    {   invName = RSGInv,
        removeItem =
            function(src, item, remamount)
                while remamount > 0 do
                    if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, 1, slot) then
                        remamount -= 1
                    else
                        print("^1Error removing "..item.." Amount left: "..remamount)
                        break
                    end
                end
                if Config.Crafting ~= nil and Config.Crafting.showItemBox then
                    TriggerClientEvent("rsg-inventory:client:ItemBox", src, Items[item], "remove", amount or 1)
                end
            end,
        addItem =
            function(src, item, amountToAdd, info, slot)
                if Core.Functions.GetPlayer(src).Functions.AddItem(item, amountToAdd, nil, info) then
                    TriggerClientEvent("rsg-inventory:client:ItemBox", src, Items[item], "add", amountToAdd)
                end
            end,
        setItemMetadata =
            function(data, src)
                local Player = Core.Functions.GetPlayer(src)
                Player.PlayerData.items[data.slot].info = data.metadata
                if data.metadata.durability then
                    Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
                end
                Player.Functions.SetInventory(Player.PlayerData.items)
            end,
        hasItem =
            function(item, amount, src, invCache)
                local count = 0
                for _, itemData in pairs(invCache) do
                    if itemData and itemData.name == item then
                        count += (itemData.amount or itemData.count or 1)
                    end
                end
                return count >= amount, count
            end,
        canCarry =
            function(itemTable, src)
                local resultTable = {}
                for k, v in pairs(itemTable) do
                    resultTable[k] = exports[RSGInv]:CanCarryItem(src, k, v)
                end
                return resultTable
            end,
        getMaxInvWeight =
            function()
                if checkExportExists(RSGInv, "GetMaxWeight") then
                    return exports[RSGInv]:GetMaxWeight()
                else
                    return InventoryWeight
                end
            end,
        getCurrentInvWeight =
            function(src)
                local weight = 0
                local itemcheck = getPlayerInv(src)
                for _, v in pairs(itemcheck) do
                    weight += ((v.weight * v.amount) or 0)
                end
                return weight
            end,
        getPlayerInv =
            function(src)
                local grabInv = nil
                if src then
                    grabInv = Core.Functions.GetPlayer(src).PlayerData.items
                else
                    grabInv = Core.Functions.GetPlayerData().items
                end
                return grabInv
            end,
        invImg =
            function(item)
                return "nui://"..RSGInv.."/html/images/"..(Items[item].image or "")
            end,
        openShop =
            function(name, label, items)
                TriggerServerEvent(getScript()..':server:openServerShop', name)
            end,
        serverOpenShop =
            function(shopName)
                exports[RSGInv]:OpenShop(source, shopName)
            end,
        registerShop =
            function(name, label, items, society)
                exports[RSGInv]:CreateShop({
                    name = name,
                    label = label,
                    slots = #items,
                    items = items,
                    society = society,
                })
            end,
        openStash =
            function(data)
                TriggerServerEvent(getScript()..':server:openServerStash', {
                    stashName = data.stash,
                    label = data.label,
                    maxweight = data.maxWeight or 600000,
                    slots = data.slots or 40
                })
            end,
        clearStash =
            function(stashId)
                exports[RSGInv]:ClearStash(stashId)
            end,
        getStash =
            function(stashName)
                return exports[RSGInv]:GetInventory(stashName)
            end,
        stashAddItem =
            function(stashItems, stashName, items)

            end,
        stashRemoveItem =
            function(stashItems, stashName, items)
                for k, v in pairs(items) do
                    exports[RSGInv]:RemoveItem(stashName[1], k, v, false, 'crafting')
                    debugPrint("^6Bridge^7: ^2Removing ^3"..RSGInv.." ^2Stash item^7:", k, v)
                end
            end,
        registerStash =
            function(name, label, slots, weight, owner, coords)
                --
            end,
    },
}

-------------------------------------------------------------
-- Item Availability & Inventory Retrieval
-------------------------------------------------------------
---
--- Locks or unlocks the player's inventory.
--- Freezes/unfreezes the player's position, sets inventory busy state, and toggles hotbar usage.
---
--- @param toggle boolean True to lock inventory; false to unlock.
---
--- @usage
--- ```lua
--- lockInv(true)  -- Lock inventory.
--- lockInv(false) -- Unlock inventory.
--- ```
function lockInv(toggle)
    FreezeEntityPosition(PlayerPedId(), toggle)
    LocalPlayer.state:set("inv_busy", toggle, true)
    LocalPlayer.state:set("invBusy", toggle, true)
    TriggerEvent('inventory:client:busy:status', toggle)
    TriggerEvent('canUseInventoryAndHotbar:toggle', not toggle)
end

--- Checks if a player has the specified items in their inventory.
---
--- Verifies whether the required quantities are present. Returns a boolean and a table of details.
---
--- @param items string|table A single item name or table with required amounts.
--- @param amount number The required quantity (default 1).
--- @param src number|nil Player source ID (defaults to caller).
--- @return boolean boolean True if all items are available; otherwise, false.
--- @return table|nil table Table detailing counts for each item.
---
---@usage
--- ```lua
--- local hasAll, details = hasItem({"health_potion", "mana_potion"}, 2, playerId)
--- if hasAll then
---     -- Proceed with action
--- else
---     -- Inform the player about missing items
--- end
--- ```
function hasItem(items, amount, src)
    local amount = amount and amount or 1
    local grabInv, foundInv = getPlayerInv(src)

    if type(items) ~= "table" then items = { [items] = amount and amount or 1, } end

    local hasTable = {}
    for item, amt in pairs(items) do
        if not doesItemExist(item) then
            print("^4ERROR^7: ^2Script can't find ingredient item in Shared Items - ^1"..item.."^7")
        end
        for i = 1, #InvFunc do
            local inv = InvFunc[i]
            if isStarted(inv.invName) then
                local hasItem, count = inv.hasItem(item, amt, src, grabInv)

                local foundMessage = "^6Bridge^7: ^3hasItem^7[^6"..foundInv.."^7]: "..tostring(item).." ^3"..count.."^7/^3"..amt
                if count >= amt then foundMessage = foundMessage.." ^5FOUND^7" else foundMessage = foundMessage .." ^1NOT FOUND^7" end
                debugPrint(foundMessage)

                hasTable[item] = { hasItem = hasItem, count = count }
                break
            end
        end
    end

    -- Fallback to default hasItem function
    if not hasTable or not next(hasTable) then
        if isStarted(ESXExport) then
            for item, amt in pairs(items) do
                local count = 0
                for itemName, amount in pairs(grabInv) do
                    if itemName and itemName == item then
                        count += (amount or 1)
                    end
                end
                hasTable[item] = { hasItem = count >= amt, count = count }
            end
        else
            for item, amt in pairs(items) do
                local count = 0
                for _, itemData in pairs(grabInv) do
                    if itemData and itemData.name == item then
                        count += (itemData.amount or itemData.count or 1)
                    end
                end
                hasTable[item] = { hasItem = count >= amt, count = count }
            end
        end
    end

    for _, v in pairs(hasTable) do
        if not v.hasItem then
            return false, hasTable
        end
    end
    return true, hasTable
end

--- Retrieves a player's inventory based on the active inventory system.
---
--- @param src number|nil The player source ID (if nil, retrieves current player's inventory).
--- @return table|nil table The inventory items.
--- @return string|nil string The name of the inventory system.
---
---@usage
--- ```lua
--- local inventory, system = getPlayerInv(playerId)
--- if inventory then
---     -- Process inventory
--- end
--- ```
function getPlayerInv(src)
    local grabInv = nil
    local foundInv = ""

    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            foundInv = inv.invName
            grabInv = inv.getPlayerInv(src)
            break
        end
    end

    -- Fallback to framework functions
    if not grabInv then
        if isStarted(QBExport) then
            if src then
                grabInv = Core.Functions.GetPlayer(src).PlayerData.items
            else
                grabInv = Core.Functions.GetPlayerData().items
            end
        elseif isStarted(ESXExport) then
            if src then
                local xPlayer = ESX.GetPlayerFromId(src)
                grabInv = xPlayer and xPlayer.getInventory() or {}
            else
                grabInv = triggerCallback(getScript()..":GetESXInv")
            end
        end
    end

    if grabInv == nil then
        print("^4ERROR^7: ^2No Supported Inventory detected ^7- ^2Check ^3starter^1.^2lua^7")
    end
    return grabInv, foundInv
end

if isServer() then
    createCallback(getScript()..":GetESXInv", function(source)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        local inv = xPlayer.getInventory()
        return xPlayer.getInventory(src)
    end)
end

function isInventoryOpen()

    return IsNuiFocused()

end

-------------------------------------------------------------
-- Item Image Retrieval
-------------------------------------------------------------

--- Retrieves the NUI link for an item's image from the active inventory system.
---
--- @param item string The item name.
--- @return string string A `nui://` link to the item's image, or an empty string if not found.
---
--- @usage
--- ```lua
--- local imageLink = invImg("health_potion")
--- if imageLink ~= "" then print(imageLink) end
--- ```
function invImg(item)
    local imgLink = ""
    if item ~= "" and doesItemExist(item) then
        for i = 1, #InvFunc do
            local inv = InvFunc[i]
            if isStarted(inv.invName) then
                imgLink = inv.invImg(item)
                break
            end
        end
    end
    return imgLink
end

-------------------------------------------------------------
-- Registering Usable Items
-------------------------------------------------------------

--- Registers an item as usable for ESX, QBcore, or QBX.
---
--- @param item string The name of the item.
--- @param funct function The function to execute when the item is used.
---
--- @usage
--- ```lua
--- createUseableItem("health_potion", function(source)
---     -- Code to consume the health potion
--- end)
--- ```
function createUseableItem(item, funct)
    if doesItemExist(item) then
        local useableFunc = {
            {   framework = ESXExport,
                func = function(item, funct)
                    while not ESX do Wait(0) end
                    ESX.RegisterUsableItem(item, funct)
                end,
            },
            {   framework = QBXExport,
                func = function(item, funct)
                    exports[QBXExport]:CreateUseableItem(item, funct)
                end,
            },
            {   framework = QBExport,
                func = function(item, funct)
                    Core.Functions.CreateUseableItem(item, funct)
                end,
            },
            {   framework = RSGExport,
                func = function(item, funct)
                    Core.Functions.CreateUseableItem(item, funct)
                end,
            },
        }

        for i = 1, #useableFunc do
            local framework = useableFunc[i]
            if isStarted(framework.framework) then
                debugPrint("^6Bridge^7: ^2Registering ^3UsableItem^2 with ^4"..framework.framework.."^7:", item)
                framework.func(item, funct)
                return
            end
        end

        -- Fallback to framework functiosn
        if isStarted(QBExport) then
            debugPrint("^6Bridge^7: ^2Registering ^3UsableItem^2 with ^4"..QBExport.."^7:", item)
            Core.Functions.CreateUseableItem(item, funct)
        elseif isStarted(ESXExport) then
            debugPrint("^6Bridge^7: ^2Registering ^3UsableItem^2 with ^4"..ESXExport.."^7:", item)
            while not ESX do Wait(0) end
            ESX.RegisterUsableItem(item, funct)
        end

        debugPrint("^4ERROR^7: No supported framework detected for registering usable item: ^3"..item.."^7")
    else
        print("^1ERROR^7: ^1Tried to make item usable but it didn't exist^7: "..item)
    end
end


-------------------------------------------------------------
-- Adding and Removing Items
-------------------------------------------------------------

--- Adds an item to a player's inventory.
---
--- Triggers a server event (or local event) to add the specified item.
---
--- @param item string The item name.
--- @param amount number The quantity to add.
--- @param info table|nil Additional metadata for the item.
--- @param src number|nil Optional player source; if nil, defaults to the caller.
---
--- @usage
--- ```lua
--- addItem("health_potion", 2, { quality = "high" })
--- ```
function addItem(item, amount, info, src)
    if not doesItemExist(item) then
        print("^6Bridge^7: ^1Error^7 - ^2Tried to give ^7'^3"..item.."^7'^2 but it doesn't exist")
        return
    end

    if src then
        TriggerEvent(getScript()..":server:toggleItem", true, item, amount, src, info)
    else
        local timeout = GetGameTimer() + 5000
        while currentToken == nil and GetGameTimer() < timeout do Wait(100) end
        TriggerServerEvent(getScript()..":server:toggleItem", true, item, amount, nil, info, nil, currentToken)
        currentToken = nil -- clear client cached token
    end
end

--- Removes an item from a player's inventory.
---
--- Triggers a server event (or local event) to remove the specified item.
---
--- @param item string The item name.
--- @param amount number The quantity to remove.
--- @param src number|nil Optional player source.
--- @param slot number|nil Optional inventory slot.
---
--- @usage
--- ```lua
--- removeItem("health_potion", 1)
--- ```
function removeItem(item, amount, src, slot)
    if not doesItemExist(item) then
        print("^6Bridge^7: ^1Error^7 - ^2Tried to remove ^7'^3"..item.."^7'^2 but it doesn't exist")
        return
    end

    if src then
        --debugPrint(src)
        TriggerEvent(getScript()..":server:toggleItem", false, item, amount, src, nil, slot)
    else
        TriggerServerEvent(getScript()..":server:toggleItem", false, item, amount, nil, nil, slot)
    end
end

-------------------------------------------------------------
-- Toggle Items (Server Event)
-------------------------------------------------------------

--- Server event handler to toggle (add or remove) an item from a player's inventory.
---
--- This function validates the item, then calls the appropriate export functions based on the active inventory system.
--- It also includes exploit protection via the dupeWarn function.
---
--- @param give boolean True to add the item, false to remove.
--- @param item string The item name.
--- @param amount number The quantity.
--- @param newsrc number|nil The player source; defaults to event source.
--- @param info table|nil Additional metadata.
--- @param slot number|nil Optional inventory slot.
---
--- @usage
--- ```lua
--- TriggerServerEvent(getScript()..":server:toggleItem", true, "health_potion", 1)
--- ```


RegisterNetEvent(getScript()..":server:toggleItem", function(give, item, amount, newsrc, info, slot, token)
    local excludeRes = {
        [QBExport] = true,
        [ESXExport] = true,
        [VorpExport] = true,
    }
    local invokingRes = GetInvokingResource()

    --debugPrint(GetInvokingResource())
	if invokingRes and invokingRes ~= getScript() and not excludeRes[invokingRes] then
        debugPrint("^1Error^7: ^1Possible exploit^7, ^1vital function was called from an external resource^7")
        return
    end

    if not doesItemExist(item) then
        print("^1Error^7 - ^2Tried to "..(tostring(give) == "true" and "add" or "remove").." '^3"..item.."^7' but it doesn't exist")
        return
    end

    local src = (newsrc and tonumber(newsrc)) or source

    if (give == true or give == 1) then
        if newsrc == nil then -- this must be coming from client this would be blank
            if not checkToken(src, token, "item", item) then
                return
            end
        end
    end

    local action = (tostring(give) == "true" and "addItem" or "removeItem")
    local remamount = amount or 1
    if item == nil then return end

    local invName = ""
    if give == 0 or give == false then
        if not hasItem(item, amount or 1, src) then
            dupeWarn(src, item, amount)

        else
            for i = 1, #InvFunc do
                local inv = InvFunc[i]
                if isStarted(inv.invName) then
                    invName = inv.invName
                    inv.removeItem(src, item, remamount)
                    break
                end
            end

            -----
            -- Fallback for if no inventory found:
            -----
            if invName == "" then
                print("^4ERROR^7: No Supported Inventory detected - ^2Falling back to core functions")
                if isStarted(QBExport) or isStarted(QBXExport) then -- if qbcore or qbxcore, just use core functions
                    invName = isStarted(QBXExport) and QBXExport or isStarted(QBExport) and QBExport
                    Core.Functions.GetPlayer(src).Functions.RemoveItem(item, remamount, slot)

                elseif ESX and isStarted(ESXExport) then  -- if esx then use core functions
                    invName = ESX
                    ESX.GetPlayerFromId(src).removeInventoryItem(item, remamount)

                end
            else
                debugPrint("^6Bridge^7: ^3"..action.."^7[^6"..invName.."^7] Player(^3"..src.."^7) "..getItemLabel(item).."("..item..") x"..(amount or 1))
            end
        end
    else
        local amountToAdd = amount or 1
        for i = 1, #InvFunc do
            local inv = InvFunc[i]
            if isStarted(inv.invName) then
                invName = inv.invName
                inv.addItem(src, item, amountToAdd, info, slot)
                break
            end
        end

        if invName == "" then
            print("^4ERROR^7: No Supported Inventory detected - ^2Falling back to core functions")
            if isStarted(QBExport) or isStarted(QBXExport) then -- if qbcore or qbxcore, just use core functions
                invName = isStarted(QBXExport) and QBXExport or isStarted(QBExport) and QBExport
                Core.Functions.GetPlayer(src).Functions.AddItem(item, amountToAdd, nil, info)

            elseif ESX and isStarted(ESXExport) then  -- if esx then use core functions
                invName = ESX
                ESX.GetPlayerFromId(src).addInventoryItem(item, amountToAdd)
            end
        else
            debugPrint("^6Bridge^7: ^3"..action.."^7[^6"..invName.."^7] Player(^3"..src.."^7) "..getItemLabel(item).."("..item..") x"..(amount or 1))
        end
    end
end)

-------------------------------------------------------------
-- Exploit Protection
-------------------------------------------------------------

--- Warns and kicks a player if they try to remove an item they don't have.
---
--- @param src number The player's source ID.
--- @param item string The item name.
---
--- @usage
--- ```lua
--- dupeWarn(playerId, "health_potion")
--- ```
function dupeWarn(src, item, message)
    local name = getPlayer(src).name
    print(message or "^5DupeWarn^7: "..name.." (^1"..tostring(src).."^7) ^2Tried to remove item '^3"..item.."^7'^2 but it wasn't there^7")
    if not debugMode then
        DropPlayer(src, name.."("..tostring(src)..") kicked by exploit protection")
    end
    print("^5DupeWarn^7: "..name.."(^1"..tostring(src).."^7) ^2Dropped from server - exploit protection^7")
end

-------------------------------------------------------------
-- Tool Durability & Metadata
-------------------------------------------------------------

--- Reduces the durability of a tool by a specified damage amount.
---
--- If durability reaches zero or below, the tool is removed and a break sound is played.
---
--- @param data table Contains:
---   - item (string): The tool's name.
---   - damage (number): The damage % to apply.
---
--- @usage
--- ```lua
--- breakTool({ item = "drill", damage = 10 })
--- ```
function breakTool(data)
    local metadata, slot = getItemMetadata(data.item)
    metadata = metadata or {}
    if not metadata.durability then metadata.durability = 100 end
    metadata.durability -= data.damage
    if metadata.durability <= 0 then
        removeItem(data.item, 1, nil, slot)
        local breakId = GetSoundId()
        PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
    else
        TriggerServerEvent(getScript()..":server:setItemMetaData", { item = data.item, slot = slot, metadata = metadata })
    end
end


--- Reduces the uses of a tool by a specified damage amount.
---
--- If uses reaches zero or below, the tool is removed and a break sound is played.
---
--- @param data table Contains:
---   - item (string): The tool's name.
---   - damage (number): The damage % to apply.
---
--- @usage
--- ```lua
--- useToolDegrade({ item = "drill", maxUse = 10 })
--- ```
function useToolDegrade(data) -- WIP
    local metadata, slot = getItemMetadata(data.item)
    metadata = metadata or {}
    if not metadata["Uses Left"] then metadata["Uses Left"] = data.maxUse end
    metadata["Uses Left"] -= 1
    if metadata["Uses Left"] <= 0 then
        removeItem(data.item, 1, nil, slot)
        local breakId = GetSoundId()
        PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
    else
        TriggerServerEvent(getScript()..":server:setItemMetaData", { item = data.item, slot = slot, metadata = metadata })
    end
end

-- Grab whole inventory and check for metadata
function getItemMetadata(item, slot, src)
    local lowestSlot = 100
    local chosenSlot = slot
    local metadata = {}

    local itemcheck = getPlayerInv(src)

    if chosenSlot then
        for k, v in pairs(itemcheck) do
            if v.name == item and v.slot == chosenSlot then
                lowestSlot = v.slot
                metadata = itemcheck[k].info or itemcheck[k].metadata or {}
                debugPrint("^6Bridge^7: ^2Found metadata for item ^3"..item.." ^2in slot ^3"..lowestSlot.."^7")
            end
        end
    else
        for k, v in pairs(itemcheck) do
            if v.name == item then
                if v.slot <= lowestSlot then
                    lowestSlot = v.slot
                    metadata = itemcheck[k].info or itemcheck[k].metadata or {}
                end
            end
        end
    end
    return metadata, lowestSlot
end

--- Server event handler to set metadata for an item.
---
--- Updates item metadata (e.g. durability) for the player's inventory based on slot.
---
--- @param data table Contains:
---   - item (string): The item name.
---   - slot (number): The inventory slot.
---   - metadata (table): The metadata to set.
---
--- @usage
--- ```lua
--- TriggerServerEvent("script:server:setItemMetaData", { item = "drill", slot = 5, metadata = { durability = 80 } })
--- ```
RegisterNetEvent(getScript()..":server:setItemMetaData", function(data, src)
    local src = src or source
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            inv.setItemMetadata(data, src)
            return
        end
    end

    -- Fallback functions
    if isStarted(QBExport) or isStarted(QBXExport) then -- if qbcore or qbxcore, just use core functions
        local Player = Core.Functions.GetPlayer(src)
        Player.PlayerData.items[data.slot].info = data.metadata
        if data.metadata.durability then
            Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
        end
        Player.Functions.SetInventory(Player.PlayerData.items)

    elseif ESX and isStarted(ESXExport) then  -- if esx then use core functions
        --?
    end
end)

-------------------------------------------------------------
-- Random Reward
-------------------------------------------------------------

--- Grants a random reward from a predefined reward pool if the player is eligible.
---
--- Checks if the item qualifies for a reward, removes the item, then calculates a random reward based on rarity.
---
--- @param itemName string The item name to check.
---
---@usage
--- ```lua
--- getRandomReward("gold_ring")
--- ```
function getRandomReward(itemName, src)
    if Config.Rewards.RewardPool then
        local reward = false
        if type(Config.Rewards.RewardItem) == "string" then
            Config.Rewards.RewardItem = { Config.Rewards.RewardItem }
        end
        for k, v in pairs(Config.Rewards.RewardItem) do
            if v == itemName then
                reward = true
                break
            end
        end
        if reward then
            local totalRarity = 0
            for i = 1, #Config.Rewards.RewardPool do
                totalRarity += Config.Rewards.RewardPool[i].rarity
            end
            debugPrint("^6Bridge^7: ^3getRandomReward^7: Total Rarity '"..totalRarity.."'")
            local randomNum = math.random(1, totalRarity)
            debugPrint("^6Bridge^7: ^3getRandomReward^7: Random Number '"..randomNum.."'")
            local currentRarity = 0
            for i = 1, #Config.Rewards.RewardPool do
                currentRarity += Config.Rewards.RewardPool[i].rarity
                if randomNum <= currentRarity then
                    debugPrint("^6Bridge^7: ^3getRandomReward^7: ^2Selected toy ^7'^6"..Config.Rewards.RewardPool[i].item.."^7'")
                    addItem(Config.Rewards.RewardPool[i].item, 1, nil, src)
                    return
                end
            end
        end
    end
end

-------------------------------------------------------------
-- Carry Capacity Check
-------------------------------------------------------------

--- Checks if a player can carry the specified items based on weight.
---
--- Calculates the current total weight in the player's inventory and determines whether adding the new items would exceed capacity.
---
--- @param itemTable table A table where keys are item names and values are required quantities.
--- @param src number The player's source ID.
--- @return table A table mapping each item to a boolean indicating if it can be carried.
---
--- @usage
--- local carryCheck = canCarry({ ["health_potion"] = 2, ["mana_potion"] = 3 }, playerId)
--- if carryCheck["health_potion"] and carryCheck["mana_potion"] then
---     -- Player can carry items.
--- else
---     -- Notify player.
--- end
function canCarry(itemTable, src)
    local resultTable = {}
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            return inv.canCarry(itemTable, src)
        end
    end

    -- Fallback to default canCarry function
    local items = getPlayerInv(src)
    local totalWeight = 0
    if not items then return false end
    for _, item in pairs(items) do
        totalWeight += (item.weight * item.amount)
    end
    for k, v in pairs(itemTable) do
        local itemInfo = Items[k]
        if not itemInfo then
            resultTable[k] = true
        else
            resultTable[k] = (totalWeight + (itemInfo.weight * v)) <= InventoryWeight
        end
    end
    return resultTable
end

-------------------------------------------------------------
-- Server Callback Registration
-------------------------------------------------------------
if isServer() then
    createCallback(getScript()..":server:canCarry", function(source, itemTable)
        local result = canCarry(itemTable, source)
        return result
    end)

    createCallback(getScript()..":server:getMaxCarryCraft", function(source, data)
        local src = source
        local item = data.item
        local max = data.max or 100

        local maxCanCarry = 0
        for i = 1, max do
            local checkTable = {
                [item] = i
            }
            local result = canCarry(checkTable, src)
            if result[item] == true then
                maxCanCarry = i
            else
                break
            end
        end
        return maxCanCarry
    end)
end

--- Attempts to return the number value of the max inventory weight
---
--- @param src number (optional) can be run in server or client.
---
--- @usage
--- ```lua
--- local maxInvWeight = getMaxInvWeight()
--- print("Max Inventory Weight:", maxInvWeight)
--- ```
function getMaxInvWeight()
    local weight = 0
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            weight = inv.getMaxInvWeight()
            break
        end
    end

    -- Fallback function
    if weight == 0 then
        weight = InventoryWeight
    end
    return weight
end

--- Returns current number value of the players inventory weight
---
--- @param src number (optional) can be run in server or client.
---
--- @usage
--- ```lua
--- local currentInvWeight = getCurrentInvWeight()
--- print("Current Player Inventory Weight:", currentInvWeight)
--- ```
function getCurrentInvWeight(src)
    local weight = 0
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            weight = inv.getCurrentInvWeight(src)
            break
        end
    end

    -- fallback function
    if weight == 0 then
        local itemcheck = getPlayerInv(src)
        if isStarted(ESXExport) then
            for _, amount in pairs(itemcheck) do
                weight += (amount or 0)
            end
        else
            for _, v in pairs(itemcheck) do
                weight += ((v.weight * (v.amount or v.count)) or 0)
            end
        end
    end
    return weight
end

--- Retruns if the player has enough inventory slots free
---
--- @param slots number The number of free slots.
--- @param src number (optional) can be run in server or client.
---
--- @usage
--- ```lua
--- local slots = 5
--- if hasFreeInventorySlots(slots, src) then
---     print("Player has enough slots free!")
--- end
--- ```
function hasFreeInventorySlots(slots, src)
    local inv = getPlayerInv(src)
    if (countTable(inv) + slots) <= InventorySlots then
        return true
    end
    return false
end

-------------------------------------------------------------
-- Check Item Existance - return boolean(true,false)
-------------------------------------------------------------

--- checks whether an item exists in your item database
---
--- @param item string The item name.
---
--- @usage
--- ```lua
--- local item = "apple"
--- if doesItemExist(item) then print("item exists") end
--- ```
function doesItemExist(item)
    local item = type(item) == "string" and item or tostring(item)
    if not item or item == "" then
        return false
    end
    if not Items or not next(Items) then
        return item.." (Missing)"
    end
    if Items[item] ~= nil then
        return Items[item]
    end
    return false
end

--- Attempts to return the item "label"
--- If can't be found returns "item (Missing item error)"
---
--- @param item string The item name.
---
--- @usage
--- ```lua
--- local label = getItemLabel("apple")
--- print("label")
--- ```
function getItemLabel(item)
    local item = type(item) == "string" and item or tostring(item)

    if not item or item == "" then
        return ""
    end
    if not Items or not next(Items) then
        return item.." (Missing item error)"
    end
    if Items[item] ~= nil then
        return Items[item].label
    end
    return item.." (Missing item error)"
end


--[[
    Stash Management Module
    -------------------------
    This module handles stash-related operations including:
      • Retrieving stash items (from server or local cache).
      • Checking for required items in stashes.
      • Opening stashes using different inventory systems.
      • Removing items from stashes.
      • Checking if a stash has specific items.
]]

-- Global variable to hold the current stash (used in callbacks).
local stash

-- If running on the server, create a callback to retrieve stash items.
if isServer() then
    createCallback(getScript()..':server:GetStashItems', function(source, stashName)
        if stashName == nil or stashName == "" then
            return {}
        end
        stash = getStash(stashName)
        return stash
    end)
end

-- Local cache for stashes.
local stashCache = {}

--- Retrieves (or updates) a local stash cache entry with a timeout.
--- When the cache is empty or expired, it triggers a server callback to update the items.
---
--- @param stashName string The name of the stash.
--- @param stop boolean (Optional) If true, clears the entire stash cache.
--- @return boolean True if items exist in cache (and recheck is skipped), false otherwise.
---
--- @usage
--- ```lua
--- local cached = GetStashTimeout("playerStash")
--- ```
function GetStashTimeout(stashName, stop)
    if stop or (stashName == nil or stashName == "") then
        stashCache = {}
        return false
    end

    -- Retrieve cache for this stash, or initialize if not present.
    stash = stashCache[stashName]
    if not stash then
        debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache ^1not ^2found^7, ^2need to grab from server^7")
        stashCache[stashName] = { items = {}, timeout = 0 }
        stash = stashCache[stashName]
    else
        debugPrint("^6Bridge^7: ^2Local Stash for ^7'^3"..stashName.."^7'^2 cache found^7")
    end

    -- If there are already items in cache, skip recheck.
    if countTable(stashCache[stashName].items) > 0 then
        debugPrint("^6Bridge^7: '^3"..stashName.."^7' ^2Items found in local cache, skipping server recheck")
        return true
    end

    -- If timeout has expired, update the stash items from the server.
    if stashCache[stashName].timeout <= 0 then
        stashCache[stashName].items = triggerCallback(getScript()..':server:GetStashItems', stashName)
        stashCache[stashName].timeout = 10000  -- Timeout in milliseconds.
        CreateThread(function()
            while stashCache[stashName] and stashCache[stashName].timeout > 0 do
                stashCache[stashName].timeout -= 1000
                Wait(1000)
            end
            debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache timed out^7, ^3Clearing^7")
            stashCache[stashName] = nil
        end)
    end
    return false
end

--- Checks if the specified stashes have the required items.
---
--- If multiple stashes are provided (as a table), it iterates over each until all required items are found.
---
--- @param stashes string|table Either a single stash name or a table of stash names.
--- @param itemTable table A table where keys are item names and values are the required amounts.
--- @return boolean, string|nil `boolean, string` true and the stash name if found, otherwise false and nil.
---
--- @usage
--- ```lua
--- local found, stashName = checkStashItem({"playerStash", "storageStash"}, { iron = 2, wood = 5 })
--- ```
function checkStashItem(stashes, itemTable)
    if not stashes or stashes == "" then
        return hasItem(itemTable), nil
    end

    if type(stashes) == "table" then
        debugPrint("^6Bridge^7: ^2Checking multiple stashes for ingredients^7")
        -- Iterate over each provided stash name.
        for _, name in pairs(stashes) do
            GetStashTimeout(name)
            if stashhasItem(stashCache[name].items, itemTable, nil) then
                return true, name
            end
        end
    else
        debugPrint("^6Bridge^7: ^2Checking "..(stashes and " '^3"..stashes.."^7'" or "").." ingredients")
        GetStashTimeout(stashes)
        return stashhasItem(stashCache[stashes].items, itemTable), stashes
    end

    return false, nil
end

-------------------------------------------------------------
-- Stash Opening Functions
-------------------------------------------------------------
---
local stashExploitCheck = {}

if isServer() then
    createCallback(getScript()..":getRegisteredStashLocations", function(src, stashName)
        return stashExploitCheck[stashName]
    end)
end

--- Opens a stash using the active inventory system.
---
--- Checks for job or gang restrictions before opening the stash.
---
--- @param data table A table containing stash data:
---        - stash (string): The stash identifier.
---        - label (string): Display label.
---        - maxWeight (number|nil): Maximum weight (default 600000).
---        - slots (number|nil): Number of slots (default 40).
---        - stashOptions (table|nil): Additional options for the stash.
---        - job/gang (string|nil): Restriction for access.
---        - coords (vector3): Coordinates to "look" at.
---
--- @usage
--- ```lua
--- openStash({ stash = "playerStash", label = "Player Stash", coords = vector3(100, 200, 30) })
--- ```
function openStash(data)
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end

    local exploitCheck = triggerCallback(getScript()..":getRegisteredStashLocations", data.stash)

    if not exploitCheck then
        print("^3Warning^7: ^2This isn't a registered stash^1, refusing call^7")
        return
    end
    if not distExploitCheck(exploitCheck) then
        return
    end

    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            inv.openStash(data)
            lookEnt(data.coords)
            return
        end
    end

    --Fallback to these commands
    TriggerEvent("inventory:client:SetCurrentStash", data.stash)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, {
        slots = data.slots or 50,
        maxWeight = data.maxWeight or 600000
    })

    lookEnt(data.coords)
end


-- Wrapper function for opening stash from the server.
-- Messy but not much else I can do about it.
RegisterNetEvent(getScript()..":server:openServerStash", function(data)
    local src = source

    if not stashExploitCheck[data.stashName] then
        print("^3Warning^7: ^1Source^7: ^3"..src.." ^1Tried to open a shop^7: ^2This isn't a registered stash^1, refusing call^7")
        return
    end
    if not distExploitCheck(stashExploitCheck[data.stashName], src) then
        return
    end

    if isStarted(TgiannInv) then
        exports[TgiannInv]:OpenInventory(source, 'stash', data.stashName, data)

    elseif isStarted(JPRInv) then
        exports[JPRInv]:OpenInventory(source, data.stashName, data)

    elseif isStarted(QBInv) then
        exports[QBInv]:OpenInventory(source, data.stashName, data)

    elseif isStarted(PSInv) then
        exports[PSInv]:OpenInventory(source, data.stashName, data)

    elseif isStarted(RSGInv) then
        exports[RSGInv]:OpenInventory(source, data.stashName, data)
    end
end)

function clearStash(stashId)
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            debugPrint("^5Bridge^7: ^2Clearing ^3"..inv.invName.."^2 Stash^7:", stashId)
            inv.clearStash(stashId)
            return
        end
    end
end


-------------------------------------------------------------
-- Stash Retrieval Function
-------------------------------------------------------------

--- Retrieves stash items from the active inventory system.
---
--- This function converts the raw stash items into a standardized table using the global Items lookup.
---
--- @param stashName string The identifier for the stash.
--- @return stashTable table A table of items from the stash.
---
--- @usage
--- ```lua
--- local items = getStash("playerStash")
--- ```
function getStash(stashName)
    if stashName == "" or type(stashName) ~= "string" then
        print("^6Bridge^7: ^2Stash name was not a string ^3"..stashName.."^7(^3"..type(stashName).."^7)")
        return {}
    end

    local stashItems, items = {}, {}
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            debugPrint("^6Bridge^7: ^2Retrieving ^3"..inv.invName.." ^2Stash^7:", stashName)
            stashItems = inv.getStash(stashName)
            goto skip
        end
    end

    -- Fallback to sql checks if no supported inventory found
    if not stashItems or not next(stashItems) then
        if isStarted(QBExport) or isStarted(QBXExport) then
            local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
            if result then
                stashItems = json.decode(result)
            end
        elseif ESX and isStarted(ESXExport) then  -- if esx then use core functions
            --?
        end

    end
    ::skip::
    if stashItems then
        for _, item in pairs(stashItems) do
            local itemInfo = Items[item.name:lower()]
            if itemInfo then
                local indexNum = #items + 1  -- Fallback index if slot is missing.
                items[(item.slot or indexNum)] = {
                    name = itemInfo.name or nil,
                    amount = tonumber(item.amount) or tonumber(item.count),
                    info = item.info or "",
                    label = itemInfo.label or nil,
                    description = itemInfo.description or "",
                    weight = itemInfo.weight or nil,
                    type = itemInfo.type or nil,
                    unique = itemInfo.unique or nil,
                    useable = itemInfo.useable or nil,
                    image = itemInfo.image or nil,
                    slot = (item.slot and item.slot) or indexNum,
                    metadata = (item.metadata and item.metadata) or nil,
                }
            end
        end
        debugPrint("^6Bridge^7: ^3GetStashItems^7: ^2Stash information for '^6"..stashName.."^7' retrieved")
    end
    return items
end

-------------------------------------------------------------
-- Stash Item Removal Function
-------------------------------------------------------------

--- Removes items from a stash using the active inventory system.
---
--- Iterates over the provided items and adjusts the stash contents accordingly.
---
--- @param stashItems table The current stash items.
--- @param stashName string|table The stash identifier (or table of identifiers).
--- @param items table A table of items to remove (keys are item names, values are amounts).
---
--- @usage
--- ```lua
--- stashRemoveItem(currentItems, "playerStash", { iron = 2, wood = 5 })
--- ```
function stashRemoveItem(stashItems, stashName, items)
    if stashName == "" or stashName == nil then
        print("^1ERROR^7: ^1stashRemoveItem triggered but stashName was empty^7")
        return
    end
    if type(stashName) ~= "table" then
        stashName = { stashName }
    end

    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            inv.stashRemoveItem(stashItems, stashName, items)
            return
        end
    end

    -- Fallback to core functions
    if isStarted(QBExport) then
        local stashItems = getStash(stashName[1])
        for k, v in pairs(items) do
            for l in pairs(stashItems) do
                if stashItems[l].name == k then
                    if (stashItems[l].amount - v) <= 0 then
                        stashItems[l] = nil
                    else
                        debugPrint("^6Bridge^7: ^2Removing ^3"..PSInv.." ^2Stash item^7:", k, v)
                        stashItems[l].amount -= v
                    end
                end
            end
        end
        debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QBCORE^2 stash ^7'^6"..stashName[1].."^7'")
        MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
            ['stash'] = stashName[1],
            ['items'] = json.encode(stashItems)
        })
    elseif isStarted(ESXExport) then
        --?
    end
    print("^4ERROR^7: ^2No supported Inventory detected ^7- ^2Check ^3starter^1.^2lua^7")
end
RegisterNetEvent(getScript()..":server:stashRemoveItem", stashRemoveItem)

function stashAddItem(stashItems, stashName, items)
    -- wip
end

-------------------------------------------------------------
-- Stash Item Availability Check
-------------------------------------------------------------

--- Checks whether a stash has the required amount of specific items.
---
--- It iterates through the provided items and tallies available quantities.
---
--- @param stashItems table The items available in the stash.
--- @param items string|table The item name or table of required items (key: item, value: amount).
--- @param amount number (Optional) The required amount (if a single item is provided).
--- @return boolean, table (`boolean, string`) Returns true (and a table with counts) if all items are available; false otherwise.
---
--- @usage
--- ```lua
--- local hasAll, details = stashhasItem(currentStashItems, { iron = 2, wood = 5 })
--- ```
function stashhasItem(stashItems, items, amount)
    local invs = { OXInv, CoreInv, CodeMInv, OrigenInv, TgiannInv, JPRInv, QBInv, PSInv, RSGInv }
    local foundInv = ""

    for _, inv in ipairs(invs) do
        if isStarted(inv) then
            foundInv = inv:gsub("%-", "^7-^6"):gsub("%_", "^7_^6")
            break
        end
    end

    -- Ensure items is a table.
    if type(items) ~= "table" then items = { [items] = amount and amount or 1, } end

    local hasTable = {}
    for item, requiredAmount in pairs(items) do
        local count = 0
        for _, itemData in pairs(stashItems) do
            if itemData and (itemData.name == item) then
                count += (itemData.amount or 1)
            end
        end

        local debugMsg = string.format("^6Bridge^7: ^3stashHasItem^7[^6%s^7]: %s '%s' ^3%d^7/^3%d^7", foundInv, (count >= requiredAmount and "^5FOUND^7" or "^1NOT FOUND^7"), item, count, requiredAmount)
        debugPrint(debugMsg)

        hasTable[item] = { hasItem = (count >= requiredAmount), count = count }
    end

    for k, v in pairs(hasTable) do
        if v.hasItem == false then
            return false, hasTable
        end
    end

    return true, hasTable
end


--- Registers a stash with the active inventory system.
--- Not all
---
--- @param name string Unique stash identifier.
--- @param label string Display name for the stash.
--- @param slots number|nil (Optional) Number of slots (default 50).
--- @param weight number|nil (Optional) Maximum weight (default 4000000).
--- @param owner string|nil (Optional) Owner identifier for personal stashes.
--- @param coords table|nil (Optional) Coordinates for the stash location.
--- @usage
--- ```lua
--- registerStash(
---     "playerStash",
---     "Player Stash",
---     100,
---     8000000,
---     "player123",
---     { x = 100.0, y = 200.0, z = 30.0 }
--- )
--- ```
function registerStash(name, label, slots, weight, owner, coords)

    -- ensure tables exist
    stashExploitCheck = stashExploitCheck or {}
    stashExploitCheck[name] = stashExploitCheck[name] or {}
    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            inv.registerStash(name, label, slots, weight, owner, coords)
            debugPrint("^6Bridge^7: ^2Registering ^4"..inv.invName.." ^3Stash^7:", name, "^4Label^7: "..label, coords and "- ^4Coord^7: "..formatCoord(coords) or "NO COORD SET")
            break
        end
    end

    if coords then
        stashExploitCheck[name][#stashExploitCheck[name]+1] = coords.xyz
    else
        print("^3Warning^7: ^1Stash ^4"..name.." ^1doesn^7'^1t have coords^7, ^1this is exploitable^7, ^1add coords to ^3regiterStash^7()")
    end
end

if isServer() then
    --- Registers an event to create an OX stash from the server.
    --- When triggered, it calls registerStash with the provided parameters.
    ---
    --- @event server:makeOXStash
    --- @param name string Unique stash identifier.
    --- @param label string Display name for the stash.
    --- @param slots number|nil (Optional) Number of slots.
    --- @param weight number|nil (Optional) Maximum weight.
    --- @param owner string|nil (Optional) Owner identifier.
    --- @param coords table|nil (Optional) Stash coordinates.
    --- @usage
    --- ```lua
    --- TriggerEvent(getScript()..":server:makeOXStash", name, label, slots, weight, owner, coords, token)
    --- ```
    RegisterNetEvent(getScript()..":server:makeOXStash", function(name, label, slots, weight, owner, coords, token)
        local src = source or nil
        if src then
            if not checkToken(src, token, "stash", name) then
                return
            end
        end

        registerStash(name, label, slots, weight, owner, coords)
    end)
end

RegisterNetEvent(getScript()..":openGrabBox", function(data, stashData)
    local Ped = PlayerPedId()
	local id = data.metadata and data.metadata.id or data.info and data.info.id or ""

    if isStarted(OXInv) then
        -- this SHOLD be handled within ox_inventory if set up right
        return
    end

	openStash({
		stash = id,
        coords = GetEntityCoords(Ped),
        maxWeight = stashData and stashData.maxWeight or 100000,
        slots = stashData and stashData.slots or 5,
	})
end)


-------------------------------------------------------------
-- Selling Menu and Animation
-------------------------------------------------------------

local sellShopExploitCheck = {}
if isServer() then
    createCallback(getScript()..":getRegisteredSellShopLocation", function(src, name)
        return sellShopExploitCheck[name] or nil
    end)
end

--- Opens a selling menu with available items and prices.
---
--- @param data table Contains selling menu data:
---     - sellTable (`table`) Table with Header and Items (item names and prices).
---     - ped (optional) (`number`) Ped entity involved.
---     - onBack (optional) (`function`) Callback for returning.
--- @usage
--- ```lua
--- sellMenu({
---     sellTable = {
---         Header = "Sell Items",
---         Items = {
---             ["gold_ring"] = 100,
---             ["diamond"] = 500,
---         },
---     },
---     ped = pedEntity,
---     onBack = function() print("Returning to previous menu") end,
--- })
--- ```
function sellMenu(data)
    local origData = data

    local exploitCheck = triggerCallback(getScript()..":getRegisteredSellShopLocation", data.name)
    if not exploitCheck then
        print("^3Warning^7: ^2This isn't a registered store^1, refusing call^7")
        return
    end
    if not distExploitCheck(exploitCheck) then
        return
    end

    local Menu = {}
    if data.sellTable.Items then
        local itemList = {}
        for k, v in pairs(data.sellTable.Items) do itemList[k] = 1 end
        local _, hasTable = hasItem(itemList)
        for k, v in pairsByKeys(data.sellTable.Items) do
            if Items[k] then
                Menu[#Menu + 1] = {
                    isMenuHeader = not hasTable[k].hasItem,
                    icon = invImg(k),
                    header = getItemLabel(k)..(hasTable[k].hasItem and "💰 (x"..hasTable[k].count..")" or ""),
                    txt = (Loc and Loc[Config.Lan]) and Loc[Config.Lan].info["sell_all"]..v.." "..Loc[Config.Lan].info["sell_each"]
                    or "Sell ALL at $"..v.." each",
                    onSelect = function()

                        local token = triggerCallback(AuthEvent)
                        sellAnim({ item = k, price = v, ped = data.ped, onBack = function() sellMenu(data) end }, token)
                    end,
                }
            end
        end
    else
        for k, v in pairsByKeys(data.sellTable) do
            if type(v) == "table" then
                Menu[#Menu + 1] = {
                    arrow = true,
                    header = k,
                    txt = "Amount of items: "..countTable(v.Items),
                    onSelect = function()
                        v.onBack = function()
                            sellMenu(origData)
                        end
                        v.sellTable = data.sellTable[k]
                        v.name = data.name
                        sellMenu(v)
                    end,
                }
            end
        end
    end
    openMenu(Menu, {
        header = data.sellTable.Header or "Amount of items: "..countTable(data.sellTable.Items or data.sellTable),
        headertxt = data.sellTable.Header and "Amount of items: "..countTable(data.sellTable.Items or data.sellTable),
        canClose = true,
        onBack = data.onBack,
    })
end

--- Plays the selling animation and processes the sale transaction.
---
--- Checks if the player has the item, plays animations, triggers the server event for selling,
--- and then calls the onBack callback if provided.
---
--- @param data table Contains:
---   `- item: The item to sell.
---   `- price: Price per item.
---   `- ped (optional): Ped entity involved.
---   `- onBack (optional): Callback to call on completion.
---@usage
--- ```lua
--- sellAnim({
---     item = "gold_ring",
---     price = 100,
---     ped = pedEntity,
---     onBack = function() sellMenu(data) end,
--- })
--- ```
function sellAnim(data, token)
    if not hasItem(data.item, 1) then
        triggerNotify(nil, (Loc[Config.Lan].error["dont_have"] or "You don't have any") .." "..getItemLabel(data.item), "error")
        return
    end

    -- Remove any attached clipboard objects.
    for _, obj in pairs(GetGamePool('CObject')) do
        for _, model in pairs({ `p_cs_clipboard` }) do
            if GetEntityModel(obj) == model and IsEntityAttachedToEntity(data.ped, obj) then
                DeleteObject(obj)
                DetachEntity(obj, 0, 0)
                SetEntityAsMissionEntity(obj, true, true)
                Wait(100)
                DeleteEntity(obj)
            end
        end
    end

    TriggerServerEvent(getScript()..":Sellitems", data, token)
    lookEnt(data.ped)
    local dict = "mp_common"
    playAnim(dict, "givetake2_a", 0.3, 48)
    playAnim(dict, "givetake2_b", 0.3, 48, data.ped)
    Wait(2000)
    StopAnimTask(PlayerPedId(), dict, "givetake2_a", 0.5)
    StopAnimTask(data.ped, dict, "givetake2_b", 0.5)
    if data.onBack then
        data.onBack()
    end
end

local bannedItems = {
    money = true,
    cash = true,
    bank = true,
    crypto = true,
    blackmoney = true,
    dirty_money = true,
    markedbills = true
}

--- Server event handler for processing item sales.
--- Removes sold items from inventory and funds the player based on the sale.
RegisterNetEvent(getScript()..":Sellitems", function(data, token)
    local src = source

    if not checkToken(src, token, "item", "cash") then
        return
    end
    -- Check bannedItems list
    for k, v in pairs(bannedItems) do
        if data.item == k then
            dupeWarn(src, data.item, "^3Source^7: "..src.." ^1Tried to spawn banned item with sell items function")
            return
        end
    end

    local hasItems, hasTable = hasItem(data.item, 1, src)
    if hasItems then
        removeItem(data.item, hasTable[data.item].count, src)
        print((hasTable[data.item].count * data.price), data.price)
        fundPlayer((hasTable[data.item].count * data.price), "cash", src)
    else
        triggerNotify(nil, Loc[Config.Lan].error["dont_have"].." "..getItemLabel(data.item), "error", src)
    end
end)

function registerSellShop(name, coords)
    if coords then
        debugPrint("^6Bridge^7: ^2Registering ^3Sell Store^7: "..name, coords and "- ^4Coord^7: "..formatCoord(coords) or "NO COORD SET")
        sellShopExploitCheck[name] = sellShopExploitCheck[name] or {}
        sellShopExploitCheck[name][#sellShopExploitCheck[name]+1] = coords
    end
end

-------------------------------------------------------------
-- Shop Interface
-------------------------------------------------------------

-- Keep a local cache of all registered shops coords, if they are actually registering in the inventory or not
local shopExploitCheck = {}

if isServer() then
    createCallback(getScript()..":getRegisteredShopLocation", function(src, name)
        return shopExploitCheck[name] or nil
    end)
end

--- Opens a shop interface for the player.
---
--- Checks job/gang restrictions, then uses the active inventory system to open the shop.
--- @param data table Contains:
---     - shop (`string`) The shop identifier.
---     - items (`table`) The items available in the shop.
---     - coords (`vector3`) where the shop is located.
---     - job/gang (optional) (`string`) Job or gang requirements.
---@usage
--- ```lua
--- openShop({
---     shop = "weapon_shop",
---     items = weaponShopItems,
---     coords = vector3(100.0, 200.0, 300.0),
---     job = "police",
--- })
--- ```
function openShop(data)
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end

    -- If shop has registered coords, limit players from being too far away from it when opening
    local exploitCheck = triggerCallback(getScript()..":getRegisteredShopLocation", data.shop)
    if not exploitCheck then
        print("^3Warning^7: ^2This isn't a registered store^1, refusing call^7")
        return
    end

    if not distExploitCheck(exploitCheck) then
        return
    end

    if Config.General.JimShops then
        TriggerServerEvent("jim-shops:ShopOpen", "shop", data.items.label, data.items)
        lookEnt(data.coords)
        return
    end
    if not data.items.items[1] then
        local shopMenu = {}
        for k, v in pairs(data.items.items) do
            local clonedTable = cloneTable(data)
            local itemsTable = v.items or v.Items
            shopMenu[#shopMenu+1] = {
                header = v.header or k,
                txt = countTable(itemsTable).." Products",
                onSelect = function()
                    --clonedTable.originShop = data.shop
                    clonedTable.shop = data.shop.."_"..k
                    clonedTable.label = data.items.label.." - "..(v.header or k)
                    clonedTable.slots = #itemsTable
                    clonedTable.items.items = itemsTable
                    openShop(clonedTable)
                end,
            }
        end
        return openMenu(shopMenu, { header = data.items.label, canClose = true, })
    end


    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            inv.openShop(data.shop, data.items.label, data.items)
            lookEnt(data.coords)
            return
        end
    end

    if isStarted(QBExport) then
        TriggerServerEvent(getScript()..':server:openServerShop', data.shop)
        TriggerServerEvent("inventory:server:OpenInventory", "shop", data.items.label, data.items)
    elseif isStarted(ESXExport) then
        --?
    end

end

RegisterNetEvent(getScript()..':server:openServerShop', function(shopName)
    local src = source

    -- If shop has registered coords, limit players from being too far away from it when opening
    if not shopExploitCheck[shopName] then
        print("^3Warning^7: ^1Source^7: ^3"..src.." ^1Tried to open a shop ^7'"..shopName.."' ^2This isn't a registered store^7, ^1refusing call^7")
        return
    end
    if not distExploitCheck(shopExploitCheck[shopName], src) then
        return
    end

    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            inv.serverOpenShop(shopName)
            break
        end
    end

end)

--- Registers a shop with the active inventory system.
---
--- @param name string Unique shop identifier.
--- @param label string Display name for the shop.
--- @param items table List of available shop items.
--- @param society string|nil (Optional) Society identifier for shared shops.
--- @usage
--- ```lua
--- registerShop("weaponShop", "Weapon Shop", weaponItems, "society_weapons")
--- ```
function registerShop(name, label, items, society, coords)
    -- ensure tables exist
    shopExploitCheck = shopExploitCheck or {}
    shopExploitCheck[name] = shopExploitCheck[name] or {}

    if isStarted("jim-shops") then
        -- Add support for new jim-shops registration export
        if checkExportExists("jim-shops", "registerShop") then
            exports["jim-shops"]:registerShop(name, label, items, society, coords)
        end
    end

    for i = 1, #InvFunc do
        local inv = InvFunc[i]
        if isStarted(inv.invName) then
            if not items[1] then
                for k, v in pairs(items) do
                    inv.registerShop(name.."_"..k, label.." - "..(v.header or k), v.items, society)
                    shopExploitCheck[name.."_"..k] = shopExploitCheck[name.."_"..k] or {}
                    shopExploitCheck[name.."_"..k][#shopExploitCheck[name.."_"..k]+1] = coords

                    debugPrint("^6Bridge^7: ^2Registering ^5"..inv.invName.." ^3Store^7:", name.."_"..k, "^4Label^7: "..label.." - "..(v.header or k), coords and "- ^4Coord^7: "..formatCoord(coords) or "NO COORD SET")
                end
            else
                inv.registerShop(name, label, items, society)
                debugPrint("^6Bridge^7: ^2Registering ^5"..inv.invName.." ^3Store^7:", name, "^4Label^7: "..label, coords and "- ^4Coord^7: "..formatCoord(coords) or "NO COORD SET")
            end
            break
        end
    end

    -- If received coords, pass them to distance check cache
    if coords then
        shopExploitCheck[name][#shopExploitCheck[name]+1] = coords
    else
        print("^3Warning^7: ^1Store ^4"..name.." ^1doesn^7'^1t have coords^7, ^1this is exploitable^7, ^1add coords to ^3regiterShop^7()")
    end
end
