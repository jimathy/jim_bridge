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
    if #stashItems > 0 then return true end
    if timeout <= 0 then
        stashItems = triggerCallback(GetCurrentResourceName()..':server:GetStashItems', stashName)
        timeout = 10000
        if not timing then
            CreateThread(function()
                timing = true
                while timeout > 0 do timeout -= 1000 Wait(1000) end
                timing, stashItems, timeout = false, {}, 0
            end)
        end
    end
    return false
end

local CraftLock = false
function craftingMenu(data)
    if CraftLock then return end
    if data.stashName and not GetStashTimeout(data.stashName) then
		--triggerNotify(nil, "Chacking", "success")
    end
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
    local Menu, hasjob = {}, false
    local Recipes = data.craftable.Recipes
    local tempCarryTable = {}
	for i = 1, #Recipes do
        for k in pairs(Recipes[i]) do
            if k ~= "amount" and k ~= "job" and k ~= "gang" then
                tempCarryTable[k] = Recipes[i].amount or 1
            end
        end
    end
    local canCarryTable = triggerCallback(GetCurrentResourceName()..':server:canCarry', tempCarryTable)
	for i = 1, #Recipes do
        if not Recipes[i]["amount"] then Recipes[i]["amount"] = 1 end
        for k, v in pairs(Recipes[i]) do
			if k ~= "amount" and k ~= "job" and k ~= "gang" then
                if Recipes[i].job then
					for l, b in pairs(Recipes[i].job) do
						hasjob = hasJob(l, nil, b)
                        if hasjob == true then break end
					end
				else hasjob = true end
                local setheader, settext, disable = "", "", false
                if hasjob then
                    local itemTable = {}
                    for l, b in pairs(Recipes[i][tostring(k)]) do
                        settext = settext..(settext ~= "" and br or "")..(Items[l] and Items[l].label or "error - "..l)..(b > 1 and " x"..b or "")
                        itemTable[l] = b
                        Wait(0)
                    end
                    while not canCarryTable do Wait(0) end
                    print(json.encode(canCarryTable, {indent = true}))
                    if Config.System.Debug then print("^6Bridge^7: ^2Checking"..(data.stashName and " ^7'^6"..data.stashName.."^7'" or "").." ^2ingredients^7 - ^6"..k.."^7") end
                    if data.stashName then disable = not stashhasItem(stashItems, itemTable)
                    else disable = not hasItem(itemTable) end
                    setheader = (Items[tostring(k)] and Items[tostring(k)].label or "error - " .. tostring(k)) .. (Recipes[i]["amount"] > 1 and " x" .. Recipes[i]["amount"] or "")
                    if not disable then
                        if not canCarryTable[k] then setheader = setheader .. " 📦"
                        else setheader = setheader .. " ✔️" end
                    elseif not canCarryTable[k] then setheader = setheader .. " 📦" end
                    Menu[#Menu + 1] = {
                        isMenuHeader = disable or not canCarryTable[k],
                        icon = invImg(tostring(k)),
                        header = setheader,
                        txt = settext,
                        onSelect = function()
                            local transdata = { item = k, craft = data.craftable.Recipes[i], craftable = data.craftable, coords = data.coords, stashName = data.stashName, onBack = data.onBack }
                            if Config.Crafting.MultiCraft then multiCraft(transdata) else makeItem(transdata) end
                        end,
                    }
                end
            end
            Wait(0)
		end
	end
	openMenu(Menu, { header = data.craftable.Header, onBack = data.onBack or nil, canClose = true, onExit = function() end,  })
	lookEnt(data.coords)
end

function multiCraft(data) local Menu = {}
    local success = Config.Crafting.MultiCraftAmounts
    if data.stashName and not GetStashTimeout(data.stashName) then
		--triggerNotify(nil, "Refreshing stashinfo", "success")
    end
    Menu[#Menu+1] = {
        isMenuHeader = true,
        icon = invImg(data.item),
        header = Items[data.item].label,
    }
	for k in pairsByKeys(success) do
        local settext = ""
        local itemTable = {}
        for l, b in pairs(data.craft[data.item]) do
            itemTable[l] = (b * k)
            settext = settext..(settext ~= "" and br or "")..Items[l].label..(b*k > 1 and "- x"..b*k or "")
            Wait(0)
        end
        local disable = false
        if Config.System.Debug then print("^6Bridge^7: ^2Checking "..(data.stashName and "^7'^6"..data.stashName.."^7'" or "inventory").."^7x^5"..k.." ^2ingredients^7 - ^6"..data.item.."^7") end
        if data.stashName then disable = not stashhasItem(stashItems, itemTable)
        else disable = not hasItem(itemTable) end

		Menu[#Menu + 1] = {
			isMenuHeader = disable,
            arrow = not disable,
            header = "Craft - x"..k * data.craft.amount,
            txt = settext,
            onSelect = function ()
                makeItem({item = data.item, craft = data.craft, craftable = data.craftable, amount = k, coords = data.coords, stashName = data.stashName, onBack = data.onBack })
            end,
        }
	end
    openMenu(Menu, { header = data.craftable.Header, onBack = function() craftingMenu(data) end, })
end

function makeItem(data)
	if CraftLock then return end
	CraftLock = true

	local bartime = data.craftable.progressBar and data.craftable.progressBar.time or 5000
	local bartext = data.craftable.progressBar and data.craftable.progressBar.label or Loc[Config.Lan].progressbar["progress_make"]
	local animDict = data.craftable.Anims.animDict or "amb@prop_human_parking_meter@male@idle_a"
	local anim = data.craftable.Anims.anim or "idle_a"
	local amount = data.amount and (data.amount ~= 1) and data.amount or 1

	local crafted, crafting = true, true
	local cam = createTempCam(PlayerPedId(), data.coords)
	startTempCam(cam)

    for i = 1, amount do
        for k, v in pairs(data.craft) do
            if k ~= "amount" and k ~= "job" then
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
                            --TriggerEvent('inventory:client:ItemBox', Items[l], "use", b) -- Show item box for each item
                        else
							crafted, crafting = false, false
							break
                        end
                        Wait(200)
                    end
                    if crafted then
                        if crafting and progressBar({
                            label = bartext..Items[data.item].label,
                            time = bartime,
                            cancel = true,
                            dict = animDict,
                            anim = anim,
                            flag = 8,
                            icon = data.item,
                        }) then
                            TriggerServerEvent(GetCurrentResourceName()..":Crafting:GetItem", data.item, data.craft, data.stashName)
                        else
                            crafting = false
                            break
                        end
                    end
                end
            end
        end
        Wait(500)
    end
    stopTempCam()
    CraftLock = false
    lockInv(false)
    craftingMenu(data)
    ClearPedTasks(PlayerPedId())
end

RegisterNetEvent(GetCurrentResourceName()..":Crafting:GetItem", function(ItemMake, craftable, stashName)
    local src, amount, stashItems = source, craftable and craftable.amount or 1, stashName and getStash(stashName)
    if stashName then
        local itemRemove = {}
        for k, v in pairs(craftable[ItemMake] or {}) do
            for _, b in pairs(stashItems or {}) do
                if k == b.name then itemRemove[k] = v end
            end
        end
        stashRemoveItem(stashItems, stashName, itemRemove)
    else
        if craftable then
            for k, v in pairs(craftable[ItemMake] or {}) do
                TriggerEvent(GetCurrentResourceName()..":server:toggleItem", false, tostring(k), v, src)
            end
        end
    end
    TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, ItemMake, amount, src)
    if GetResourceState("core_skills"):find("start") then exports["core_skills"]:AddExperience(src, 2) end
end)

--[[SHOPS]]--
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
        grabInv = src and exports.ox_inventory:GetInventoryItems(src) or exports[OXInv]:GetPlayerItems()

    elseif GetResourceState(QSInv):find("start") then
        foundInv = QSInv
        grabInv = src and exports[QSInv]:GetInventory(src) or exports[QSInv]:getUserInventory()

    elseif GetResourceState(OrigenInv):find("start") then
        foundInv = OrigenInv
        grabInv = src and exports[OrigenInv]:getPlayerInventory(src) or exports[OrigenInv]:getPlayerInventory()

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
        grabInv = src and exports[CodeMInv]:GetUserInventory(src) or exports[CodeMInv]:GetClientPlayerInventory()

    elseif GetResourceState(QBInv):find("start") then
        foundInv = QBInv
        grabInv = src and Core.Functions.GetPlayer(src).PlayerData.items or Core.Functions.GetPlayerData().items

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
        exports[CodeMInv]:OpenStash(data.stash, 400000, 100)
    else
        TriggerEvent("inventory:client:SetCurrentStash", data.stash)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash, data.stashOptions)
	end
    lookEnt(data.coords)
end

function getStash(stashName) local stashResource = ""
    local stashItems, items = {}, {}
    if GetResourceState(OXInv):find("start") then stashResource = OXInv
        stashItems = exports[OXInv]:Inventory(stashName).items

    elseif GetResourceState(QSInv):find("start") then stashResource = QSInv
        stashItems = exports[QSInv]:GetStashItems(stashName)

    elseif GetResourceState(CoreInv):find("start") then stashResource = CoreInv
        stashItems = exports[CoreInv]:getInventory(stashName)

    elseif GetResourceState(CodeMInv):find("start") then stashResource = CodeMInv
        stashItems = exports[CodeMInv]:GetInventoryItems('Stash', stashName)

    elseif GetResourceState(OrigenInv):find("start") then stashResource = OrigenInv
        stashItems = exports[OrigenInv]:GetStashItems(stashName)

    elseif GetResourceState(QBInv):find("start") then stashResource = QBInv
        local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
		if result then stashItems = json.decode(result) end
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
        if Config.System.Debug then print("^6Bridge^7: ^3GetStashItems^7: ^2Stash information for ^7'^6"..stashName.."^7' ^2retrieved^7") end
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
            for l in pairs(stashItems) do
                if stashItems[l].name == k then
                    if (stashItems[l].amount - v) <= 0 then
                        if Config.System.Debug then
                            print("^6Bridge^7: ^2None of this item left in stash ^3Stash^7", k, v)
                        end
                        stashItems[l] = nil
                    else
                        if Config.System.Debug then
                            print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..CodeMInv, k, v)
                        end
                        stashItems[l].amount -= v
                    end
                end
            end
        end
        if Config.System.Debug then
            print("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName.."^7'")
        end

    elseif GetResourceState(OrigenInv):find("start") then
        for k, v in pairs(items) do
            exports[OrigenInv]:RemoveItem(stashName, k, v)
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
    local invs = {OXInv, QSInv, CoreInv, CodeMInv, OrigenInv, QBInv}
    local foundInv = ""
    for _, inv in ipairs(invs) do
        if GetResourceState(inv):find("start") then
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
        if Config.System.Debug then print(debugMsg) end

        hasTable[item] = { hasItem = (count >= amount), count = count }
    end
    for k, v in pairs(hasTable) do if v.hasItem == false then return false, hasTable end end
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
    print("checking if player can carry")
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