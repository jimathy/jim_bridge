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
        fundPlayer((hasTable[data.item].count * data.price), "cash", src)
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
    jsonPrint(data)
    if (data.job or data.gang) and not jobCheck(data.job or data.gang) then return end

    if Config.General.JimShops then
        TriggerServerEvent("jim-shops:ShopOpen", "shop", data.items.label, data.items)

    elseif isStarted(OXInv) then
        exports[OXInv]:openInventory('shop', { type = data.shop })

    elseif isStarted(QSInv) then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", data.items.label, data.items)

    elseif isStarted(TgiannInv) then
        TriggerServerEvent(getScript()..':server:OpenShopTgiann', data.shop)

    elseif isStarted(QBInv) then
        if QBInvNew then
            TriggerServerEvent(getScript()..':server:OpenShopNewQB', data.shop)
        else
            TriggerServerEvent("inventory:server:OpenInventory", "shop", data.items.label, data.items)
        end

    elseif isStarted(RSGInv) then
        TriggerServerEvent(getScript()..':server:OpenShopRSG', data.shop)
    end
    lookEnt(data.coords)
end

RegisterNetEvent(getScript()..':server:OpenShopNewQB', function(data)
    exports[QBInv]:OpenShop(source, data)
end)

RegisterNetEvent(getScript()..':server:OpenShopTgiann', function(data)
    exports[TgiannInv]:OpenShop(source, data)
end)

RegisterNetEvent(getScript()..':server:OpenShopRSG', function(data)
    exports[RSGInv]:OpenShop(source, data)
end)

--- Registers a shop with the active inventory system.
--- Supports either OXInv or QBInv (with QBInvNew flag).
---
--- @param name string Unique shop identifier.
--- @param label string Display name for the shop.
--- @param items table List of available shop items.
--- @param society string|nil (Optional) Society identifier for shared shops.
--- @usage
--- ```lua
--- registerShop("weaponShop", "Weapon Shop", weaponItems, "society_weapons")
--- ```
function registerShop(name, label, items, society)
    if isStarted(OXInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3OX ^2Store^7:", name, label)
        exports[OXInv]:RegisterShop(name, {
            name = label,
            inventory = items,
            society = society,
        })

    elseif isStarted(TgiannInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3Tgiann ^2Store^7:", name, label)
        exports[TgiannInv]:RegisterShop(name, items)

    elseif isStarted(QBInv) and QBInvNew then
        debugPrint("^6Bridge^7: ^2Registering ^3QB ^2Store^7:", name, label)
        exports[QBInv]:CreateShop({
            name = name,
            label = label,
            slots = #items,
            items = items,
            society = society,
        })

    elseif isStarted(RSGInv) then
        debugPrint("^6Bridge^7: ^2Registering ^3RSG ^2Store^7:", name, label)
        exports[RSGInv]:CreateShop({
            name = name,
            label = label,
            slots = #items,
            items = items,
            society = society,
        })
    end
end