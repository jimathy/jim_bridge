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
                if itemData and itemData.name == item then
                    count += (itemData.count or itemData.amount or 1)
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
            grabInv = exports[QSInv]:getUserInventory()
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
            grabInv = exports[CodeMInv]:GetInventory(src)
        else
            grabInv = exports[CodeMInv]:GetClientPlayerInventory()
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