if not Config.System then Config.System = {} end
Config.System.Debug = false

if IsDuplicityVersion() then
    if GetResourceState(OXLibExport):find("start") then
        createCallback(GetCurrentResourceName()..':server:GetStashItems', function(source, stashName) local stash = getStash(stashName) return stash end)
    else
        createCallback(GetCurrentResourceName()..':server:GetStashItems', function(source, cb, stashName) local stash = getStash(stashName) cb(stash) end)
    end
end

local timeout, timing, stashItems = 0, false, {}
function GetStashTimeout(stashName, stop)
    if stop then stashItems, timing, timeout = {}, false, 0 return end
    
    -- Initialize stashItems as empty table if nil
    if not stashItems then stashItems = {} end
    
    if timeout <= 0 then
        -- Get stash items and ensure we have a valid table
        stashItems = triggerCallback(GetCurrentResourceName()..':server:GetStashItems', stashName) or {}
        
        timeout = 10000
        if not timing then
            CreateThread(function()
                timing = true
                while timeout > 0 do 
                    timeout = timeout - 1000 
                    Wait(1000) 
                end
                timing, stashItems, timeout = false, {}, 0
            end)
        end
        -- Return true only after we've actually fetched the stash data
        return true
    end
    -- Return false if we're still in timeout
    return false
end

local CraftLock = false
function craftingMenu(data)
    if CraftLock then return end
    local stashItems = {}
    if data.stashName then
        -- Get stash items directly
        stashItems = triggerCallback(GetCurrentResourceName()..':server:GetStashItems', data.stashName) or {}
        if Config.System.Debug then
            print("^6Bridge^7: ^3craftingMenu^7: Loaded stash items:", json.encode(stashItems))
        end
    end
    
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
    local Menu = {}
    local Recipes = data.craftable.Recipes
    
	for i = 1, #Recipes do
        if not Recipes[i]["amount"] then Recipes[i]["amount"] = 1 end
        for k, v in pairs(Recipes[i]) do
			if k ~= "amount" and k ~= "job" and k ~= "gang" then
                local settext = ""
                local itemTable = {}
                for l, b in pairs(Recipes[i][tostring(k)]) do
                    settext = settext..(settext ~= "" and " + " or "")..Items[l].label..(b > 1 and " x"..b or "")
                    itemTable[l] = b
                end
                
                local disable = false
                if Config.System.Debug then 
                    print("^6Bridge^7: ^2Checking"..(data.stashName and " ^7'^6"..data.stashName.."^7'" or "").." ^2ingredients^7 - ^6"..k.."^7")
                    print("^6Bridge^7: ^3craftingMenu^7: Checking recipe:", json.encode(itemTable))
                end
                
                if data.stashName then 
                    disable = not stashhasItem(stashItems, itemTable)
                    if Config.System.Debug then
                        print("^6Bridge^7: ^3craftingMenu^7: Recipe disabled:", disable)
                    end
                else 
                    disable = not hasItem(itemTable) 
                end
                
                Menu[#Menu + 1] = {
                    isMenuHeader = disable,
                    header = Items[k].label,
                    txt = "Requires: "..settext,
                    onSelect = not disable and function()
                        makeItem({
                            item = k, 
                            craft = Recipes[i], 
                            craftable = data.craftable, 
                            coords = data.coords, 
                            stashName = data.stashName, 
                            onBack = data.onBack
                        })
                    end or nil,
                }
            end
		end
	end
	openMenu(Menu, { header = data.craftable.Header, onBack = data.onBack or nil, canClose = true })
end

function makeItem(data)
	if CraftLock then return end
	CraftLock = true

    if Config.System.Debug then
        print("^6Bridge^7: ^3makeItem^7: Starting crafting for", data.item)
        print("^6Bridge^7: ^3makeItem^7: Using stash:", data.stashName or "none")
        print("^6Bridge^7: ^3makeItem^7: Craft data:", json.encode(data.craft))
    end

    -- Get fresh stash items
    local stashItems = data.stashName and triggerCallback(GetCurrentResourceName()..':server:GetStashItems', data.stashName) or {}
    
    -- Verify we have the required items
    if data.stashName then
        local hasItems = true
        for k, v in pairs(data.craft) do
            if k ~= "amount" and k ~= "job" and type(v) == "table" then
                if not stashhasItem(stashItems, v) then
                    hasItems = false
                    if Config.System.Debug then
                        print("^6Bridge^7: ^3makeItem^7: Missing required items:", json.encode(v))
                    end
                    break
                end
            end
        end
        if not hasItems then
            if Config.System.Debug then
                print("^6Bridge^7: ^3makeItem^7: Cancelling craft - missing required items")
            end
            CraftLock = false
            return
        end
    end

    -- Animation and progress bar settings
    local bartime = data.craftable.progressBar and data.craftable.progressBar.time or 5000
    local bartext = (data.craftable.progressBar and data.craftable.progressBar.label) or "Crafting"
    local animDict = data.craftable.Anims and data.craftable.Anims.animDict or "amb@prop_human_parking_meter@male@idle_a"
    local anim = data.craftable.Anims and data.craftable.Anims.anim or "idle_a"

    -- Load animation dictionary
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Wait(10) end
    end

    -- Start crafting animation
    TaskPlayAnim(PlayerPedId(), animDict, anim, 8.0, 8.0, -1, 1, 0, false, false, false)

    -- Show progress bar for each required item
    for k, v in pairs(data.craft) do
        if k ~= "amount" and k ~= "job" and type(v) == "table" then
            for item, amount in pairs(v) do
                if not progressBar({
                    label = "Using " .. amount .. " " .. (Items[item] and Items[item].label or item),
                    time = 1000,
                    cancel = true,
                    dict = 'pickup_object',
                    anim = "putdown_low",
                    flag = 48,
                    icon = item
                }) then
                    CraftLock = false
                    ClearPedTasks(PlayerPedId())
                    return
                end
                Wait(200)
            end
        end
    end

    -- Main crafting progress bar
    if progressBar({
        label = bartext .. " " .. (Items[data.item] and Items[data.item].label or data.item),
        time = bartime,
        cancel = true,
        dict = animDict,
        anim = anim,
        flag = 8,
        icon = data.item
    }) then
        -- Trigger the crafting event
        if Config.System.Debug then
            print("^6Bridge^7: ^3makeItem^7: Triggering craft event")
        end
        TriggerServerEvent(GetCurrentResourceName()..":Crafting:GetItem", data.item, data.craft, data.stashName)
    end
    
    -- Reset and show menu again
    Wait(500) -- Small delay to ensure server event processes
    ClearPedTasks(PlayerPedId())
    CraftLock = false
    craftingMenu(data)
end

RegisterNetEvent(GetCurrentResourceName()..":Crafting:GetItem", function(ItemMake, craftable, stashName)
    local src = source
    local amount = craftable and craftable.amount or 1
    
    if Config.System.Debug then
        print("^6Bridge^7: ^3Crafting:GetItem^7: Crafting", ItemMake, "amount:", amount)
        print("^6Bridge^7: ^3Crafting:GetItem^7: Using stash:", stashName or "none")
    end
    
    if stashName then
        -- Get current stash items
        local stashItems = getStash(stashName)
        if Config.System.Debug then
            print("^6Bridge^7: ^3Crafting:GetItem^7: Current stash items:", json.encode(stashItems))
        end
        
        -- Remove required items from stash
        local itemRemove = {}
        for k, v in pairs(craftable[ItemMake] or {}) do
            itemRemove[k] = v
            if Config.System.Debug then
                print("^6Bridge^7: ^3Crafting:GetItem^7: Will remove", v, "of", k)
            end
        end
        
        -- Remove items from stash
        stashRemoveItem(stashItems, stashName, itemRemove)
        
        -- Add crafted item to player inventory using codem-inventory
        if GetResourceState(CodeMInv):find("start") then
            if Config.System.Debug then
                print("^6Bridge^7: ^3Crafting:GetItem^7: Adding", amount, "of", ItemMake, "to player inventory")
            end
            exports[CodeMInv]:AddItem(src, ItemMake, amount)
        else
            -- Fallback to generic toggleItem
            TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, ItemMake, amount, src)
        end
    else
        -- Handle regular inventory crafting
        if craftable then
            for k, v in pairs(craftable[ItemMake] or {}) do
                TriggerEvent(GetCurrentResourceName()..":server:toggleItem", false, tostring(k), v, src)
            end
        end
        TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, ItemMake, amount, src)
    end
    
    -- Add experience if core_skills is available
    if GetResourceState("core_skills"):find("start") then 
        exports["core_skills"]:AddExperience(src, 2) 
    end
end)

--[[SHOPS]]--
function sellMenu(data)
    local origData = data
    local Menu = {}
	if data.sellTable.Items then
		local itemList = {}
		for k, v in pairs(data.sellTable.Items) do itemList[k] = 1 end
		local hasitems, hasTable = hasItem(itemList)
        for k, v in pairsByKeys(data.sellTable.Items) do
			Menu[#Menu +1] = {
                isMenuHeader = not hasTable[k].hasItem,
                icon = invImg(k),
				header = Items[k].label.. (hasTable[k].hasItem and "💰 (x"..hasTable[k].count..")" or ""),
				txt = Loc[Config.Lan].info["sell_all"].." "..v.." "..Loc[Config.Lan].info["sell_each"],
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
	openMenu(Menu, { header = data.sellTable.Header or "Amount of items: "..countTable(data.sellTable.Items), canClose = true, onBack = data.onBack })
end

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
	TriggerServerEvent(GetCurrentResourceName().."Sellitems", data) -- Had to slip in the sell command during the animation command
	lookEnt(data.ped)
    local dict = "mp_common"
    playAnim(dict, "givetake2_a", 0.3, 2)
	playAnim(dict, "givetake2_b", 0.3, 2, data.ped)
	Wait(2000)
    StopAnimTask(PlayerPedId(), dict, "givetake2_a", 0.5)
    StopAnimTask(data.ped, dict, "givetake2_b", 0.5)
    if data.onBack then data.onBack() end
end

RegisterNetEvent(GetCurrentResourceName().."Sellitems", function(data)
    local src = source
	local hasItems, hasTable = hasItem(data.item, 1, src)
    if hasItems then
		TriggerEvent(GetCurrentResourceName()..":server:toggleItem", false, data.item, hasTable[data.item].count, src)
		TriggerEvent(GetCurrentResourceName()..":server:FundPlayer", (hasTable[data.item].count * data.price), "cash", src)
    else
		triggerNotify(nil,Loc[Config.Lan].error["dont_have"].." "..Items[data.item].label, "error", src)
    end
end)

function openShop(data)
	if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
    if GetResourceState(OXInv):find("start") then
        exports[OXInv]:openInventory('shop', { type = data.shop })
    else
        TriggerServerEvent(Config.General.JimShops and "jim-shops:ShopOpen" or "inventory:server:OpenInventory", "shop", data.items.label, data.items)
    end
	lookEnt(data.coords)
end

-- Client & Server side
function hasItem(items, amount, src) local amount = amount and amount or 1
    local grabInv = nil
    local foundInv = ""
    if type(items) ~= "table" then items = { [items] = amount and amount or 1, } end
    if GetResourceState(OXInv):find("start") then
        foundInv = OXInv
        if src then grabInv = exports[OXInv]:GetInventoryItems(src)
        else grabInv = exports[OXInv]:GetPlayerItems() end

    elseif GetResourceState(QSInv):find("start") then
        foundInv = QSInv
        if src then grabInv = exports[QSInv]:GetInventory(src)
        else grabInv = exports[QSInv]:getUserInventory() end

    elseif GetResourceState(OrigenInv):find("start") then
        foundInv = OrigenInv
        if src then grabInv = exports[OrigenInv]:GetInventory(src)
        else grabInv = exports[OrigenInv]:getPlayerInventory() end

    elseif GetResourceState(CoreInv):find("start") then
        foundInv = CoreInv
        if src then
            if GetResourceState(QBExport):find("start") or GetResourceState(QBXExport):find("start") then
                grabInv = Core.Functions.GetPlayer(src).PlayerData.items
            elseif GetResourceState(ESXExport):find("start") then
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

    elseif GetResourceState(CodeMInv):find("start") then
        foundInv = CodeMInv
        if src then grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else grabInv = Core.Functions.GetPlayerData().items end

    elseif GetResourceState(QBInv):find("start") then
        foundInv = QBInv
        if src then grabInv = Core.Functions.GetPlayer(src).PlayerData.items
        else grabInv = Core.Functions.GetPlayerData().items end

    else
        print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
    end

    if grabInv then
        local hasTable = {}
        for item, amount in pairs(items) do
            if not Items[item] then print("^4ERROR^7: ^2Script can't find ingredient item in Shared Items - ^1"..item.."^7") end
            local count = 0
            for _, itemData in pairs(grabInv) do
                if itemData and (itemData.name == item) then count += (itemData.count or itemData.amount or 1) end
            end
            foundInv = foundInv:gsub("%-", "^7-^6"):gsub("%_", "^7_^6")
            local foundMessage = "^6Bridge^7: ^3hasItem^7[^6"..foundInv.."^7]: "..tostring(item).." ^3"..count.."^7/^3"..amount
            if count >= amount then foundMessage = foundMessage.." ^5FOUND^7" else foundMessage = foundMessage .." ^1NOT FOUND^7" end
            if Config.System.Debug then print(foundMessage) end
            hasTable[item] = { hasItem = count >= amount, count = count }
        end
        for k, v in pairs(hasTable) do if not v.hasItem then return false, hasTable end end
        return true, hasTable
    end
end

-- Stash Items
function openStash(data)
	if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
    if GetResourceState(OXInv):find("start") then
        exports[OXInv]:openInventory('stash', data.stash)
    elseif GetResourceState(CodeMInv):find("start") then
        -- codem-inventory method for crafting
        local slots = data.stashOptions and data.stashOptions.slots or 40
        local weight = data.stashOptions and data.stashOptions.maxweight or 100000
        local label = data.stashOptions and data.stashOptions.label or "Crafting"
        
        -- If this is a crafting bench, use specific settings
        if data.craftable then
            label = data.craftable.Header or "Crafting Bench"
            -- You can adjust slots/weight based on the crafting bench type if needed
        end
        
        TriggerServerEvent('codem-inventory:server:openstash', data.stash, slots, weight, label)
    else
        TriggerEvent("inventory:client:SetCurrentStash", data.stash)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, data.stashOptions)
	end
    lookEnt(data.coords)
end

function getStash(stashName) local stashResource = ""
    -- Add debug print for stash name
    if Config.System.Debug then
        print("^6Bridge^7: ^3getStash^7: Attempting to get stash:", stashName)
    end
    
    local stashItems, items = {}, {}
    if GetResourceState(CodeMInv):find("start") then stashResource = CodeMInv
        -- Debug before getting stash items
        if Config.System.Debug then
            print("^6Bridge^7: ^3getStash^7: Using codem-inventory to get stash")
        end
        
        stashItems = exports[CodeMInv]:GetStashItems(stashName)
        
        -- Debug the raw stash items
        if Config.System.Debug then
            print("^6Bridge^7: ^3getStash^7: Raw stash items type:", type(stashItems))
            print("^6Bridge^7: ^3getStash^7: Raw stash items:", json.encode(stashItems or {}))
        end
        
        -- Return empty table if stashItems is nil
        if not stashItems then 
            if Config.System.Debug then
                print("^6Bridge^7: ^3getStash^7: No items found in stash")
            end
            return {}
        end
        
        -- Format items for jim-mechanic's expected structure
        for _, itemData in pairs(stashItems) do
            if type(itemData) == "table" then
                local itemName = itemData.name
                if itemName then
                    local itemInfo = Items[itemName:lower()]
                    if itemInfo then
                        items[#items + 1] = {
                            name = itemName:lower(),
                            amount = tonumber(itemData.amount or 0),
                            info = itemData.info or {},
                            label = itemInfo.label,
                            description = itemInfo.description,
                            weight = itemInfo.weight,
                            type = itemInfo.type,
                            unique = itemInfo.unique,
                            useable = itemInfo.useable,
                            image = itemInfo.image,
                            slot = itemData.slot or #items + 1
                        }
                        if Config.System.Debug then
                            print("^6Bridge^7: ^3getStash^7: Added item:", itemName, "amount:", items[#items].amount)
                        end
                    end
                end
            end
        end
        
        if Config.System.Debug then
            print("^6Bridge^7: ^3getStash^7: Total items found:", #items)
            print("^6Bridge^7: ^3getStash^7: Formatted items:", json.encode(items))
        end
        
        return items
    end

    if Config.System.Debug then print("^6Bridge^7: ^2Retrieving ^3Stash^2 with ^7"..stashResource) end
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
                }
            end
        end
        if Config.System.Debug then print("^6Bridge^7: ^3getStashItems^7: ^2Stash information for ^7'^6"..stashName.."^7' ^2retrieved^7") end
    end
    return items
end

function stashRemoveItem(stashItems, stashName, items) local amount = amount and amount or 1
    if GetResourceState(OXInv):find("start") then
        for k, v in pairs(items) do
            exports[OXInv]:RemoveItem(stashName, k, v)
            if Config.System.Debug then print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..OXInv, k, v) end
        end

    elseif GetResourceState(QSInv):find("start") then
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
                            exports[QSInv]:RemoveItemIntoStash(stashName, k, v, l)
                        end
                    end
                end
            end

    elseif GetResourceState(CoreInv):find("start") then
        for k, v in pairs(items) do
            exports[CoreInv]:removeItemExact(stashName, k, v)
            if Config.System.Debug then print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..CoreInv, k, v) end
        end

    elseif GetResourceState(CodeMInv):find("start") then
        for k, v in pairs(items) do
            -- For codem-inventory, we need to remove items from the stash
            if IsDuplicityVersion() then
                -- Server-side: Update stash contents
                local currentStash = exports[CodeMInv]:GetStashItems(stashName)
                if currentStash then
                    for slot, item in pairs(currentStash) do
                        if item.name == k then
                            item.amount = tonumber(item.amount) - v
                            if item.amount <= 0 then
                                currentStash[slot] = nil
                            end
                            break
                        end
                    end
                    exports[CodeMInv]:UpdateStash(stashName, currentStash)
                end
            else
                -- Client-side: Use server event
                TriggerServerEvent('codem-inventory:server:removefromstash', stashName, k, v)
            end
            if Config.System.Debug then 
                print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..CodeMInv, k, v) 
            end
        end

    elseif GetResourceState(OrigenInv):find("start") then
        for k, v in pairs(items) do
            exports[OrigenInv]:RemoveFromStash(stashName, k, v)
            if Config.System.Debug then print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..OrigenInv, k, v) end
        end

    elseif GetResourceState(QBInv):find("start") then
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
        if Config.System.Debug then
            print("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName.."^7'")
        end
        MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', { ['stash'] = stashName, ['items'] = json.encode(stashItems) })
    else
        print("^4ERROR^7: ^2No Inventory detected ^7- ^2Check ^3exports^1.^2lua^7")
    end
end
RegisterNetEvent(GetCurrentResourceName()..":server:stashRemoveItem", stashRemoveItem)

function stashhasItem(stashItems, items, amount)
    -- Initialize empty stash as empty table rather than returning false
    if not stashItems then 
        if Config.System.Debug then 
            print("^6Bridge^7: ^3stashHasItem^7: Stash is empty") 
        end
        return false, {}
    end

    if type(items) ~= "table" then 
        items = { [items] = amount and amount or 1 } 
    end

    local hasTable = {}
    for item, amount in pairs(items) do
        local count = 0
        -- Handle codem-inventory stash format
        if GetResourceState(CodeMInv):find("start") then
            for _, itemData in pairs(stashItems) do
                if itemData and itemData.name and itemData.name:lower() == item:lower() then
                    count = count + (tonumber(itemData.amount) or 0)
                    if Config.System.Debug then
                        print("^6Bridge^7: ^3stashHasItem^7: Found item", item, "count:", count)
                    end
                end
            end
        else
            for _, itemData in pairs(stashItems) do
                if itemData and (itemData.name == item) then
                    count = count + (itemData.amount or itemData.count or 1)
                end
            end
        end

        if Config.System.Debug then
            print("^6Bridge^7: ^3stashHasItem^7: Item:", item, "Required:", amount, "Found:", count)
        end

        hasTable[item] = { hasItem = count >= amount, count = count }
        if not hasTable[item].hasItem then
            return false, hasTable
        end
    end
    return true, hasTable
end

if IsDuplicityVersion() then
    if GetResourceState(OXLibExport):find("start") then
        createCallback(GetCurrentResourceName()..':server:canCarry', function(source, itemTable) local result = canCarry(itemTable, source) return result end)
    else
        createCallback(GetCurrentResourceName()..':server:canCarry', function(source, cb, itemTable) local result = canCarry(itemTable, source) cb(result) end)
    end
end

function canCarry(itemTable, src)
    local resultTable = {}
    if src then
        if GetResourceState(OXInv):find("start") then
            for k, v in pairs(itemTable) do
                resultTable[k] = exports[OXInv]:CanCarryItem(src, k, v)
            end

        elseif GetResourceState(QSInv):find("start") then
            for k, v in pairs(itemTable) do
                resultTable[k] = exports[OXInv]:CanCarryItem(src, k, v)
            end

        elseif GetResourceState(CoreInv):find("start") then
            --??

        elseif GetResourceState(CodeMInv):find("start") then
            for k, v in pairs(itemTable) do
                local weight = Items[k].weight
                resultTable[k] = exports[CodeMInv]:CanCarryItem(src, weight, v)
            end

        elseif GetResourceState(OrigenInv):find("start") then
            for k, v in pairs(itemTable) do
                resultTable[k] = exports[OrigenInv]:canCarryItem(src, k, v)
            end

        elseif GetResourceState(QBInv):find("start") then
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
                    resultTable[k] = (totalWeight + (Items[k]['weight'] * v)) <= 120000
                end
            end
        end
    end
    return resultTable
end

function getRandomReward(itemName) -- intended for job scripts
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
            if Config.System.Debug then
                print("^6Bridge^7: ^3getRandomReward^7: ^2Total Rarity ^7'^6"..totalRarity.."^7'")
            end

            local randomNum = math.random(1, totalRarity)
            if Config.System.Debug then
                print("^6Bridge^7: ^3getRandomReward^7: ^2Random Number ^7'^6"..randomNum.."^7'")
            end
            local currentRarity = 0
            for i=1, #Config.Rewards.RewardPool do
                currentRarity += Config.Rewards.RewardPool[i].rarity
                if randomNum <= currentRarity then
                    if Config.System.Debug then
                        print("^6Bridge^7: ^3getRandomReward^7: ^2Selected toy ^7'^6"..Config.Rewards.RewardPool[i].item.."^7'")
                    end
                    addItem(Config.Rewards.RewardPool[i].item, 1)
                    return
                end
            end
        end
    end
end
