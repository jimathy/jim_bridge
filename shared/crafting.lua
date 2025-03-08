--[[
    Crafting, Selling, and Shop Module
    -----------------------------------
    This module provides functions for opening crafting menus, handling multi-crafting,
    performing the crafting process (with animations and progress bars), selling items,
    and opening shop interfaces. It integrates with various inventory and menu systems,
    and uses server callbacks to check item carry capacity.
]]

-------------------------------------------------------------
-- Global Variables
-------------------------------------------------------------
CraftLock = false

-------------------------------------------------------------
-- Crafting Menu
-------------------------------------------------------------

--- Opens the crafting menu based on provided data.
--- Checks job restrictions, builds the recipe menu, and opens the menu.
---
--- @param data table Crafting menu configuration containing:
---     - craftable (`table`) Table with Header, Recipes, Anims, and (optionally) craftedItems.
---     - coords (`vector3`) The coordinates where the crafting menu is being opened.
---     - stashTable|stashName (`string\table`) Name(s) of the stash for checking item availability.
---     - job|gang (`string`) Job or gang requirements.
---     - onBack (optional): Function to call when returning.
---
--- @usage
--- ```lua
---craftingMenu({
---     craftable = {
---         Header = "Weapon Crafting",
---         Recipes = {
---             [1] = {
---                 ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 },
---                 amount = 1,
---             },
---             -- More recipes...
---         },
---         Anims = {
---             animDict = "amb@prop_human_parking_meter@male@idle_a",
---             anim = "idle_a",
---         },
---     },
---     coords = vector3(100.0, 200.0, 300.0),
---stashTable = "crafting_stash",
---    job = "mechanic",
---    onBack = function() print("Returning to previous menu") end,
---})
function craftingMenu(data)
    if CraftLock then return end

    -- Job or gang check; exit if not authorized.
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end

    -- Display a temporary "thinking" notification.
    if Config.System.Menu == "jim" then
        triggerNotify(nil, "Thinking", "info")
    else
        openMenu({ { header = "Thinking...", icon = "fas fa-hourglass-end", isMenuHeader = true } }, { header = "Crafting Menu" } )
    end

    -- Normalize stash name.
    data.stashName = data.stashTable or data.stashName

    local Menu = {}
    local Recipes = data.craftable.Recipes
    local craftedItems = {}
    local tempCarryTable = {}

    -- Build a table of all required ingredients (default quantity is 1).
    for i = 1, #Recipes do
        for k in pairs(Recipes[i]) do
            if k == "hasCrafted" and not data.craftable.craftedItems then
                craftedItems = GetMetadata(nil, "craftedItems") or {}
                data.craftable.craftedItems = craftedItems
            end
            if k ~= "amount" and k ~= "metadata" and k ~= "job" and k ~= "gang" then
                tempCarryTable[k] = Recipes[i].amount or 1
            end
        end
    end

    -- Check if the player can carry the required items (server callback).
    local canCarryTable = triggerCallback(getScript()..':server:canCarry', tempCarryTable)
    -- Process each recipe to create menu entries.
    for i = 1, #Recipes do
        if not Recipes[i]["amount"] then Recipes[i]["amount"] = 1 end
        for k, _ in pairs(Recipes[i]) do
            local excludeKeys = {
                amount = true, metadata = true, description = true, info = true,
                job = true, gang = true, oneUse = true, slot = true,
                blueprintRef = true, craftingLevel = true, craftedItems = true,
                hasCrafted = true, exp = true, anim = true, time = true,
            }
            if not excludeKeys[k] then
                local hasjob = true
                if Recipes[i].job then
                    for l, b in pairs(Recipes[i].job) do
                        hasjob = hasJob(l, nil, b)
                        if hasjob then break end
                    end
                end
                if hasjob then
                    local setheader, settext, disable, metadata = "", "", false, (Recipes[i]["metadata"] or Recipes[i]["info"] or nil)
                    local itemTable = {}
                    local metaTable = {}
                    -- Build ingredient details.
                    for l, b in pairs(Recipes[i][tostring(k)]) do
                        settext = settext..(settext ~= "" and br or "")..(Items[l] and Items[l].label or "error - "..l)..(b > 1 and " x"..b or "")
                        metaTable[Items[l] and Items[l].label or "error - "..l] = b
                        itemTable[l] = b
                        Wait(0)
                    end

                    while not canCarryTable do Wait(0) end
                    disable = not checkHasItem(data.stashName, itemTable)
                    setheader = ((metadata and metadata.label) or (Items[tostring(k)] and Items[tostring(k)].label) or "error - "..tostring(k))
                               ..(Recipes[i]["amount"] > 1 and " x"..Recipes[i]["amount"] or "")

                    if not disable then
                        if not canCarryTable[k] then
                            setheader = setheader.." 📦"
                        else
                            setheader = setheader.." ✔️"
                        end
                    elseif not canCarryTable[k] then
                        setheader = setheader.." 📦"
                    end
                    if Recipes[i]["hasCrafted"] ~= nil and craftedItems[k] == nil then
                        setheader = "✨ "..setheader
                    end

                    Menu[#Menu + 1] = {
                        arrow = not disable and canCarryTable[k],
                        isMenuHeader = disable or not canCarryTable[k],
                        icon = invImg((metadata and metadata.image) or tostring(k)),
                        image = invImg((metadata and metadata.image) or tostring(k)),
                        header = setheader..((disable or not canCarryTable[k]) and " ❌" or ""),
                        txt = (isStarted(QBMenuExport) or disable) and settext or nil,
                        metadata = metaTable,
                        onSelect = (not disable and canCarryTable[k]) and function()
                            local transdata = {
                                item = k,
                                craft = data.craftable.Recipes[i],
                                craftable = data.craftable,
                                coords = data.coords,
                                stashName = data.stashName,
                                onBack = data.onBack,
                                metadata = metadata,
                            }
                            if Config.Crafting.MultiCraft then
                                multiCraft(transdata)
                            else
                                makeItem(transdata)
                            end
                        end or nil,
                    }
                end
            end
            Wait(0)
        end
    end

    openMenu(Menu, {
        header = data.craftable.Header,
        headertxt = data.craftable.Headertxt,
        onBack = data.onBack or nil,
        canClose = true,
        onExit = data.onExit or (function() end),
    })
    lookEnt(data.coords)
end

-------------------------------------------------------------
-- Multi-Craft Menu
-------------------------------------------------------------

--- Opens a menu for selecting the quantity to craft.
---
--- Presents the player with multiple crafting quantities based on Config.Crafting.MultiCraftAmounts.
---
--- @param data table Crafting configuration containing:
---     - item `string`) The item to craft.
---     - craft (`table`) The crafting recipe.
---     - craftable (`table`)  Crafting options.
---     - coords (`vector3`) where crafting occurs.
---     - stashName (`string`) The stash name(s) for item availability.
---     - onBack (`function`) Callback when returning.
---     - metadata (`table`) (optional): Metadata for the crafted item.
---
--- @usage
--- ```lua
--- multiCraft({
---     item = "weapon_pistol",
---     craft = { ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 }, amount = 1 },
---     craftable = craftingOptions,
---     coords = vector3(100,200,300),
---     stashName = "crafting_stash",
---     onBack = function() craftingMenu(data) end,
---     metadata = { label = "Custom Pistol", image = "custom_pistol.png" },
--- })
--- ```
function multiCraft(data)
    local Menu = {}
    local amounts = Config.Crafting.MultiCraftAmounts
    local metadata = data.metadata or nil

    -- Header for the multi-craft menu.
    Menu[#Menu + 1] = {
        isMenuHeader = true,
        icon = invImg(metadata and metadata.image or data.item),
        header = metadata and metadata.label or Items[data.item].label,
    }

    for k in pairsByKeys(amounts) do
        local settext = ""
        local itemTable = {}
        for l, b in pairs(data.craft[data.item]) do
            itemTable[l] = (b * k)
            settext = settext..(settext ~= "" and br or "")..Items[l].label..(b * k > 1 and " x"..b * k or "")
            Wait(0)
        end
        local disable, stashname = checkHasItem(data.stashName, itemTable)
        Menu[#Menu + 1] = {
            isMenuHeader = not disable,
            arrow = disable,
            header = "Craft - x"..(k * data.craft.amount),
            txt = settext,
            onSelect = function()
                makeItem({
                    item = data.item,
                    craft = data.craft,
                    craftable = data.craftable,
                    amount = k,
                    coords = data.coords,
                    stashName = stashname,
                    stashTable = data.stashName,
                    onBack = data.onBack,
                    metadata = data.metadata,
                })
            end,
        }
    end

    openMenu(Menu, { header = data.craftable.Header, onBack = function() craftingMenu(data) end })
end

-------------------------------------------------------------
-- Crafting Process
-------------------------------------------------------------

--- Initiates the crafting process for a specified item.
---
--- Plays crafting animations, shows progress bars, removes ingredients, and triggers item creation.
---
--- @param data table Crafting configuration containing:
---     - item `string`) The item to craft.
---     - craft (`table`) The crafting recipe.
---     - craftable (`table`)  Crafting options.
---     - amount (`number`) (optional): Quantity to craft (default 1).
---     - coords (`vector3`) where crafting occurs.
---     - stashName (`string`) The stash name(s) for item availability.
---     - onBack (`function`) Callback when returning.
---     - metadata (`table`) (optional): Metadata for the crafted item.
---
--- @usage
--- ```lua
--- makeItem({
---     item = "weapon_pistol",
---     craft = { ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 }, amount = 1 },
---     craftable = craftingOptions,
---     amount = 2,
---     coords = vector3(100,200,300),
---     stashName = "crafting_stash",
---     onBack = function() craftingMenu(data) end,
---     metadata = { label = "Custom Pistol", image = "custom_pistol.png" },
--- })
--- ```
function makeItem(data)
    if CraftLock then return end
    CraftLock = true
    data.stashName = data.stashTable or data.stashName

    local bartime = (data.craftable.progressBar and data.craftable.progressBar.time) or 5000
    local bartext = (data.craftable.progressBar and data.craftable.progressBar.label)
                    or (Loc[Config.Lan].progressbar and Loc[Config.Lan].progressbar["progress_make"])
                    or "Making "
    local animDict = (data.craftable.Anims and data.craftable.Anims.animDict) or "amb@prop_human_parking_meter@male@idle_a"
    local anim = (data.craftable.Anims and data.craftable.Anims.anim) or "idle_a"
    local craftAmount = (data.amount and data.amount ~= 1) and data.amount or 1
    local metadata = data.metadata or nil
    local prop = data.craftable.Anims and data.craftable.Anims.prop or nil
    local canReturn = true

    local crafted, crafting = true, true
    local cam = createTempCam(PlayerPedId(), data.coords)
    startTempCam(cam)

    for i = 1, craftAmount do
        for k, v in pairs(data.craft) do
            local excludeKeys = {
                amount = true, info = true, metadata = true, description = true,
                job = true, gang = true, oneUse = true, slot = true,
                blueprintRef = true, craftingLevel = true, craftedItems = true,
                hasCrafted = true, exp = true, anim = true, time = true,
            }
            if not excludeKeys[k] then
                if type(v) == "table" then
                    for l, b in pairs(v) do
                        if crafting and progressBar({
                            label = "Using "..b.." "..Items[l].label,
                            time = 1000,
                            cancel = true,
                            dict = 'pickup_object',
                            anim = "putdown_low",
                            flag = 48,
                            icon = l,
                        }) then
                            TriggerEvent((isStarted(QBInv) and QBInvNew and "qb-" or "")..'inventory:client:ItemBox', Items[l], "use", b)
                        else
                            crafted, crafting = false, false
                            break
                        end
                        Wait(200)
                    end
                    if crafted then
                        local craftProp = nil
                        if prop then
                            craftProp = makeProp({ prop = prop.model, coords = vec4(0, 0, 0, 0), true, true })
                            AttachEntityToEntity(craftProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), prop.bone), prop.pos.x, prop.pos.y, prop.pos.z, prop.rot.x, prop.rot.y, prop.rot.z, true, true, false, true, 1, true)
                        end
                        if crafting and progressBar({
                            label = bartext..((metadata and metadata.label) or Items[data.item].label),
                            time = bartime,
                            cancel = true,
                            dict = animDict,
                            anim = anim,
                            flag = 49,
                            icon = data.item,
                        }) then
                            TriggerServerEvent(getScript()..":Crafting:GetItem", data.item, data.craft, data.stashName, metadata)
                            CreateThread(function()
                                if data.craft["hasCrafted"] ~= nil then
                                    debugPrint("hasCrafted Found, marking '"..data.item.."' as crafted for player")
                                    data.craftable.craftedItems[data.item] = true
                                    triggerCallback(getScript()..":server:SetMetadata", "craftedItems", data.craftable.craftedItems)
                                end
                                Wait(100)
                                if data.craft["exp"] ~= nil then
                                    craftingLevel += data.craft["exp"].give
                                    jsonPrint(data.craft["exp"])
                                    debugPrint("exp found, giving exp for '"..data.item.."'")
                                    triggerCallback(getScript()..":server:SetMetadata", "craftingLevel", craftingLevel)
                                end
                            end)
                            if data.craftable.Recipes[1].oneUse == true then
                                removeItem("craftrecipe", 1, nil, data.craftable.Recipes[1].slot)
                                local breakId = GetSoundId()
                                PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
                                canReturn = false
                            end
                        else
                            crafting = false
                            break
                        end
                        if craftProp then destroyProp(craftProp) end
                    end
                end
            end
        end
        Wait(500)
    end
    stopTempCam()
    CraftLock = false
    lockInv(false)
    if canReturn then craftingMenu(data) end
    ClearPedTasks(PlayerPedId())
end

-------------------------------------------------------------
-- Server Event Handler: Crafted Item
-------------------------------------------------------------

--- Server event handler for giving the crafted item to the player.
---
--- Removes required ingredients from the player's inventory or stash,
--- then adds the crafted item to their inventory.
---
--- @param ItemMake string The item being crafted.
--- @param craftable table The crafting recipe and details.
--- @param stashName string|table The stash name(s) to remove ingredients from.
--- @param metadata table (optional) Metadata for the crafted item.
RegisterNetEvent(getScript()..":Crafting:GetItem", function(ItemMake, craftable, stashName, metadata)
    local src = source
    local hasItems, hasTable = hasItem(ItemMake, 1, src)
    if stashName then
        local itemRemove = {}
        if type(stashName) == "table" then
            for _, name in pairs(stashName) do
                stashItems = getStash(name)
                for k, v in pairs(craftable[ItemMake] or {}) do
                    for _, b in pairs(stashItems or {}) do
                        if k == b.name then itemRemove[k] = v end
                    end
                end
            end
        else
            stashItems = getStash(stashName)
            for k, v in pairs(craftable[ItemMake] or {}) do
                for _, b in pairs(stashItems or {}) do
                    if k == b.name then itemRemove[k] = v end
                end
            end
        end
        stashRemoveItem(stashItems, stashName, itemRemove)
    else
        if craftable then
            for k, v in pairs(craftable[ItemMake] or {}) do
                removeItem(tostring(k), v, src)
            end
        end
    end
    addItem(ItemMake, craftable.amount or 1, metadata, src)
    -- Optionally, add experience here:
    -- if isStarted("core_skills") then exports["core_skills"]:AddExperience(src, 2) end
end)

-------------------------------------------------------------
-- Selling Menu and Animation
-------------------------------------------------------------

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
    local Menu = {}
    if data.sellTable.Items then
        local itemList = {}
        for k, v in pairs(data.sellTable.Items) do itemList[k] = 1 end
        local _, hasTable = hasItem(itemList)
        for k, v in pairsByKeys(data.sellTable.Items) do
            Menu[#Menu + 1] = {
                isMenuHeader = not hasTable[k].hasItem,
                icon = invImg(k),
                header = Items[k].label..(hasTable[k].hasItem and "💰 (x"..hasTable[k].count..")" or ""),
                txt = Loc[Config.Lan].info["sell_all"]..v.." "..Loc[Config.Lan].info["sell_each"],
                onSelect = function()
                    sellAnim({ item = k, price = v, ped = data.ped, onBack = function() sellMenu(data) end })
                end,
            }
        end
    else
        for k, v in pairsByKeys(data.sellTable) do
            if type(v) == "table" then
                Menu[#Menu + 1] = {
                    arrow = true,
                    header = k,
                    txt = "Amount of items: "..countTable(v.Items),
                    onSelect = function()
                        v.onBack = function() sellMenu(origData) end
                        v.sellTable = data.sellTable[k]
                        sellMenu(v)
                    end,
                }
            end
        end
    end
    openMenu(Menu, {
        header = data.sellTable.Header or "Amount of items: "..countTable(data.sellTable.Items),
        headertxt = data.sellTable.Header and "Amount of items: "..countTable(data.sellTable.Items) or "",
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
function sellAnim(data)
    if not hasItem(data.item, 1) then
        triggerNotify(nil, Loc[Config.Lan].error["dont_have"].." "..Items[data.item].label, "error")
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

    TriggerServerEvent(getScript().."Sellitems", data)
    lookEnt(data.ped)
    local dict = "mp_common"
    playAnim(dict, "givetake2_a", 0.3, 2)
    playAnim(dict, "givetake2_b", 0.3, 2, data.ped)
    Wait(2000)
    StopAnimTask(PlayerPedId(), dict, "givetake2_a", 0.5)
    StopAnimTask(data.ped, dict, "givetake2_b", 0.5)
    if data.onBack then data.onBack() end
end

--- Server event handler for processing item sales.
--- Removes sold items from inventory and funds the player based on the sale.
RegisterNetEvent(getScript().."Sellitems", function(data)
    local src = source
    local hasItems, hasTable = hasItem(data.item, 1, src)
    if hasItems then
        removeItem(data.item, hasTable[data.item].count, src)
        TriggerEvent(getScript()..":server:FundPlayer", (hasTable[data.item].count * data.price), "cash", src)
    else
        triggerNotify(nil, Loc[Config.Lan].error["dont_have"].." "..Items[data.item].label, "error", src)
    end
end)

-------------------------------------------------------------
-- Shop Interface
-------------------------------------------------------------

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

    if isStarted(OXInv) then
        exports[OXInv]:openInventory('shop', { type = data.shop })

    elseif isStarted(QBInv) then
        if QBInvNew then
            TriggerServerEvent(getScript()..':server:OpenShopNewQB', data.shop)
        else
            TriggerServerEvent(Config.General.JimShops and "jim-shops:ShopOpen" or "inventory:server:OpenInventory", "shop", data.items.label, data.items)
        end

    --elseif isStarted(OrigenInv) then -- Needs testing, not sure if i did this right
    --    exports[OrigenInv]:openInventory('shop', data.shop, data.items)

    else
        TriggerServerEvent(Config.General.JimShops and "jim-shops:ShopOpen" or "inventory:server:OpenInventory", "shop", data.items.label, data.items)
    end
    lookEnt(data.coords)
end

--- Server event handler for opening a shop using the new QB inventory system.
RegisterNetEvent(getScript()..':server:OpenShopNewQB', function(data)
    exports[QBInv]:OpenShop(source, data)
end)

-------------------------------------------------------------
-- Server Callback Registration
-------------------------------------------------------------
if isServer() then
    createCallback(getScript()..':server:canCarry', function(source, itemTable) local result = canCarry(itemTable, source) return result end)
end