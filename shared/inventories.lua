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

    if grabInv then
        local hasTable = {}
        for item, amt in pairs(items) do
            if not Items[item] then print("^4ERROR^7: ^2Script can't find ingredient item in Shared Items - ^1"..item.."^7") end

            local count = 0
            for _, itemData in pairs(grabInv) do
                jsonPrint(itemData)
                if itemData and itemData.name == item then
                    count += (itemData.amount or itemData.count or 1)
                end
            end
            foundInv = foundInv:gsub("%-", "^7-^6"):gsub("%_", "^7_^6")
            local foundMessage = "^6Bridge^7: ^3hasItem^7[^6"..foundInv.."^7]: "..tostring(item).." ^3"..count.."^7/^3"..amt
            if count >= amt then foundMessage = foundMessage.." ^5FOUND^7" else foundMessage = foundMessage .." ^1NOT FOUND^7" end
            debugPrint(foundMessage)
            hasTable[item] = { hasItem = count >= amt, count = count }
        end
        for k, v in pairs(hasTable) do
            if not v.hasItem then
                return false, hasTable
            end
        end
        return true, hasTable
    end
    -- if can't find inventory, return false
    print("^1Error^7: ^1Can't find players inventory for some reason")
    return false, {}
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

    if isStarted(OXInv) then
        foundInv = OXInv
        if src then
            grabInv = exports[OXInv]:GetInventoryItems(src)
        else
            grabInv = exports[OXInv]:GetPlayerItems()
        end

    elseif isStarted(QSInv) then
        foundInv = QSInv
        if src then
            grabInv = exports[QSInv]:GetInventory(src)
        else
            --grabInv = exports[QSInv]:getUserInventory()
            grabInv = triggerCallback(getScript()..":getServerInvData", GetPlayerServerId(PlayerId()))
        end

    elseif isStarted(OrigenInv) then
        foundInv = OrigenInv
        if src then
            grabInv = exports[OrigenInv]:getInventory(src)
        else
            grabInv = exports[OrigenInv]:getInventory()
        end

    elseif isStarted(CoreInv) then
        foundInv = CoreInv
        if src then
            grabInv = exports[CoreInv]:getInventory(src)
        else
            grabInv = exports[CoreInv]:getInventory()
        end

    elseif isStarted(CodeMInv) then
        foundInv = CodeMInv
        if src then
            grabInv = exports[CodeMInv]:GetInventory(getPlayer(src).citizenId, src)
        else
            grabInv = exports[CodeMInv]:getUserInventory()
        end

    elseif isStarted(TgiannInv) then
        foundInv = TgiannInv
        if src then
            grabInv = exports[TgiannInv]:GetPlayerItems(src)
        else
            grabInv = exports[TgiannInv]:GetPlayerItems()
        end

    elseif isStarted(QBInv) then
        foundInv = QBInv
        if src then
            grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else
            grabInv = Core.Functions.GetPlayerData().items
        end

    elseif isStarted(PSInv) then
        foundInv = PSInv
        if src then grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else grabInv = Core.Functions.GetPlayerData().items end

    elseif ESX and isStarted(ESXExport) then
        foundInv = ESX
        if src then
            local xPlayer = ESX.GetPlayerFromId(src)
            grabInv = xPlayer.inventory
        else
            local xPlayer = ESX.GetPlayerData()  -- Client side, if available
            grabInv = xPlayer.inventory
        end

    elseif isStarted(RSGInv) then
        foundInv = RSGInv
        if src then
            grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else
            grabInv = Core.Functions.GetPlayerData().items
        end

    else
        print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3starter^1.^2lua^7")
    end
    return grabInv, foundInv
end

createCallback(getScript()..":getServerInvData", function(source)
    local src = source
    return getPlayerInv(src)
end)

function isInventoryOpen()
    if isStarted(OXInv) then
        return LocalPlayer.state.invBusy

    elseif isStarted(QSInv) then
        return exports[QSInv]:inInventory()

    elseif isStarted(OrigenInv) then
        return exports[OrigenInv]:IsInventoryOpen()

    elseif isStarted(CoreInv) then
        return exports[CoreInv]:isInventoryOpen()

    elseif isStarted(CodeMInv) then
        return false
        -- CodeM doesn't have a function to check if the inventory is open
        -- No idea what it uses, so it just skips the check

    elseif isStarted(TgiannInv) then
        return exports[TgiannInv]:IsInventoryActive()

    elseif isStarted(QBInv) then
        return LocalPlayer.state.inv_busy

    elseif isStarted(PSInv) then
        return LocalPlayer.state.inv_busy

    elseif ESX and isStarted(ESXExport) then
        return false

    elseif isStarted(RSGInv) then
        return LocalPlayer.state.inv_busy

    end
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
    if item ~= "" and Items[item] then
        if isStarted(OXInv) then
            imgLink = "nui://"..OXInv.."/web/images/"..(Items[item].image or "")

        elseif isStarted(QSInv) then
            imgLink = "nui://"..QSInv.."/html/images/"..(Items[item].image or "")

        elseif isStarted(CoreInv) then
            imgLink = "nui://"..CoreInv.."/html/img/"..(Items[item].image or "")

        elseif isStarted(CodeMInv) then
            imgLink = "nui://"..CodeMInv.."/html/itemimages/"..(Items[item].image or "")

        elseif isStarted(OrigenInv) then
            imgLink = "nui://"..OrigenInv.."/html/img/"..(Items[item].image or "")

        elseif isStarted(QBInv) then
            imgLink = "nui://"..QBInv.."/html/images/"..(Items[item].image or "")

        elseif isStarted(PSInv) then
            imgLink = "nui://"..PSInv.."/html/images/"..(Items[item].image or "")

        elseif isStarted(TgiannInv) then
            imgLink = "nui://inventory_images/images/"..(Items[item].image or "")

        elseif isStarted(RSGInv) then
            imgLink = "nui://"..RSGInv.."/html/images/"..(Items[item].image or "")

        else
            print("^4ERROR^7: ^2No Inventory detected for invImg - Check starter.lua")
        end
    end
    return imgLink
end