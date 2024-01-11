if GetResourceState(OXLibExport):find("start") then
    createCallback(GetCurrentResourceName()..':server:GetStashItems', function(source, stashName) local stash = getStash(stashName) return stash end)
else
    createCallback(GetCurrentResourceName()..':server:GetStashItems', function(source, cb, stashName) local stash = getStash(stashName) cb(stash) end)
end

local timeout = 0
local timing = false
local stashItems = {}
function GetStashTimeout(stashName, stop)
	if stop then stashItems = {} timing = false timeout = 0 return end
	if stashItems[1] then return true else
		if timeout <= 0 then
			stashItems = triggerCallback(GetCurrentResourceName()..':server:GetStashItems', stashName)
			timeout = 15000
			if not timing then
				CreateThread(function()
					timing = true
					while timeout > 0 do timeout -= 1000 Wait(1000) end
					timing = false stashItems = {} timeout = 0
				end)
			end
		end
		return false
	end
end

local CraftLock = false
function craftingMenu(data)
    if CraftLock then return end
    if data.stashName and not GetStashTimeout(data.stashName) then
		--triggerNotify(nil, "Chacking", "success")
    end
	if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
	local Menu = {}
    local Recipes = data.craftable.Recipes
	for i = 1, #Recipes do
		for k, v in pairs(Recipes[i]) do
			if k ~= "amount" and k ~= "job" and k ~= "gang" then
                if Recipes[i].job then hasjob = false
					for l, b in pairs(data.craftable[i]["job"]) do
						hasjob = hasJob(l)
					end
				end
                local setheader, settext = "", ""
				local text = ""
				local disable = false
				local checktable = {}
                if Recipes[i].job and hasjob == false then else
                    for l, b in pairs(Recipes[i][tostring(k)]) do
                        if not Items[l] then print("^3Error^7: ^2Script can't find ingredient item in Shared Items - ^1"..l.."^7") return end
                        settext = settext..(settext ~= "" and br or "")..Items[l].label..(b > 1 and " x"..b or "")
                        if data.stashName then checktable[l] = stashhasItem(stashItems, l, b)
                        else checktable[l] = hasItem(l, b) end
                        Wait(0)
                    end
                    for _, v in pairs(checktable) do
                        if not v then
                            disable = true
                            break
                        end
                    end
                    setheader = Items[tostring(k)].label..(Recipes[i]["amount"] > 1 and " x"..Recipes[i]["amount"] or "")..(not disable and " ✔️" or "")
                    Menu[#Menu + 1] = {
                        isMenuHeader = disable,
                        icon = invImg(tostring(k)),
                        header = setheader, txt = settext,
                        onSelect = function()
                            local transdata = { item = k, craft = data.craftable.Recipes[i], craftable = data.craftable, coords = data.coords, stashName = data.stashName, onBack = data.onBack }
                            if Config.Crafting.MultiCraft then
                                multiCraft(transdata)
                            else
                                makeItem(transdata)
                            end
                        end,
                    }
                end
            end
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
        for l, b in pairs(data.craft[data.item]) do
            if data.stashName then
                success[k] = stashhasItem(stashItems, l, (b * k))
            else
                success[k] = hasItem(l, (b * k))
            end
            settext = settext..(settext ~= "" and br or "")..Items[l].label..(b*k > 1 and "- x"..b*k or "")
            Wait(0)
        end
		Menu[#Menu + 1] = {
			isMenuHeader = not success[k],
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
	if not CraftLock then CraftLock = true else return end
    local bartime, bartext, animDict, anim = nil, nil, nil, nil
    if data.craftable.progressBar then
        bartime = data.craftable.progressBar.time
        bartext = data.craftable.progressBar.label
    else
        bartime = 5000
        bartext = Loc[Config.Lan].progressbar["progress_make"]
    end
    animDict = data.craftable.Anims.animDict or "amb@prop_human_parking_meter@male@idle_a"
    anim = data.craftable.Anims.anim or "idle_a"

    local amount = (data.amount and data.amount ~= 1) and data.amount or 1

    local crafted = true
    local crafting = true

    local cam = createTempCam(PlayerPedId(), data.coords)
    startTempCam(cam)

    for i = 1, amount do
        for _, v in pairs(data.craft) do
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
                        crafted = false
                        crafting = false
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
        Wait(500)
    end
    stopTempCam()
    CraftLock = false
    lockInv(false)
    craftingMenu(data)
    ClearPedTasks(PlayerPedId())
end

RegisterNetEvent(GetCurrentResourceName()..":Crafting:GetItem", function(ItemMake, craftable, stashName)
	local src = source
	local amount = 1
    if stashName then
        local stashItems = getStash(stashName)
        if craftable["amount"] then amount = craftable["amount"] end
        local itemRemove = {}
        for k, v in pairs(craftable[ItemMake]) do
            for l, b in pairs(stashItems) do
                if k == b.name then
                    itemRemove[k] = v
                end
            end
        end
        stashRemoveItem(stashItems, stashName, itemRemove)
    else
        if craftable then
            if craftable["amount"] then amount = craftable["amount"] end
            for k, v in pairs(craftable[ItemMake]) do
                TriggerEvent(GetCurrentResourceName()..":server:toggleItem", false, tostring(k), v, src)
            end
        end
    end
    TriggerEvent(GetCurrentResourceName()..":server:toggleItem", true, ItemMake, amount, src)
end)

--[[SHOPS]]--
function openShop(data)
	if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end
    if GetResourceState(OXInv):find("start") then
        exports[OXInv]:openInventory('shop', { type = data.shop })
    else
        TriggerServerEvent(Config.JimShops and "jim-shops:ShopOpen" or "inventory:server:OpenInventory", "shop", data.shop, data.items)
    end
	lookEnt(data.coords)
end

-- Client & Server side
function hasItem(items, amount, src) local amount, count = amount and amount or 1, 0
    if src then
        if GetResourceState(OXInv):find("start") then
            local item = exports[OXInv]:GetItem(src, items)
            local amount = (amount or 1)
            if item.count >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..item.count.."^7/^3"..amount.." "..tostring(items)) end
                return true
            else if Config.System.Debug then
                print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end

        elseif GetResourceState(QSInv):find("start") then
            for _, itemData in pairs(exports[QSInv]:GetInventory(src)) do
                if itemData and (itemData.name == items) then
                    --if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
                    count += (itemData.amount or 1)
                end
            end
            if count >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items)) end
                return true
                else
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end

        elseif GetResourceState(CoreInv):find("start") then
            local item = exports[CoreInv]:getItems('primary-'..src, items)

            if item.amount >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..item.amount.."^7/^3"..amount.." "..tostring(items)) end
                return true
            else if Config.System.Debug then
                print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end

        elseif GetResourceState(CodeMInv):find("start") then
            local success = exports["codem-inventory"]:CheckItemValid(src, items, amount)
            if success then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..amount.." "..tostring(items)) end
                return true
            end

        elseif GetResourceState(CodeMInv):find("start") then
            for _, itemData in pairs(exports[CodeMInv]:GetUserInventory(src)) do
                if itemData and (itemData.name == items) then
                    if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
                    count += (itemData.amount or 1)
                end
            end
            if count >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items)) end
                return true
            else
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end

        else
            for _, itemData in pairs(Core.Functions.GetPlayer(src).PlayerData.items) do
                if itemData and (itemData.name == items) then
                    if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
                    count += (itemData.amount or 1)
                end
            end
            if count >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items)) end
                return true
            else
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end
        end
    else
        if GetResourceState(OXInv):find("start") then
            local count = tonumber(exports[OXInv]:Search('count', items))
            local amount = (amount or 1)
            if count >= amount then if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items)) end return true
            else if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end return false end

        elseif GetResourceState(QSInv):find("start") then
            for _, itemData in pairs(exports[QSInv]:GetInventory()) do
                if itemData and (itemData.name == items) then
                    if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
                    count += (itemData.amount or 1)
                end
            end
            if count >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items)) end
                return true
            else
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end

        elseif GetResourceState(CoreInv):find("start") then
            for _, itemData in pairs(exports[CoreInv]:getInventory('primary-'..GetPlayerServerId(PlayerPedId()))) do
                if itemData and (itemData.name == items) then
                    if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
                    count += (itemData.amount or 1)
                end
            end
            if count >= amount then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items)) end
                return true
                else
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7") end
                return false
            end

        elseif GetResourceState(CodeMInv):find("start") then
            local success = exports[CodeMInv]:CheckItemValid(items, amount)
            if success then
                if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..amount.." "..tostring(items)) end
                return true
            end

        elseif GetResourceState(QBInv):find("start") then
            --if tonumber(GetResourceMetadata(QBInv, 'version')) <= 1.2 then
            --    return exports[QBInv]:HasItem(items, amount)
            --else
                for _, itemData in pairs(Core.Functions.GetPlayerData().items) do
                    if itemData and (itemData.name == items) then
                        if Config.System.Debug then print("^6Bridge^7: ^3HasItem^7: ^2Item^7: '^3"..tostring(items).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)") end
                        count += (itemData.amount or 1)
                    end
                end
                if count >= amount then
                    if Config.System.Debug then
                        print("^6Bridge^7: ^3HasItem^7: ^5FOUND^7 ^3"..count.."^7/^3"..amount.." "..tostring(items))
                    end
                    return true
                else
                    if Config.System.Debug then
                        print("^6Bridge^7: ^3HasItem^7: ^2"..tostring(items).." ^1NOT FOUND^7")
                    end
                    return false
                end
            -- end
        end
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
        TriggerServerEvent("inventory:server:OpenInventory", "stash", data.stash)
	end
    lookEnt(data.coords)
end

function getStash(stashName)
    local stashItems, items = {}, {}
    if GetResourceState(OXInv):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Retrieving ^3Stash^2 with ^7ox_inventory") end
        stashItems = exports[OXInv]:Inventory(stashName).items
    elseif GetResourceState(QSInv):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Retrieving ^3Stash^2 with ^7qs-inventory") end
        stashItems = exports[QSInv]:GetStashItems(stashName)
    elseif GetResourceState(CodeMInv):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Retrieving ^3Stash^2 with ^7qs-inventory") end
        stashItems = exports[CodeMInv]:GetInventoryItems('Stash', stashName)
    elseif GetResourceState(QBInv):find("start") then
        if Config.System.Debug then print("^6Bridge^7: ^2Retrieving ^3Stash^2 with ^7qb-inventory") end
        local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashName })
		if result then stashItems = json.decode(result) end
    end
    if stashItems then
        for _, item in pairs(stashItems) do
            local itemInfo = Items[item.name:lower()]
            if itemInfo then
                items[item.slot] = {
                    name = itemInfo["name"],
                    amount = tonumber(item.amount) or tonumber(item.count),
                    info = item.info ~= nil and item.info or "",
                    label = itemInfo["label"],
                    description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
                    weight = itemInfo["weight"],
                    type = itemInfo["type"],
                    unique = itemInfo["unique"],
                    useable = itemInfo["useable"],
                    image = itemInfo["image"],
                    slot = item.slot,
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
            exports[QSInv]:RemoveItemIntoStash(stashName, k, v)
            if Config.System.Debug then print("^6Bridge^7: ^2Removing item from ^3Stash^2 with ^7"..QSInv, k, v) end
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
        if Config.System.Debug then
            print("^6Bridge^7: ^3saveStash^7: ^2Saving ^3QB^2 stash ^7'^6"..stashName.."^7'")
        end
        MySQL.Async.insert('INSERT INTO stashitems (stash, items) VALUES (:stash, :items) ON DUPLICATE KEY UPDATE items = :items', { ['stash'] = stashName, ['items'] = json.encode(stashItems) })
    end
end
RegisterNetEvent(GetCurrentResourceName()..":server:stashRemoveItem", stashRemoveItem)

function stashhasItem(stashItems, item, amount) local amount, count = amount and amount or 1, 0
	for k, itemData in pairs(stashItems) do
		if itemData and (itemData.name == item) then
			--if Config.System.Debug then
            --    print("^6Bridge^7: ^3stashHasItem^7: ^2Item^7: '^3"..tostring(item).."^7' ^2Slot^7: ^3"..itemData.slot.." ^7x(^3"..tostring(itemData.amount).."^7)")
            --end
			count += (itemData.amount or 1)
		end
	end
	if count >= amount then
        if Config.System.Debug then
            print("^6Bridge^7: ^3stashHasItem^7: ^2Items ^3"..item.." ^5FOUND^7 x^3"..count.."^7/^3"..amount.."^7") end
            return
            true
	else
        if Config.System.Debug then print("^6Bridge^7: ^3stashHasItem^7: ^2Items ^1NOT FOUND^7 "..json.encode(item)) end
        return false
    end
end