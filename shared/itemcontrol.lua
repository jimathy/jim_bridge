-- Function to register items as usable for ESX, QBX, and QBcore --
---
--- This function registers an item as usable across different inventory systems such as ESX, QBcore, and QBX.
--- It checks which inventory system is active and registers the usable item accordingly.
---
---@param item string The name of the item to be registered as usable.
---@param funct function The function to execute when the item is used.
---
---@usage
--- ```lua
--- createUseableItem("health_potion", function(source)
---     -- Code to consume the health potion
--- end)
--- ```
function createUseableItem(item, funct)
    if isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^2Registering item as ^3Usable^2 with ^7es_extended", item)
        while not ESX do Wait(0) end
        ESX.RegisterUsableItem(item, funct)
    elseif isStarted(QBExport) and not isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^2Registering item as ^3Usable^2 with ^7qb-core", item)
        Core.Functions.CreateUseableItem(item, funct)
    elseif isStarted(QBXExport) then
        debugPrint("^6Bridge^7: ^2Registering item as ^3Usable^2 with ^7qbx_core", item)
        exports[QBXExport]:CreateUseableItem(item, funct)
    end
end

-- Simple function to grab the item's image from inventories and retrieve it as a nui:// link --
---
--- This function retrieves the image URL of an item from various inventory systems and formats it as a `nui://` link.
--- It supports multiple inventory systems such as OXInv, QSInv, CoreInv, OrigenInv, QBInv, and CodeMInv.
---
---@param item string The name of the item whose image is to be retrieved.
---@return string link The `nui://` link to the item's image. Returns an empty string if the inventory system is not detected or the item doesn't exist.
---
---@usage
--- ```lua
--- local imageLink = invImg("health_potion")
--- if imageLink ~= "" then
---     print(imageLink)
--- end
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
        elseif isStarted(OrigenInv) then
            imgLink = "nui://"..OrigenInv.."/html/img/"..(Items[item].image or "")
        elseif isStarted(QBInv) then
            imgLink = "nui://"..QBInv.."/html/images/"..(Items[item].image or "")
        elseif isStarted(CodeMInv) then
            imgLink = "nui://"..CodeMInv.."/html/itemimages/"..(Items[item].image or "")
        else
            print("^4ERROR^7: ^2No Inventory detected for invImg ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
    return imgLink
end

--- Adds an item to a player's inventory.
---
--- This function triggers a server event to add a specified amount of an item to the player's inventory.
---
---@param item string The name of the item to add.
---@param amount number The quantity of the item to add.
---@param info table|nil Additional information or metadata for the item.
---
---@usage
--- ```lua
--- addItem("health_potion", 2, { quality = "high" })
--- ```
function addItem(item, amount, info, src)
    if not Items[item] then print("^6Bridge^7: ^1Error^7 - ^2Tried to give ^7'^3"..item.."^7'^2 but it doesn't exist") return end
    if src then
        TriggerEvent(getScript()..":server:toggleItem", true, item, amount, src, info)
    else
        TriggerServerEvent(getScript()..":server:toggleItem", true, item, amount, nil, info)
    end
end

--- Removes an item from a player's inventory.
---
--- This function triggers a server event to remove a specified amount of an item from the player's inventory.
---
---@param item string The name of the item to remove.
---@param amount number The quantity of the item to remove.
---
---@usage
--- ```lua
--- removeItem("health_potion", 1)
--- ```
function removeItem(item, amount, src, slot)
    if not Items[item] then print("^6Bridge^7: ^1Error^7 - ^2Tried to remove ^7'^3"..item.."^7'^2 but it doesn't exist") return end
    if src then
        TriggerEvent(getScript()..":server:toggleItem", false, item, amount, src, nil, slot)
    else
        TriggerServerEvent(getScript()..":server:toggleItem", false, item, amount, nil, nil, slot)
    end
end

--- Server event handler to toggle items in a player's inventory.
---
--- This event handles adding or removing items based on the parameters received.
--- It supports multiple inventory systems and includes exploit protection to prevent duplication.
---
---@param give boolean Indicates whether to add (`true`) or remove (`false`) the item.
---@param item string The name of the item to toggle.
---@param amount number The quantity of the item to toggle.
---@param newsrc number|nil The source ID of the player. If `nil`, it defaults to the event source.
---@param info table|nil Additional information or metadata for the item.
---
---@usage
--- ```lua
--- TriggerServerEvent("script:server:toggleItem", true, "health_potion", 1)
--- ```
RegisterNetEvent(getScript()..":server:toggleItem", function(give, item, amount, newsrc, info, slot)
    if not Items[item] then print("^6Bridge^7: ^1Error^7 - ^2Tried to "..(tostring(give) == "true" and "add" or "remove").." ^7'^3"..item.."^7'^2 but it doesn't exist") return end
    local src = newsrc or source
    local addremove = (tostring(give) == "true" and "addItem" or "removeItem")
    debugPrint("^6Bridge^7: ^3toggleItem ^2triggered^7: ^6"..addremove.."^7 - '"..tostring(item).."' x"..(tostring(amount) or "1"))
    local remamount = (amount and amount or 1)
    if item == nil then return end
    if give == 0 or give == false then
        if hasItem(item, amount and amount or 1, src) then -- Check if the player has the item
            if isStarted(OXInv) then
                local success = exports[OXInv]:RemoveItem(src, item, (amount and amount or 1), nil)
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..OXInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            elseif isStarted(QSInv) then
                local success = exports[QSInv]:RemoveItem(src, item, amount)
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..QSInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

            elseif isStarted(CoreInv) then
                if isStarted(QBExport) then
                    Core.Functions.GetPlayer(src).Functions.RemoveItem(item, amount, nil)
                elseif isStarted(ESXExport) then
                    ESX.GetPlayerFromId(src).removeInventoryItem(item, count)
                end
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..CoreInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

            elseif isStarted(OrigenInv) then
                local success = exports[OrigenInv]:RemoveItem(src, item, amount)
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..OrigenInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

            elseif isStarted(CodeMInv) then
                local success = exports[CodeMInv]:RemoveItem(src, item, amount)
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..CodeMInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

            elseif isStarted(QBInv) then
                while remamount > 0 do
                    if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, 1, slot) then
                        remamount -= 1
                    else
                        print("^1Error removing "..data.item.." Amount left to remove: "..remamount.."^7")
                        break
                    end
                end
                if Config.Crafting.showItemBox then
                    TriggerClientEvent((isStarted(QBInv) and QBInvNew and "qb-" or "")..'inventory:client:ItemBox', src, Items[item], "remove", (amount and amount or 1))
                end
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..QBInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            elseif isStarted(PSInv) then
                while remamount > 0 do
                    if Core.Functions.GetPlayer(src).Functions.RemoveItem(item, 1) then
                        remamount -= 1
                    else
                        print("^1Error removing "..data.item.." Amount left to remove: "..remamount.."^7")
                        break
                    end
                end
                if Config.Crafting.showItemBox then
                    TriggerClientEvent('inventory:client:ItemBox', src, Items[item], "remove", (amount and amount or 1))
                end
                debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..PSInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
            else
                print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
            end
        else
            dupeWarn(src, item, amount) -- Trigger exploit protection
        end
    else
        local amount = amount and amount or 1
        if isStarted(OXInv) then
            local success = exports[OXInv]:AddItem(src, item, amount or 1, info)
            if not Items[item] or not Items[item].label then
                print("^1Error^7: "..addremove.." ["..OXInv.."] Player("..src..") "..Items[item]?.label.."("..item..") x"..(amount or 1))
            end
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..OXInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

        elseif isStarted(QSInv) then
            local success = exports[QSInv]:AddItem(src, item, amount)
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..QSInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

        elseif isStarted(CoreInv) then
            if isStarted(QBExport) or isStarted(QBXExport) then
                Core.Functions.GetPlayer(src).Functions.AddItem(item, amount, nil, nil)
            elseif isStarted(ESXExport) then
                ESX.GetPlayerFromId(src).addInventoryItem(item, amount)
            end
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..CoreInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

        elseif isStarted(CodeMInv) then
            local success = exports[CodeMInv]:AddItem(src, item, amount)
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..CodeMInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
        elseif isStarted(OrigenInv) then
            local success = exports[OrigenInv]:AddItem(src, item, amount)
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..OrigenInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

        elseif isStarted(QBInv) then
            if Core.Functions.GetPlayer(src).Functions.AddItem(item, amount or 1, nil, info) then
                TriggerClientEvent((isStarted(QBInv) and QBInvNew and "qb-" or "")..'inventory:client:ItemBox', src, Items[item], "add", amount and amount or 1)
            end
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..QBInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")

        elseif isStarted(PSInv) then
            if Core.Functions.GetPlayer(src).Functions.AddItem(item, amount or 1, nil, info) then
                if Config.Crafting.showItemBox then
                    TriggerClientEvent("inventory:client:ItemBox", src, Items[item], "add", amount and amount or 1)
                end
            end
            debugPrint("^6Bridge^7: ^3"..addremove.."^7[^6"..PSInv.."^7] ^2Player^7("..src..") ^6"..Items[item].label.."^7("..item..") x^5"..(amount and amount or "1").."^7")
        else
            print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
end)

--- Protects against item duplication exploits by warning and potentially kicking the player.
---
--- This function is called when an attempt is made to remove an item that the player does not possess.
--- It logs the incident and kicks the player if `debugMode` is not enabled.
---
--- @param src number The source ID of the player attempting the exploit.
--- @param item string The name of the item being exploited.
---
--- @usage
--- ```lua
--- dupeWarn(playerId, "health_potion")
--- ```
function dupeWarn(src, item)
    local name = getPlayer(src).name
    print("^5DupeWarn^7: "..name.." (^1"..tostring(src).."^7) ^2Tried to remove item ^7'^3"..item.."^7'^2 but it wasn't there^7")
    if not debugMode then
        DropPlayer(src, name.."("..tostring(src)..") Kicked for suspected duplicating items: "..item)
    end
    print("^5DupeWarn^7: "..name.."(^1"..tostring(src).."^7) ^2Dropped from server - exploit protection detected an item not being found in players inventory^7")
end

--- Breaks a tool by reducing its durability or removing it if durability reaches zero.
---
--- This function handles the durability mechanics for tools. If a tool's durability drops to zero or below,
--- it removes the tool from the player's inventory and plays a breaking sound.
---
--- @param data table A table containing data about the tool being used.
--- - **item** (`string`): The name of the tool item.
--- - **damage** (`number`): The amount of durability damage to apply.
---
--- @usage
--- ```lua
--- breakTool({ item = "drill", damage = 10 })
--- ```
function breakTool(data) -- WIP
    local durability, slot = getDurability(data.item)
    if not durability then durability = 100 end
    durability -= data.damage
    if durability <= 0 then
        removeItem(data.item, 1)
        local breakId = GetSoundId()
        PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
    else
        TriggerServerEvent(getScript()..":server:setMetaData", { item = data.item, slot = slot, metadata = { durability = durability } })
    end
end

--- Retrieves the durability and slot of an item in a player's inventory.
---
--- This function searches the player's inventory for the specified item and returns its durability and slot number.
---
--- @param item string The name of the item to check.
--- @return number|nil The durability of the item. Returns `nil` if not found.
--- @return number|nil The slot number of the item. Returns `nil` if not found.
---
--- @usage
--- ```lua
--- local durability, slot = getDurability("drill")
--- if durability then
---     print("Durability:", durability)
--- end
--- ```
function getDurability(item)
    local lowestSlot = 100
    local durability = nil
    if isStarted(QBInv) or isStarted(PSInv) then
        local itemcheck = Core.Functions.GetPlayerData().items
        for k, v in pairs(itemcheck) do
            if v.name == item then
                if v.slot <= lowestSlot then
                    lowestSlot = v.slot
                    durability = itemcheck[k].info.durability
                end
            end
        end
    end

    if isStarted(OXInv) then
        local itemcheck = exports[OXInv]:Search('slots', item)
        for k, v in pairs(itemcheck) do
            if v.slot <= lowestSlot then
                debugPrint(v.slot, itemcheck[k].metadata.durability)
                lowestSlot = v.slot
                durability = itemcheck[k].metadata.durability
            end
        end
    end

    if isStarted(QSInv) then
        local itemcheck = exports[QSInv]:getUserInventory()
        for k, v in pairs(itemcheck) do
            if v.name == item and v.slot <= lowestSlot then
                lowestSlot = v.slot
                durability = itemcheck[k].metadata.durability
            end
        end
    end

    if isStarted(OrigenInv) then
        local itemcheck = exports[OrigenInv]:getPlayerInventory()
        for k, v in pairs(itemcheck) do
            if v.name == item and v.slot <= lowestSlot then
                lowestSlot = v.slot
                durability = itemcheck[k].metadata.durability
            end
        end
    end
    return durability, lowestSlot
end

--- Server event handler to set metadata for an item in a player's inventory.
---
--- This event updates the metadata (e.g., durability) of an item in the player's inventory.
---
---@param data table A table containing metadata information.
--- - **item** (`string`): The name of the item.
--- - **slot** (`number`): The slot number of the item in the inventory.
--- - **metadata** (`table`): The metadata to set for the item.
---
---@usage
--- ```lua
--- TriggerServerEvent("script:server:setMetaData", { item = "drill", slot = 5, metadata = { durability = 80 } })
--- ```
RegisterNetEvent(getScript()..":server:setMetaData", function(data)
    local src = source
    if isStarted(QBInv) or isStarted(PSInv) then
        debugPrint(src, data.item, 1, data.slot)
        local Player = Core.Functions.GetPlayer(src)
        Player.PlayerData.items[data.slot].info = data.metadata
        Player.PlayerData.items[data.slot].description = "HP : "..data.metadata.durability
        Player.Functions.SetInventory(Player.PlayerData.items)
    end

    if isStarted(OXInv) then
        exports[OXInv]:SetMetadata(source, data.slot, data.metadata)
    end

    if isStarted(QSInv) then
        exports[QSInv]:SetItemMetadata(source, data.slot, data.metadata)
    end

    if isStarted(OrigenInv) then
        local item = exports[OrigenInv]:GetItemBySlot(source, data.slot)
        if item then
            exports[OrigenInv]:SetItemData(source, item.name, "durability", data.metadata.durability)
        end
    end
end)

--- Checks if a player has the specified items in their inventory.
---
--- This function verifies whether a player possesses the required quantity of specified items.
--- It supports multiple inventory systems and provides detailed feedback on item availability.
---
---@param items string|table A single item name or a table of item names with their required amounts.
---@param amount number The quantity required for each item. Defaults to `1` if not specified.
---@param src number|nil The source ID of the player. If `nil`, it defaults to the caller.
---@return boolean Returns `true` if the player has all the required items in the specified amounts.
---@return table|nil Returns a table detailing which items are present or missing if not all items are found.
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
                if itemData and (itemData.name == item) then count += (itemData.count or itemData.amount or 1) end
            end
            foundInv = foundInv:gsub("%-", "^7-^6"):gsub("%_", "^7_^6")
            local foundMessage = "^6Bridge^7: ^3hasItem^7[^6"..foundInv.."^7]: "..tostring(item).." ^3"..count.."^7/^3"..amt
            if count >= amt then foundMessage = foundMessage.." ^5FOUND^7" else foundMessage = foundMessage .." ^1NOT FOUND^7" end
            debugPrint(foundMessage)
            hasTable[item] = { hasItem = count >= amt, count = count }
        end
        for k, v in pairs(hasTable) do if not v.hasItem then return false, hasTable end end
        return true, hasTable
    end
end

--- Retrieves a player's inventory from the active inventory system.
---
--- This function fetches the player's inventory based on the active inventory system.
--- It supports multiple systems including OXInv, QSInv, OrigenInv, CoreInv, CodeMInv, QBInv, and PSInv.
---
---@param src number|nil The source ID of the player. If `nil`, it fetches the current player's inventory.
---@return table|nil The inventory items of the player.
---@return string|nil The name of the inventory system being used.
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
        if src then grabInv = exports[OXInv]:GetInventoryItems(src)
        else grabInv = exports[OXInv]:GetPlayerItems() end

    elseif isStarted(QSInv) then
        foundInv = QSInv
        if src then grabInv = exports[QSInv]:GetInventory(src)
        else grabInv = exports[QSInv]:getUserInventory() end

    elseif isStarted(OrigenInv) then
        foundInv = OrigenInv
        if src then grabInv = exports[OrigenInv]:GetInventory(src)
        else grabInv = exports[OrigenInv]:getPlayerInventory() end

    elseif isStarted(CoreInv) then
        foundInv = CoreInv
        if src then
            if isStarted(QBExport) or isStarted(QBXExport) then
                grabInv = Core.Functions.GetPlayer(src).PlayerData.items
            elseif isStarted(ESXExport) then
                local Player = ESX.GetPlayerFromId(src)
                grabInv = Player.getInventory(false)
            end
        else
            local p = promise.new()
            Core.Functions.TriggerCallback('core_inventory:server:getInventory', function(cb) p:resolve(cb) end)
            local result = Citizen.Await(p)
            if type(result) == "string" then result = json.decode(result) end
            grabInv = result
        end

    elseif isStarted(CodeMInv) then
        foundInv = CodeMInv
        if src then grabInv = exports[CodeMInv]:GetInventory(src)
        else grabInv = exports[CodeMInv]:GetClientPlayerInventory() end

    elseif isStarted(QBInv) then
        foundInv = QBInv
        if src then grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else grabInv = Core.Functions.GetPlayerData().items end

    elseif isStarted(PSInv) then
        foundInv = PSInv
        if src then grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else grabInv = Core.Functions.GetPlayerData().items end

    else
        print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
    return grabInv, foundInv
end

--- Generates a random reward from a predefined reward pool.
---
--- This function is intended for job scripts where players receive random rewards upon completing certain tasks.
--- It ensures that the player has the required item before attempting to grant a reward.
---
---@param itemName string The name of the item to check for eligibility to receive a reward.
---
---@usage
--- ```lua
--- getRandomReward("gold_ring")
--- ```
function getRandomReward(itemName) -- Intended for job scripts
    if Config.Rewards.RewardPool then
        local reward = false
        if type(Config.Rewards.RewardItem) == "string" then Config.Rewards.RewardItem = { Config.Rewards.RewardItem } end
        for k, v in pairs(Config.Rewards.RewardItem) do
            if v == itemName then reward = true break end
        end
        if reward then
            removeItem(itemName, 1)
            local totalRarity = 0
            for i=1, #Config.Rewards.RewardPool do
                totalRarity += Config.Rewards.RewardPool[i].rarity
            end
            debugPrint("^6Bridge^7: ^3getRandomReward^7: ^2Total Rarity ^7'^6"..totalRarity.."^7'")

            local randomNum = math.random(1, totalRarity)
            debugPrint("^6Bridge^7: ^3getRandomReward^7: ^2Random Number ^7'^6"..randomNum.."^7'")
            local currentRarity = 0
            for i=1, #Config.Rewards.RewardPool do
                currentRarity += Config.Rewards.RewardPool[i].rarity
                if randomNum <= currentRarity then
                    debugPrint("^6Bridge^7: ^3getRandomReward^7: ^2Selected toy ^7'^6"..Config.Rewards.RewardPool[i].item.."^7'")
                    addItem(Config.Rewards.RewardPool[i].item, 1)
                    return
                end
            end
        end
    end
end

--- Checks if a player can carry specific items in their inventory.
---
--- This function determines whether a player has enough capacity to carry the specified items.
--- It considers the weight of each item and the player's current inventory weight.
---
---@param itemTable table A table where keys are item names and values are the quantities to check.
---@param src number The source ID of the player.
---@return table A table where keys are item names and values are booleans indicating if the player can carry the specified quantity.
---
---@usage
--- ```lua
--- local canCarry = canCarry({ ["health_potion"] = 2, ["mana_potion"] = 3 }, playerId)
--- if canCarry["health_potion"] and canCarry["mana_potion"] then
---     -- Proceed with adding items
--- else
---     -- Inform the player they can't carry all items
--- end
--- ```
function canCarry(itemTable, src)
    local resultTable = {}
    if src then
        if isStarted(OXInv) then
            for k, v in pairs(itemTable) do
                resultTable[k] = exports[OXInv]:CanCarryItem(src, k, v)
            end

        elseif isStarted(QSInv) then
            for k, v in pairs(itemTable) do
                resultTable[k] = exports[OXInv]:CanCarryItem(src, k, v)
            end

        elseif isStarted(CoreInv) then
            --??

        elseif isStarted(CodeMInv) then
            for k, v in pairs(itemTable) do
                local weight = Items[k].weight
                resultTable[k] = exports[CodeMInv]:CanCarryItem(src, weight, v)
            end

        elseif isStarted(OrigenInv) then
            for k, v in pairs(itemTable) do
                resultTable[k] = exports[OrigenInv]:canCarryItem(src, k, v)
            end

        elseif isStarted(QBInv) or isStarted(PSInv) then
            local Player = Core.Functions.GetPlayer(src)
            local items = Player.PlayerData.items
            local weight, totalWeight = 0, 0
            if not items then return false end
            for _, item in pairs(items) do weight += item.weight * item.amount end

            totalWeight = tonumber(weight)

            for k, v in pairs(itemTable) do
                local itemInfo = Items[k]
                if not itemInfo and not Player.Offline then
                    triggerNotify(nil, 'Item does not exist', 'error', src)
                    resultTable[k] = true
                else
                    resultTable[k] = (totalWeight + (Items[k]['weight'] * v)) <= InventoryWeight
                end
            end
        end
    end
    return resultTable
end