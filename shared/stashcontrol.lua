local stash
if isServer() then
    createCallback(getScript()..':server:GetStashItems',
        function(source, stashName)
            stash = getStash(stashName) return stash
        end)
end

local stashCache ={}
function GetStashTimeout(stashName, stop)
    if stop then
        stashCache = {}
        return
    end
    stash = stashCache[stashName]
    if not stash then
        debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache ^1not ^2found^7, ^2need to grab from server^7")
        stashCache[stashName] = { items = {}, timeout = 0 }
        stash = stashCache[stashName]
    else
        debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache found^7")
    end
    if countTable(stashCache[stashName].items) > 0 then
        debugPrint("^6Bridge^7: '^3"..stashName.." ^2Items found in cache, skipping recheck")
        return true
    end
    if stashCache[stashName].timeout <= 0 then
        stashCache[stashName].items = triggerCallback(getScript()..':server:GetStashItems', stashName)
        stashCache[stashName].timeout = 15000
        CreateThread(function()
            while stash.timeout > 0 do
                stashCache[stashName].timeout -= 1000
                Wait(1000)
            end
            debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache timed out^7, ^3Clearing^7")
            stashCache[stashName] = nil
        end)
    end
    return false
end

function checkHasItem(stashes, itemTable)
    if not stashes then
        return hasItem(itemTable), nil
    end
    if type(stashes) == "table" then
        local succeses = 0
        local itemCount = countTable(itemTable)
        --for _, item in pairs(itemTable) do itemCount += 1 end
        for _, name in pairs(stashes) do
            Wait(10) -- add delay because qb doesn't appreciate multiple callbacks for stashes
            GetStashTimeout(name)
            for item, amount in pairs(itemTable) do
                debugPrint("^6Bridge^7: ^2Checking"..(name and " ^7'^6"..name.."^7'" or "").." ^2ingredients^7 - ^6"..item.."^7")
                if stashhasItem(stashCache[name].items, item, amount) then
                    succeses += 1
                    if succeses == itemCount then
                        return true, name
                    end
                end
            end
        end
    else
        debugPrint("^6Bridge^7: ^2Checking"..(stashes and " ^7'^6"..stashes.."^7'" or "").." ^2ingredients^7 - ^6"..k.."^7")
        GetStashTimeout(stashes)
        return stashhasItem(stashCache[stashes].items, itemTable), stashes
    end
    return false, nil
end


-- Stash Items
function openStash(data)
	if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
    if isStarted(OXInv) then
        exports[OXInv]:openInventory('stash', data.stash)
    elseif isStarted(CodeMInv) then
        exports[CodeMInv]:OpenStash(data.stash, StashWeight, 100)
    elseif isStarted(QBInv) then
        if QBInvNew then
            TriggerServerEvent(getScript()..':server:OpenStashQB', { stashName = data.stash, label = data.label, maxweight = data.maxWeight or 600000, slots = data.slots or 40 })
        else
            TriggerEvent("inventory:client:SetCurrentStash", data.stash)
            TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, data.stashOptions)
        end
    else
        TriggerEvent("inventory:client:SetCurrentStash", data.stash)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, data.stashOptions)
	end
    lookEnt(data.coords)
end

RegisterNetEvent(getScript()..':server:OpenStashQB', function(data)
    exports[QBInv]:OpenInventory(source, data.stashName, data)
end)

function getStash(stashName) local stashResource = ""
    if type(stashName) ~= "string" then
        return print("Stash name was not a string %s(%s)", stashName, type(stashName))
    end
    local stashItems, items = {}, {}
    if isStarted(OXInv) then stashResource = OXInv
        stashItems = exports[OXInv]:Inventory(stashName).items

    elseif isStarted(QSInv) then stashResource = QSInv
        stashItems = exports[QSInv]:GetStashItems(stashName)

    elseif isStarted(CoreInv) then stashResource = CoreInv
        stashItems = exports[CoreInv]:getInventory(stashName)

    elseif isStarted(CodeMInv) then stashResource = CodeMInv
        stashItems = exports[CodeMInv]:GetInventoryItems('Stash', stashName)

    elseif isStarted(OrigenInv) then stashResource = OrigenInv
        stashItems = exports[OrigenInv]:GetStashItems(stashName)

    elseif isStarted(PSInv) then stashResource = PSInv
        local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
		if result then stashItems = json.decode(result) end
    elseif isStarted(QBInv) then stashResource = QBInv
        local result = MySQL.scalar.await("SELECT items FROM "..(QBInvNew and "inventories" or "stashitem").." WHERE identifier = ?", { stashName })
        if result then stashItems = json.decode(result) end
    end

    debugPrint("^6Bridge^7: ^2Retrieving ^3Stash^2 with ^7"..stashResource)
    if stashItems then
        for _, item in pairs(stashItems) do
            local itemInfo = Items[item.name:lower()]
            if itemInfo then
                local indexNum = #items+1 -- Added to help recreate missing slot numbers
                items[(item.slot and item.slot) or indexNum] = {
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
        debugPrint("^6Bridge^7: ^3GetStashItems^7: ^2Stash information for ^7'^6"..stashName.."^7' ^2retrieved^7")
    end
    jsonPrint(items)
    return items
end

function stashRemoveItem(stashItems, stashName, items) local amount = amount and amount or 1
    -- print("stashItems: "..json.encode(stashItems, { indent = true}))
    -- print("stashName: "..json.encode(stashName, { indent = true}))
    -- print("items: "..json.encode(items, { indent = true}))
    if isStarted(OXInv) then
        for k, v in pairs(items) do
            debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..OXInv, k, v)
            if type(stashName) == "table" then
                for _, name in pairs(stashName) do
                    local success = exports[OXInv]:RemoveItem(name, k, v)
                    if success then
                        debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..OXInv, k, v)
                        break
                    end
                end
            else
                exports[OXInv]:RemoveItem(stashName, k, v)
            end
        end

    elseif isStarted(QSInv) then
            for k, v in pairs(items) do
                for l in pairs(stashItems) do
                    if stashItems[l].name == k then
                        if (stashItems[l].amount - v) <= 0 then
                            debugPrint("^6Bridge^7: ^2None of this item left in stash ^3Stash^7", k, v)
                            stashItems[l] = nil
                        else
                            debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..QBInv, k, v)
                            exports[QSInv]:RemoveItemIntoStash(stashName, k, v, l)
                        end
                    end
                end
            end

    elseif isStarted(CoreInv) then
        for k, v in pairs(items) do
            exports[CoreInv]:removeItemExact(stashName, k, v)
            debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..CoreInv, k, v)
        end

    elseif isStarted(CodeMInv) then
        for k, v in pairs(items) do
            for l in pairs(stashItems) do
                if stashItems[l].name == k then
                    if (stashItems[l].amount - v) <= 0 then
                        debugPrint("^6Bridge^7: ^2None of this item left in stash ^3Stash^7", k, v)
                        stashItems[l] = nil
                    else
                        debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..CodeMInv, k, v)
                        stashItems[l].amount -= v
                    end
                end
            end
        end
        debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName.."^7'")

    elseif isStarted(OrigenInv) then
        for k, v in pairs(items) do
            exports[OrigenInv]:RemoveFromStash(stashName, k, v)
            debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..OrigenInv, k, v)
        end

    elseif isStarted(PSInv) then
        for k, v in pairs(items) do
            for l in pairs(stashItems) do
                if stashItems[l].name == k then
                    if (stashItems[l].amount - v) <= 0 then
                        debugPrint("^6Bridge^7: ^2None of this item left in stash ^3Stash^7", k, v)
                        stashItems[l] = nil
                    else
                        debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..QBInv, k, v)
                        stashItems[l].amount -= v
                    end
                end
            end
        end
        debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName.."^7'")
        MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', { ['stash'] = stashName, ['items'] = json.encode(stashItems) })
    elseif isStarted(QBInv) then
        if QBInvNew then
            for k, v in pairs(items) do
                exports[QBInv]:RemoveItem(stashName[1], k, v, false, 'crafting')
                debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..QBInv, k, v)
            end
            debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName[1].."^7'")
            MySQL.Async.insert('INSERT INTO inventories (identifier, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', { ['stash'] = stashName[1], ['items'] = json.encode(stashItems) })
        else
            for k, v in pairs(items) do
                for l in pairs(stashItems) do
                    if stashItems[l].name == k then
                        if (stashItems[l].amount - v) <= 0 then
                            if Config.System.Debug then
                                print("^6Bridge^7: ^2None of this item left in stash ^3Stash^7", k, v)
                            end
                            stashItems[l] = nil
                        else
                            if Config.System.Debug then
                                print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..QBInv, k, v)
                            end
                            stashItems[l].amount -= v
                        end
                    end
                end
            end
            debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName.."^7'")
            MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', { ['stash'] = stashName, ['items'] = json.encode(stashItems) })
        end
    else
        print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
end
RegisterNetEvent(getScript()..":server:stashRemoveItem", stashRemoveItem)

function stashhasItem(stashItems, items, amount)
    local invs = {OXInv, QSInv, CoreInv, CodeMInv, OrigenInv, QBInv, PSInv}
    local foundInv = ""
    for _, inv in ipairs(invs) do
        if isStarted(inv) then
            foundInv = inv:gsub("%-", "^7-^6"):gsub("%_", "^7_^6")
            break
        end
    end

    if type(items) ~= "table" then items = { [items] = amount and amount or 1, } end
    local hasTable = {}
    for item, amount in pairs(items) do
        local count = 0
        for _, itemData in pairs(stashItems) do
            if itemData and (itemData.name == item) then
                count += (itemData.amount or 1)
            end
        end

        local debugMsg = string.format("^6Bridge^7: ^3stashHasItem^7[^6%s^7]: %s '%s' ^3%d^7/^3%d^7", foundInv, (count >= amount and "^5FOUND^7" or "^1NOT FOUND^7"), item, count, amount)
        debugPrint(debugMsg)

        hasTable[item] = { hasItem = (count >= amount), count = count }
    end
    for k, v in pairs(hasTable) do if v.hasItem == false then return false, hasTable end end
    return true, hasTable
end