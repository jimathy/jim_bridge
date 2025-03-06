local CraftLock = false

--- Opens a crafting menu based on the provided data.
---
--- This function checks job requirements, prepares the menu options, and opens the crafting menu.
--- It handles item availability, crafting recipes, and displays appropriate icons and labels.
---
---@param data table A table containing crafting menu data.
--- - **craftable** (`table`): The crafting options and settings.
---   - **Header** (`string`): The header/title of the crafting menu.
---   - **Recipes** (`table`): A list of crafting recipes.
--- - **coords** (`vector3`): The coordinates where the crafting menu is being opened.
--- - **stashTable** (`string` or `table`, optional): The stash name(s) to check for item availability.
--- - **stashName** (`string` or `table`, optional): Alias for `stashTable`.
--- - **job** (`string` or `table`, optional): Job(s) required to access the crafting menu.
--- - **gang** (`string` or `table`, optional): Gang(s) required to access the crafting menu.
--- - **onBack** (`function`, optional): Function to call when returning from the menu.
---
---@usage
--- ```lua
--- craftingMenu({
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
---     stashTable = "crafting_stash",
---     job = "mechanic", -- Optional
---     onBack = function() print("Returning to previous menu") end,
--- })
--- ```
function craftingMenu(data)
    -- Prevent opening the menu if crafting is locked.
    if CraftLock then return end

    -- If a job or gang restriction exists and the player doesn't pass the job check, exit early.
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end

    -- Display a temporary "thinking" notification/menu depending on the configured system.
    if Config.System.Menu == "jim" then
        triggerNotify(nil, "Thinking", "info")
    else
        openMenu({ { header = "Thinking...", icon = "fas fa-hourglass-end", isMenuHeader = true } }, { header = "Crafting Menu" } )
    end

    -- Normalize stash name: if stashTable is provided, assign it to stashName.
    if data.stashTable then data.stashName = data.stashTable end

    -- Initialize an empty menu table and a flag for job verification.
    local Menu, hasjob = {}, false
    -- Get the list of recipes from the provided data.
    local Recipes = data.craftable.Recipes
    local craftingLevel = data.craftable.craftingLevel
    local craftedItems = data.craftable.craftedItems

    -- Create a temporary table to collect required item amounts for each recipe.
    local tempCarryTable = {}
    for i = 1, #Recipes do
        -- Iterate over each key in the current recipe.
        for k in pairs(Recipes[i]) do
            -- Ignore meta keys: "amount", "metadata", "job", and "gang".
            if k ~= "amount" and k ~= "metadata" and k ~= "job" and k ~= "gang" then
                -- Record the required amount for this ingredient (default to 1 if not specified).
                tempCarryTable[k] = Recipes[i].amount or 1
            end
        end
    end

    -- Trigger a server callback to check if the player can carry the required items.
    local canCarryTable = triggerCallback(getScript()..':server:canCarry', tempCarryTable)

    -- Process each recipe to build the menu entries.
    for i = 1, #Recipes do
        -- Ensure the recipe has an "amount" field; default to 1 if missing.
        if not Recipes[i]["amount"] then Recipes[i]["amount"] = 1 end

        -- Loop through each key-value pair in the recipe.
        for k, v in pairs(Recipes[i]) do
            -- Skip meta keys that are not ingredients.
            local excludeKeys = {
                amount = true,
                metadata = true,
                description = true,
                info = true,
                job = true,
                gang = true,
                oneUse = true,
                slot = true,
                blueprintRef = true,
                craftingLevel = true,
                craftedItems = true,
                hasCrafted = true,
            }

            if not excludeKeys[k] then

                -- Check job requirements if specified for the recipe.
                if Recipes[i].job then
                    for l, b in pairs(Recipes[i].job) do
                        -- hasJob returns true if the player meets the job criteria.
                        hasjob = hasJob(l, nil, b)
                        if hasjob == true then break end
                    end
                else
                    hasjob = true
                end

                -- Initialize variables for menu display text, disable flag, and any metadata.
                local setheader, settext, disable, metadata = "", "", false, (Recipes[i]["metadata"] or Recipes[i]["info"] or nil)

                if hasjob then
                    -- Build tables for ingredient details.
                    local itemTable = {}
                    local metaTable = {}

                    -- Iterate over the ingredients for the current key.
                    for l, b in pairs(Recipes[i][tostring(k)]) do
                        -- Append item label and quantity to the settext string.
                        -- Use a line break (br) if settext is not empty.
                        settext = settext..(settext ~= "" and br or "")..(Items[l] and Items[l].label or "error - "..l)..(b > 1 and " x"..b or "")
                        -- Populate the metaTable with item labels and their amounts.
                        metaTable[Items[l] and Items[l].label or "error - "..l] = b
                        -- Build a simple table of items required.
                        itemTable[l] = b
                        Wait(0)  -- Yield to avoid freezing the game.
                    end

                    -- Wait until the server callback (canCarryTable) has returned.
                    while not canCarryTable do Wait(0) end

                    -- Determine if the recipe should be disabled by checking if the player has the required items.
                    disable = not checkHasItem(data.stashName, itemTable)

                    -- Construct the header text for this menu item using metadata or default item label.
                    setheader = ((metadata and metadata.label) or (Items[tostring(k)] and Items[tostring(k)].label) or "error - " .. tostring(k))
                                .. (Recipes[i]["amount"] > 1 and " x" .. Recipes[i]["amount"] or "")

                    -- Append an emoji to indicate carry status:
                    -- If not disabled and the player cannot carry the item, append 📦,
                    -- otherwise append ✔️ if they can carry it.
                    -- if jim-crafting and its a blueprint item that has/hasnt been crafting prefix with ✨ to represent its a new item
                    if not disable then
                        if not canCarryTable[k] then
                            setheader = setheader .. " 📦"
                        else
                            setheader = setheader .. " ✔️"
                        end
                    elseif not canCarryTable[k] then
                        setheader = setheader .. " 📦"
                    end
                    if Recipes[i]["hasCrafted"] ~= nil then
                        if craftedItems[k] == nil then
                            setheader = "✨ "..setheader
                        end
                    end
                    -- Add the constructed menu item into the Menu table.
                    Menu[#Menu + 1] = {
                        -- Show an arrow if the item is enabled and can be carried.
                        arrow = not disable and canCarryTable[k],
                        -- Disable the menu item based on the state of QBMenuExport and carry-check.
                        isMenuHeader = disable or not canCarryTable[k],
                        -- Set icon and image for the menu item (using metadata image if available).
                        icon = invImg((metadata and metadata.image) or tostring(k)),
                        image = invImg((metadata and metadata.image) or tostring(k)),
                        -- Final header text, appending ❌ if disabled or cannot be carried.
                        header = setheader..((disable or not canCarryTable[k]) and " ❌" or ""),
                        -- Set description text if QBMenuExport is started.
                        txt = (isStarted(QBMenuExport) or disable) and settext or nil,
                        -- Attach the metadata table containing ingredient details.
                        metadata = metaTable,
                        -- Define the onSelect function to trigger crafting actions if the item is selectable.
                        onSelect = ((not disable and canCarryTable[k]) and (function()
                            -- Build transaction data with details needed for crafting.
                            local transdata = {
                                item = k,
                                craft = data.craftable.Recipes[i],
                                craftable = data.craftable,
                                coords = data.coords,
                                stashName = data.stashName,
                                onBack = data.onBack,
                                metadata = metadata
                            }
                            -- Call multiCraft or makeItem based on configuration.
                            if Config.Crafting.MultiCraft then
                                multiCraft(transdata)
                            else
                                makeItem(transdata)
                            end
                        end) or nil),
                    }
                end
            end
            Wait(0)  -- Yield within the loop to maintain responsiveness.
        end
    end

    -- Open the final crafting menu with the built Menu table and provided header/onBack configuration.
    openMenu(Menu, {
        header = data.craftable.Header,
        headertxt = data.craftable.Headertxt,
        onBack = data.onBack or nil,
        canClose = true,
        onExit = function() end,
    })

    -- Trigger an action (likely camera or player focus) to look at the specified coordinates.
    lookEnt(data.coords)
end


--- Opens a menu for selecting the quantity to craft.
---
--- This function presents the player with options to craft multiple quantities of an item, based on `Config.Crafting.MultiCraftAmounts`.
---
---@param data table A table containing crafting data.
--- - **item** (`string`): The item to craft.
--- - **craft** (`table`): The crafting recipe for the item.
--- - **craftable** (`table`): The crafting options and settings.
--- - **coords** (`vector3`): The coordinates where the crafting is taking place.
--- - **stashName** (`string` or `table`, optional): The stash name(s) to check for item availability.
--- - **onBack** (`function`, optional): Function to call when returning from the menu.
--- - **metadata** (`table`, optional): Metadata for the crafted item.
---
---@usage
--- ```lua
--- multiCraft({
---     item = "weapon_pistol",
---     craft = { ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 }, amount = 1 },
---     craftable = craftingOptions,
---     coords = vector3(100.0, 200.0, 300.0),
---     stashName = "crafting_stash",
---     onBack = function() craftingMenu(data) end,
---     metadata = { label = "Custom Pistol", image = "custom_pistol.png" },
--- })
--- ```
function multiCraft(data)
    local Menu = {}
    local success = Config.Crafting.MultiCraftAmounts
    local metadata = data.metadata or nil
    Menu[#Menu+1] = {
        isMenuHeader = true,
        icon = invImg(metadata and metadata.image or data.item),
        header = metadata and metadata.label or Items[data.item].label,
    }
    for k in pairsByKeys(success) do
        local settext = ""
        local itemTable = {}
        for l, b in pairs(data.craft[data.item]) do
            itemTable[l] = (b * k)
            settext = settext..(settext ~= "" and br or "")..Items[l].label..(b*k > 1 and "- x"..b*k or "")
            Wait(0)
        end
        local disable, stashname = checkHasItem(data.stashName, itemTable)
        Menu[#Menu + 1] = {
            isMenuHeader = not disable,
            arrow = disable,
            header = "Craft - x"..k * data.craft.amount,
            txt = settext,
            onSelect = function ()
                makeItem({
                    item = data.item,
                    craft = data.craft,
                    craftable = data.craftable,
                    amount = k,
                    coords = data.coords,
                    stashName = stashname,
                    stashTable = data.stashName,
                    onBack = data.onBack,
                    metadata = data.metadata
                })
            end,
        }
    end
    openMenu(Menu, { header = data.craftable.Header, onBack = function() craftingMenu(data) end, })
end

--- Initiates the crafting process for a specified item.
---
--- This function handles the crafting animation, progress bar, item removal, and item creation.
---
---@param data table A table containing crafting data.
--- - **item** (`string`): The item to craft.
--- - **craft** (`table`): The crafting recipe for the item.
--- - **craftable** (`table`): The crafting options and settings.
--- - **amount** (`number`, optional): The quantity to craft. Default is `1`.
--- - **coords** (`vector3`): The coordinates where the crafting is taking place.
--- - **stashName** (`string` or `table`, optional): The stash name(s) to remove items from.
--- - **stashTable** (`string` or `table`, optional): Alias for `stashName`.
--- - **onBack** (`function`, optional): Function to call when returning from the menu.
--- - **metadata** (`table`, optional): Metadata for the crafted item.
---
---@usage
--- ```lua
--- makeItem({
---     item = "weapon_pistol",
---     craft = { ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 }, amount = 1 },
---     craftable = craftingOptions,
---     amount = 2,
---     coords = vector3(100.0, 200.0, 300.0),
---     stashName = "crafting_stash",
---     onBack = function() craftingMenu(data) end,
---     metadata = { label = "Custom Pistol", image = "custom_pistol.png" },
--- })
--- ```
function makeItem(data)
    if CraftLock then return end
    CraftLock = true
    if data.stashTable then data.stashName = data.stashTable end
    local bartime = data.craftable.progressBar and data.craftable.progressBar.time or 5000
    local bartext = (data.craftable.progressBar and data.craftable.progressBar.label) or (Loc[Config.Lan].progressbar and Loc[Config.Lan].progressbar["progress_make"]) or "Making "
    local animDict = data.craftable.Anims and data.craftable.Anims.animDict or "amb@prop_human_parking_meter@male@idle_a"
    local anim = data.craftable.Anims and data.craftable.Anims.anim or "idle_a"
    local amount = data.amount and (data.amount ~= 1) and data.amount or 1
    local metadata = data.metadata or nil
    local prop = data.craftable.Anims and data.craftable.Anims.prop or nil

    local canReturn = true

    local crafted, crafting = true, true
    local cam = createTempCam(PlayerPedId(), data.coords)
    startTempCam(cam)

    for i = 1, amount do
        countTable(data.craft)
        for k, v in pairs(data.craft) do
            local excludeKeys = {
                amount = true,
                info = true,
                metadata = true,
                description = true,
                job = true,
                gang = true,
                oneUse = true,
                slot = true,
                blueprintRef = true,
                craftingLevel = true,
                craftedItems = true,
                hasCrafted = true,
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
                            TriggerEvent((isStarted(QBInv) and QBInvNew and "qb-" or "").."inventory:client:ItemBox", Items[l], "use", b) -- Show item box for each item
                        else
                            crafted, crafting = false, false
                            break
                        end
                        Wait(200)
                    end
                    if crafted then
                        local craftProp = nil
                        if prop then
                            local model, pos, rot, bone = prop.model, prop.pos, prop.rot, prop.bone
                            craftProp = makeProp({ prop = model, coords = vec4(0, 0, 0, 0), true, true })
                            AttachEntityToEntity(craftProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), bone), pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
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
                            if data.craft["hasCrafted"] ~= nil then
                                debugPrint("hasCrafted Found, marking '"..data.item.."' as crafted for player")

                                data.craftable.craftedItems[data.item] = true
                                triggerCallback(getScript()..":server:SetMetadata", "craftedItems", data.craftable.craftedItems )
                                --SetMetadata(nil, "craftedItems", data.craftable.craftedItems)
                            end
                            if data.craftable.Recipes[1].oneUse == true then
                                removeItem("craftrecipe", 1, nil, data.craftable.Recipes[1].slot)
                                local breakId = GetSoundId()
                                PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
                                canReturn = false
                                -- If recipe is removed it doesn't try to open menu again, it was causing blank menus for some reason
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

--- Server event handler for giving the crafted item to the player.
---
--- This event is triggered when the crafting process is completed successfully.
---
--- @param ItemMake string The item being crafted.
--- @param craftable table The crafting recipe and details.
--- @param stashName string|table The stash name(s) to remove items from.
--- @param metadata table (optional) Metadata for the crafted item.
RegisterNetEvent(getScript()..":Crafting:GetItem", function(ItemMake, craftable, stashName, metadata)
    local src, amount, stashItems = source, craftable and craftable.amount or 1, nil
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
    addItem(ItemMake, amount, metadata, src)
    --if isStarted("core_skills") then exports["core_skills"]:AddExperience(src, 2) end
end)

--- Opens a selling menu based on the provided data.
---
--- This function checks available items to sell, prepares the menu options, and opens the selling menu.
---
---@param data table A table containing selling menu data.
--- - **sellTable** (`table`): The selling options and settings.
---   - **Items** (`table`): A list of items that can be sold with their prices.
---   - **Header** (`string`, optional): The header/title of the selling menu.
--- - **ped** (`number`, optional): The ped entity involved in the selling interaction.
--- - **onBack** (`function`, optional): Function to call when returning from the menu.
---
---@usage
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
            Menu[#Menu +1] = {
                isMenuHeader = not hasTable[k].hasItem,
                icon = invImg(k),
                header = Items[k].label.. (hasTable[k].hasItem and "💰 (x"..hasTable[k].count..")" or ""),
                txt = Loc[Config.Lan].info["sell_all"]..v.." "..Loc[Config.Lan].info["sell_each"],
                onSelect = function()
                    sellAnim({ item = k, price = v, ped = data.ped, onBack = function() sellMenu(data) end })
                end,
            }
        end
    else
        for k, v in pairsByKeys(data.sellTable) do
            if type(v) == "table" then
                Menu[#Menu +1] = {
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
    openMenu(Menu, { header = data.sellTable.Header or "Amount of items: "..countTable(data.sellTable.Items), headertxt = data.sellTable.Header and "Amount of items: "..countTable(data.sellTable.Items) or "", canClose = true, onBack = data.onBack })
end

--- Handles the selling animation and item transaction.
---
--- This function plays the selling animation, removes the item from the player's inventory, and gives the player money.
---
---@param data table A table containing selling data.
--- - **item** (`string`): The item to sell.
--- - **price** (`number`): The price per item.
--- - **ped** (`number`, optional): The ped entity involved in the selling interaction.
--- - **onBack** (`function`, optional): Function to call when returning from the menu.
---
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
    for k, v in pairs(GetGamePool('CObject')) do
        for _, model in pairs({`p_cs_clipboard`}) do
            if GetEntityModel(v) == model then
                if IsEntityAttachedToEntity(data.ped, v) then
                    DeleteObject(v) DetachEntity(v, 0, 0) SetEntityAsMissionEntity(v, true, true)
                    Wait(100) DeleteEntity(v)
                end
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

--- Server event handler for processing the item sale.
---
--- This event removes the sold item from the player's inventory and adds money to their account.
---
---@param data table The data containing item and price information.
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

--- Opens a shop interface for the player.
---
--- This function checks job requirements and opens the shop using the appropriate inventory system.
---
---@param data table A table containing shop data.
--- - **shop** (`string`): The shop identifier.
--- - **items** (`table`): The items available in the shop.
--- - **coords** (`vector3`): The coordinates where the shop interaction is happening.
--- - **job** (`string` or `table`, optional): Job(s) required to access the shop.
--- - **gang** (`string` or `table`, optional): Gang(s) required to access the shop.
---
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
            TriggerServerEvent(getScript()..':server:OpenShopNewQB', data.shop) -- i hate qb-inv
        else
            TriggerServerEvent(Config.General.JimShops and "jim-shops:ShopOpen" or "inventory:server:OpenInventory", "shop", data.items.label, data.items)
        end
    else
        TriggerServerEvent(Config.General.JimShops and "jim-shops:ShopOpen" or "inventory:server:OpenInventory", "shop", data.items.label, data.items)
    end
    lookEnt(data.coords)
end

--- Server event handler for opening a new QB inventory shop.
---
--- This event is triggered when using the new QB inventory system.
---
---@param data table The shop data to open.
RegisterNetEvent(getScript()..':server:OpenShopNewQB', function(data)
    exports[QBInv]:OpenShop(source, data)
end)

--- Server-side callback registration for checking if the player can carry items.
if isServer() then
    createCallback(getScript()..':server:canCarry', function(source, itemTable) local result = canCarry(itemTable, source) return result end)
end