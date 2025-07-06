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

-- helper filter table for crafting menus
local excludeKeys = {
    amount = true, metadata = true, description = true, info = true,
    job = true, gang = true, oneUse = true, slot = true,
    blueprintRef = true, craftingLevel = true, craftedItems = true,
    hasCrafted = true, exp = true, anim = true, time = true,
}

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
--- craftingMenu({
---      craftable = {
---          Header = "Weapon Crafting",
---          Recipes = {
---              [1] = {
---                  ["weapon_pistol"] = { ["steel"] = 5, ["plastic"] = 2 },
---                  amount = 1,
---              },
---              -- More recipes...
---          },
---          Anims = {
---              animDict = "amb@prop_human_parking_meter@male@idle_a",
---              anim = "idle_a",
---          },
---      },
---      coords = vector3(100.0, 200.0, 300.0),
---      stashTable = "crafting_stash",
---      job = "mechanic",
---      onBack = function() print("Returning to previous menu") end,
--- })
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
            if k ~= "amount" and k ~= "metadata" and k ~= "job" and k ~= "gang" then
                tempCarryTable[k] = Recipes[i].amount or 1
            end
        end
    end

    -- Check if the player can carry the required items (server callback).
    local canCarryTable = triggerCallback(getScript()..':server:canCarry', tempCarryTable)

    local usingStash = data.stashName ~= nil

    Menu[#Menu+1] = {
        icon = usingStash and "fas fa-boxes-stacked" or "fas fa-person",
        header = "Material Source: "..(usingStash and "Job Stash" or "Player Inventory"),
        disabled = true,
    }

    -- Process each recipe to create menu entries.
    for i = 1, #Recipes do
        if not Recipes[i]["amount"] then Recipes[i]["amount"] = 1 end
        for k, _ in pairs(Recipes[i]) do
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
                        local label = Items[l] and Items[l].label or "error - "..l
                        local hasItem = checkStashItem(data.stashName, { [l] = b })
                        local missingMark = not hasItem and " ❌" or " "
                        settext = settext..(settext ~= "" and br or "").."[ x"..b.." ] - "..label..missingMark

                        metaTable[Items[l] and Items[l].label or "error - "..l] = b
                        itemTable[l] = b
                    end

                    while not canCarryTable do Wait(0) end
                    disable = not checkStashItem(data.stashName, itemTable)
                    setheader = ((metadata and metadata.label) or (Items[tostring(k)] and Items[tostring(k)].label) or "error - "..tostring(k))
                               ..(Recipes[i]["amount"] > 1 and " x"..Recipes[i]["amount"] or "")

                    local statusEmoji = disable and " " or not canCarryTable[k] and " 📦" or " ✔️"
                    local isNew = (Recipes[i]["hasCrafted"] ~= nil and craftedItems[k] == nil) and "✨ " or ""
                    setheader = isNew .. setheader .. statusEmoji

                    Menu[#Menu + 1] = {
                        arrow = isOx() and (not disable and canCarryTable[k]),
                        isMenuHeader = disable or not canCarryTable[k],
                        icon = invImg((metadata and metadata.image) or tostring(k)),
                        image = invImg((metadata and metadata.image) or tostring(k)),
                        header = setheader,
                        txt = settext or nil,
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
            --Wait(0)
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
    local max = 0
    local stashName = nil
    local maxCreation = 100

    -- Generate item table to check against stash or inventory
    -- takes into account the ingredients needed for multiple items
    local multiItemTable = {}

    for i = 1, maxCreation do
        multiItemTable[i] = {}
        for l, b in pairs(data.craft[data.item]) do
            multiItemTable[i][l] = (b * i)
        end
    end

    for i = 1, maxCreation do
        -- if its received a stash name, check if the items are in the stash
        if data.stashName then
            local hasItems, stashname = checkStashItem(data.stashName, multiItemTable[i])
            if hasItems == true then
                max += 1
                stashName = stashname
            else
                break
            end
        else
            -- if not check the players inventory for the items
            local has, _ = hasItem(multiItemTable[i], nil, nil)
            if has then
                max += 1
            else
                break
            end
        end
    end

    local carryMax = triggerCallback(getScript()..":server:getMaxCarryCraft", {
        item = data.item,
        max = max
    })

    local dialog = createInput(data.craftable.Header..(Config.System.Menu == "qb" and ": "..br.."How many to craft? "..br.."Max: "..carryMax or ""), {
        ((Config.System.Menu == "ox" or Config.System.Menu == "lation") and {
            type = "slider",
            label = "How many to craft? "..br.."Max: "..carryMax,
            required = true,
            default = 1,
            min = 1,
            max = carryMax
        }) or nil,
        ((Config.System.Menu == "qb") and {
            type = "number",
            name = "amount",
            isRequired = true,
            default = 1,
        }) or nil,
    })

    if dialog then
        if Config.System.Menu == "ox" then

        end
        if Config.System.Menu == "qb" then
            dialog["amount"] = tonumber(dialog["amount"])
            if dialog["amount"] > carryMax or dialog["amount"] < 1 or dialog["amount"] == nil or dialog["amount"] == "" then
                triggerNotify(nil, "Invalid Amount", "error")
                craftingMenu(data)
                return
            end
        end

        makeItem({
            item = data.item,
            craft = data.craft,
            craftable = data.craftable,
            amount = dialog["amount"] or dialog[1],
            coords = data.coords,
            stashName = stashName or nil,
            onBack = data.onBack,
            metadata = data.metadata,
        })
    end
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

    -- Calculate total bartime if SingleProgress is enabled
    local totalBartime = bartime * craftAmount

    -- Run ingredient check and usage separately first
    for i = 1, craftAmount do
        for k, v in pairs(data.craft) do
            if not excludeKeys[k] and type(v) == "table" then
                for l, b in pairs(v) do
                    if isInventoryOpen() then
                        print("^1Error^7: ^2Inventory is open, you tried to break things")
                        stopTempCam()
                        ClearPedTasks(PlayerPedId())
                        if canReturn then craftingMenu(data) end
                        CraftLock = false
                        return
                    end
                    if crafting and progressBar({
                        label = "Using "..b.." "..Items[l].label,
                        time = 1000,
                        cancel = true,
                        dict = 'pickup_object',
                        anim = "putdown_low",
                        flag = 49,
                        icon = l,
                    }) then
                        TriggerEvent((isStarted(QBInv) and QBInvNew and "qb-" or "")..'inventory:client:ItemBox', Items[l], "use", b)
                    else
                        crafted, crafting = false, false
                        break
                    end
                    Wait(200)
                end
            end
        end
    end

    if not crafted then
        stopTempCam()
        ClearPedTasks(PlayerPedId())
        if canReturn then craftingMenu(data) end
        CraftLock = false
        return
    end

    -- Handle SingleProgress option
    if Config.Crafting.SingleProgress then
        local craftProp = nil
        if prop then
            craftProp = makeProp({ prop = prop.model, coords = vec4(0, 0, 0, 0), true, true })
            AttachEntityToEntity(craftProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), prop.bone), prop.pos.x, prop.pos.y, prop.pos.z, prop.rot.x, prop.rot.y, prop.rot.z, true, true, false, true, 1, true)
        end
        if data.sound then
            local s = data.sound
            PlaySoundFromEntity(s.soundId, s.audioName, PlayerPedId(), s.audioRef, true, 0)
        end
        if crafting and progressBar({
            label = bartext..((metadata and metadata.label) or Items[data.item].label).." x"..craftAmount,
            time = totalBartime,
            cancel = true,
            dict = animDict,
            anim = anim,
            flag = 49,
            icon = data.item,
            request = true,
        }) then
            data.craft.amount = craftAmount
            TriggerServerEvent(getScript()..":Crafting:GetItem", data.item, data.craft, data.stashName, metadata, currentToken)
            currentToken = nil -- clear client cached token
            -- handle metadata and experience in a single go
            if data.craft["hasCrafted"] ~= nil then
                data.craftable.craftedItems[data.item] = true
                triggerCallback(getScript()..":server:SetMetadata", "craftedItems", data.craftable.craftedItems)
            end
            if data.craft["exp"] ~= nil then
                craftingLevel += data.craft["exp"].give * craftAmount
                triggerCallback(getScript()..":server:SetMetadata", "craftingLevel", craftingLevel)
            end
            if data.craftable.Recipes[1].oneUse == true then
                removeItem("craftrecipe", 1, nil, data.craftable.Recipes[1].slot)
                local breakId = GetSoundId()
                PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
                canReturn = false
            end
            if data.sound then
                StopSound(data.sound.soundId)
            end
            if data.requiredItemfunc then
                data.requiredItemfunc()
            end
        end
        if craftProp then destroyProp(craftProp) end
    else
        -- Run the original loop for multiple progress bars
        for i = 1, craftAmount do
            if crafting and progressBar({
                label = bartext..((metadata and metadata.label) or Items[data.item].label),
                time = bartime,
                cancel = true,
                dict = animDict,
                anim = anim,
                flag = 49,
                icon = data.item,
                request = true,
            }) then
                TriggerServerEvent(getScript()..":Crafting:GetItem", data.item, data.craft, data.stashName, metadata, currentToken)
                currentToken = nil
                if data.craft["hasCrafted"] ~= nil then
                    data.craftable.craftedItems[data.item] = true
                    triggerCallback(getScript()..":server:SetMetadata", "craftedItems", data.craftable.craftedItems)
                end
                if data.craft["exp"] ~= nil then
                    craftingLevel += data.craft["exp"].give
                    triggerCallback(getScript()..":server:SetMetadata", "craftingLevel", craftingLevel)
                end
                if data.craftable.Recipes[1].oneUse == true then
                    removeItem("craftrecipe", 1, nil, data.craftable.Recipes[1].slot)
                    local breakId = GetSoundId()
                    PlaySoundFromEntity(breakId, "Drill_Pin_Break", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
                    canReturn = false
                end
                if data.requiredItemfunc then
                    data.requiredItemfunc()
                end
            else
                break
            end
        end
    end

    Wait(500)
    stopTempCam()
    CraftLock = false
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
--- @usage
RegisterNetEvent(getScript()..":Crafting:GetItem", function(ItemMake, craftable, stashName, metadata, token)
    local src = source
    -- debugPrint("^6Bridge^7: ^4"..getScript().."^7:^4Crafting^7:^4GetItem ^2invoked by^7: "..GetInvokingResource())
	if GetInvokingResource() and GetInvokingResource() ~= getScript() and GetInvokingResource() ~= "qb-core" then
        debugPrint("^1ERROR^7: ^1Possible exploit^7, ^1vital function was called from an external resource^7")
        return
    end

    if not checkToken(src, token, "item", ItemMake) then
        return
    end


    local hasItems, hasTable = hasItem(ItemMake, 1, src)
    if stashName then
        local itemRemove = {}
        if type(stashName) == "table" then
            for _, name in pairs(stashName) do
                stashItems = getStash(name)
                for k, v in pairs(craftable[ItemMake] or {}) do
                    for _, b in pairs(stashItems or {}) do
                        if k == b.name then
                            itemRemove[k] = v
                        end
                    end
                end
            end
        else
            stashItems = getStash(stashName)
            for k, v in pairs(craftable[ItemMake] or {}) do
                for _, b in pairs(stashItems or {}) do
                    if k == b.name then
                        itemRemove[k] = v
                    end
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
    -- for example:
    -- if isStarted("core_skills") then exports["core_skills"]:AddExperience(src, 2) end
end)