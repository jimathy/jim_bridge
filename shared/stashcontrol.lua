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
    if stop then
        stashCache = {}
        return
    end

    -- Retrieve cache for this stash, or initialize if not present.
    stash = stashCache[stashName]
    if not stash then
        debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache ^1not ^2found^7, ^2need to grab from server^7")
        stashCache[stashName] = { items = {}, timeout = 0 }
        stash = stashCache[stashName]
    else
        debugPrint("^6Bridge^7: ^2Local Stash ^7'^3"..stashName.."^7'^2 cache found^7")
        ("^6Bridge^7: ^2Local Stash '^3"..stashName.."^7' cache found")
    end

    -- If there are already items in cache, skip recheck.
    if countTable(stashCache[stashName].items) > 0 then
        debugPrint("^6Bridge^7: '^3"..stashName.." ^2Items found in cache, skipping recheck")
        return true
    end

    -- If timeout has expired, update the stash items from the server.
    if stashCache[stashName].timeout <= 0 then
        stashCache[stashName].items = triggerCallback(getScript()..':server:GetStashItems', stashName)
        stashCache[stashName].timeout = 15000  -- Timeout in milliseconds.
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
--- local found, stashName = checkHasItem({"playerStash", "storageStash"}, { iron = 2, wood = 5 })
--- ```
function checkHasItem(stashes, itemTable)
    if not stashes then
        return hasItem(itemTable), nil
    end

    if type(stashes) == "table" then
        local successes = 0
        local itemCount = countTable(itemTable)
        -- Iterate over each provided stash name.
        for _, name in pairs(stashes) do
            Wait(10)  -- Delay to avoid multiple callbacks issues.
            GetStashTimeout(name)
            for item, amount in pairs(itemTable) do
                debugPrint("^6Bridge^7: ^2Checking "..(name and " '^3"..name.."^7'" or "").." ingredients - ^6"..item.."^7")
                if stashhasItem(stashCache[name].items, item, amount) then
                    successes = successes + 1
                    if successes == itemCount then
                        return true, name
                    end
                end
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

    if isStarted(OXInv) then
        exports[OXInv]:openInventory('stash', data.stash)

    elseif isStarted(CoreInv) then
        TriggerServerEvent('core_inventory:server:openInventory', data.stash, 'stash')

    elseif isStarted(CodeMInv) then
        TriggerServerEvent('codem-inventory:server:openstash', data.stash, data.slots, data.maxWeight, data.label)

    elseif isStarted(OrigenInv) then
        exports[OrigenInv]:openInventory('stash', data.stash, { label = data.label })

    elseif isStarted(QBInv) then
        if QBInvNew then
            TriggerServerEvent(getScript()..':server:OpenStashQB', {
                stashName = data.stash,
                label = data.label,
                maxweight = data.maxWeight or 600000,
                slots = data.slots or 40
            })
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

-- Register an event for opening QB stashes.
RegisterNetEvent(getScript()..':server:OpenStashQB', function(data)
    exports[QBInv]:OpenInventory(source, data.stashName, data)
end)

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
    local stashResource = ""
    if type(stashName) ~= "string" then
        print("^6Bridge^7: ^2Stash name was not a string ^3"..stashName.."^7(^3"..type(stashName).."^7)")
        return {}
    end

    local stashItems, items = {}, {}
    if isStarted(OXInv) then stashResource = OXInv
        stashItems = exports[OXInv]:Inventory(stashName).items

    elseif isStarted(QSInv) then stashResource = QSInv
        stashItems = exports[QSInv]:GetStashItems(stashName)

    elseif isStarted(CoreInv) then stashResource = CoreInv
        stashItems = exports[CoreInv]:getInventory(stashName)

    elseif isStarted(CodeMInv) then stashResource = CodeMInv
        stashItems = exports[CodeMInv]:GetStashItems(stashName)

    elseif isStarted(OrigenInv) then stashResource = OrigenInv
        stashItems = exports[OrigenInv]:getInventory(stashName)

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
    jsonPrint(items)
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
        exports[CodeMInv]:UpdateStash(stashName, stashItems)
        debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3CodeM^2 stash ^7'^6"..stashName.."^7'")
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
        MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
            ['stash'] = stashName,
            ['items'] = json.encode(stashItems)
        })

    elseif isStarted(QBInv) then
        if QBInvNew then
            for k, v in pairs(items) do
                exports[QBInv]:RemoveItem(stashName[1], k, v, false, 'crafting')
                debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..QBInv, k, v)
            end
            debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName[1].."^7'")
            MySQL.Async.insert('INSERT INTO inventories (identifier, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                ['stash'] = stashName[1],
                ['items'] = json.encode(stashItems)
            })
        else
            for k, v in pairs(items) do
                for l in pairs(stashItems) do
                    if stashItems[l].name == k then
                        if (stashItems[l].amount - v) <= 0 then
                            debugPrint("^6Bridge^7: ^2None of this item left in stash ^3Stash^7", k, v)
                            stashItems[l] = nil
                        else
                            debugPrint("^6Bridge^7: ^2Removing item from ^3Stash^2 with "..QBInv, k, v)
                            stashItems[l].amount -= v
                        end
                    end
                end
            end
            debugPrint("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash '^6"..stashName.."^7'")
            MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', {
                ['stash'] = stashName,
                ['items'] = json.encode(stashItems)
            })
        end

    else
        print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3starter^1.^2lua^7")
    end
end
RegisterNetEvent(getScript()..":server:stashRemoveItem", stashRemoveItem)

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
    local invs = { OXInv, QSInv, CoreInv, CodeMInv, OrigenInv, QBInv, PSInv }
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

    for k, v in pairs(hasTable) do if v.hasItem == false then return false, hasTable end end

    return true, hasTable
end
