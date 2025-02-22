--- Locks or unlocks the player's inventory.
---
--- This function freezes or unfreezes the player's position, sets the inventory busy state,
--- and toggles the ability to use the inventory and hotbar based on the `toggle` parameter.
---
--- @param toggle boolean `true` to lock the inventory, `false` to unlock.
---
--- @usage
--- ```lua
--- -- Lock the player's inventory
--- lockInv(true)
---
--- -- Unlock the player's inventory
--- lockInv(false)
--- ```
function lockInv(toggle)
    FreezeEntityPosition(PlayerPedId(), toggle)
    LocalPlayer.state:set("inv_busy", toggle, true)
    TriggerEvent('inventory:client:busy:status', toggle)
    TriggerEvent('canUseInventoryAndHotbar:toggle', not toggle)
end

--- Instantly turns an entity to face a specific location or another entity.
---
--- This function calculates the heading from the first entity to the second entity or coordinates
--- and sets the entity's heading immediately without any animation.
---
--- @param ent number|nil The Ped entity to turn. Defaults to the player's Ped (`PlayerPedId()`).
--- @param ent2 number|vector3|nil The target entity or coordinates to face. If a vector, it uses the coordinates.
---
--- @usage
--- ```lua
--- -- Make the player instantly face a specific location
--- instantLookEnt(nil, vector3(200.0, 300.0, 40.0))
---
--- -- Make one entity face another entity
--- instantLookEnt(ped1, ped2)
--- ```
function instantLookEnt(ent, ent2)
    local ent = ent or PlayerPedId()
    local p1 = GetEntityCoords(ent, true)
    local p2 = type(ent2):find("vector") and ent2 or GetEntityCoords(ent2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    debugPrint("^6Bridge^7: ^1Forced ^2Turning Player to^7: '^6"..formatCoord(p2).."^7'")
    SetEntityHeading(ent, heading)
end

--- Makes the player Ped look towards a specific entity or coordinates with animation.
---
--- This function checks if the player is already facing the target. If not, it triggers a turning animation
--- to face the specified entity or coordinates.
---
--- @param entity number|vector3|vector4|nil The target entity or coordinates to look at.
---
--- @usage
--- ```lua
--- -- Make the player look at a specific location
--- lookEnt(vector3(200.0, 300.0, 40.0))
---
--- -- Make the player look at another entity
--- lookEnt(pedEntity)
--- ```
function lookEnt(entity)
    local ped = PlayerPedId()
    if entity then
        if type(entity) == "vector3" or type(entity) == "vector4" then
            if not IsPedHeadingTowardsPosition(ped, entity.xyz, 30.0) then
                TaskTurnPedToFaceCoord(ped, entity.xyz, 1500)
                debugPrint("^6Bridge^7: ^2Turning Player to^7: '^6"..formatCoord(entity).."^7'")
                Wait(1500)
            end
        else
            if DoesEntityExist(entity) then
                local entCoords = GetEntityCoords(entity)
                if not IsPedHeadingTowardsPosition(ped, entCoords, 30.0) then
                    TaskTurnPedToFaceCoord(ped, entCoords, 1500)
                    debugPrint("^6Bridge^7: ^2Turning Player to^7: '^6"..entity.."^7' - '"..formatCoord(entCoords).."^7'")
                    Wait(1500)
                end
            end
        end
    end
end

--- Server event handler for handling urinal usage.
---
--- This event decreases the player's thirst based on a random amount and updates their thirst level.
---
--- @usage
--- ```lua
--- -- Triggered when a player uses a urinal
--- TriggerServerEvent(getScript()..":server:Urinal")
--- ```
RegisterNetEvent(getScript()..":server:Urinal", function()
    local src = source
    local Player = getPlayer(src)
    local thirstamt = math.random(10, 30)
    local thirst = Player.thirst - thirstamt
    setThirst(src, getPlayer(src).thirst - thirst)
end)

--- Server event handler for setting player needs.
---
--- This event updates the player's thirst or hunger based on the provided type and amount.
---
--- @event
--- @param type string The type of need to set ("thirst" or "hunger").
--- @param amount number The amount to set the need to.
---
--- @return void
---
--- @usage
--- ```lua
--- -- Set the player's thirst level
--- TriggerServerEvent(getScript()..":server:setNeed", "thirst", 50)
---
--- -- Set the player's hunger level
--- TriggerServerEvent(getScript()..":server:setNeed", "hunger", 75)
--- ```
RegisterNetEvent(getScript()..":server:setNeed", function(type, amount)
    local src = source
    if type == "thirst" then
        setThirst(src, amount)
    elseif type == "hunger" then
        setHunger(src, amount)
    end
end)

--- Sets the player's thirst level.
---
--- This function updates the player's thirst based on the active inventory system.
---
--- @param src number The server ID of the player.
--- @param thirst number The new thirst level to set.
---
--- @usage
--- ```lua
--- -- Set a player's thirst to 80
--- setThirst(playerId, 80)
--- ```
function setThirst(src, thirst)
    if isStarted(ESXExport) then
        TriggerClientEvent('esx_status:add', src, 'thirst', thirst)
    elseif isStarted(QBExport) or isStarted(QBXExport) then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.SetMetaData('thirst', thirst)
        TriggerClientEvent("hud:client:UpdateNeeds", src, thirst, Player.PlayerData.metadata.thirst)
    end
end

--- Sets the player's hunger level.
---
--- This function updates the player's hunger based on the active inventory system.
---
--- @param src number The server ID of the player.
--- @param hunger number The new hunger level to set.
---
--- @usage
--- ```lua
--- -- Set a player's hunger to 60
--- setHunger(playerId, 60)
--- ```
function setHunger(src, hunger)
    if isStarted(ESXExport) then
        TriggerClientEvent('esx_status:add', src, 'hunger', hunger)
    elseif isStarted(QBExport) or isStarted(QBXExport) then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.SetMetaData('hunger', hunger)
        TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.hunger)
    end
end

--- Server event handler for charging a player.
---
--- This event removes money from a player based on the specified type ("cash" or "bank").
---
--- @event
--- @param cost number The amount of money to charge.
--- @param type string The type of money to charge ("cash" or "bank").
--- @param newsrc number|nil Optional. The server ID of the player. If `nil`, uses the event source.
---
--- @usage
--- ```lua
--- -- Charge a player $100 in cash
--- chargePlayer(100, "cash", playerId)
---
--- -- Charge the source $250 from the bank
--- chargePlayer(250, "bank", src,)
--- ```
function chargePlayer(cost, type, newsrc)
    local src = newsrc or source
    local fundResource = ""
    if type == "cash" then
        if isStarted(OXInv) then fundResource = OXInv
            exports[OXInv]:RemoveItem(src, "money", cost)
        elseif isStarted(QBExport) or isStarted(QBXExport) then fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("cash", cost)
        elseif isStarted(ESXExport) then fundResource = ESXExport
            local Player = ESX.GetPlayerFromId(src)
            Player.removeMoney(cost, "")
        end
    end
    if type == "bank" then
        if isStarted(QBExport) or isStarted(QBXExport) then fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.RemoveMoney("bank", cost)
        elseif isStarted(ESXExport) then fundResource = ESXExport
            local Player = ESX.GetPlayerFromId(src)
            Player.removeMoney(cost, "")
        end
    end
    if fundResource == "" then print("error - check exports.lua")
    else
        debugPrint("^6Bridge^7: ^2Charging ^2Player^7: '^6"..cost.."^7'", type, fundResource)
    end
end
RegisterNetEvent(getScript()..":server:ChargePlayer", chargePlayer)

--- Server event handler for funding a player.
---
--- This event adds money to a player based on the specified type ("cash" or "bank").
---
--- @event
--- @param fund number The amount of money to add.
--- @param type string The type of money to add ("cash" or "bank").
--- @param newsrc number|nil Optional. The server ID of the player. If `nil`, uses the event source.
---
--- @usage
--- ```lua
--- -- Add $150 to a player's cash
--- fundPlayer(playerId, 150, "cash")
---
--- -- Add $300 to the event source's bank account
--- fundPlayer(playerId, 300, "bank")
--- ```
function fundPlayer(fund, type, newsrc)
    local src = newsrc or source
    local fundResource = ""
    if type == "cash" then
        if isStarted(OXInv) then fundResource = OXInv
            exports[OXInv]:AddItem(src, "money", fund)
        elseif isStarted(QBExport) or isStarted(QBXExport) then fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.AddMoney("cash", fund)
        elseif isStarted(ESXExport) then fundResource = ESXExport
            local Player = ESX.GetPlayerFromId(src)
            Player.addMoney(fund, "")
        end
    end
    if type == "bank" then
        if isStarted(QBExport) or isStarted(QBXExport) then fundResource = QBExport
            Core.Functions.GetPlayer(src).Functions.AddMoney("bank", fund)
        elseif isStarted(ESXExport) then fundResource = ESXExport
            local Player = ESX.GetPlayerFromId(src)
            Player.addMoney(fund, "")
        end
    end
    if fundResource == "" then print("error - check exports.lua")
    else
        debugPrint("^6Bridge^7: ^2Funding ^2Player^7: '^2"..fund.."^7'", type, fundResource)
    end
end

RegisterNetEvent(getScript()..":server:FundPlayer", fundPlayer)

--- Handles successful consumption of an item.
---
--- This function plays a consumption animation, removes the item from the inventory,
--- updates the player's hunger and thirst based on the item consumed,
--- handles alcohol effects, and checks for random rewards.
---
--- @param itemName string The name of the item consumed.
--- @param type string The type/category of the item (e.g., "alcohol").
---
--- @usage
--- ```lua
--- -- Player consumes a health pack
--- ConsumeSuccess("health_pack", "health")
---
--- -- Player consumes an alcohol drink
--- ConsumeSuccess("beer", "alcohol")
--- ```
function ConsumeSuccess(itemName, type, data)
    local hunger = data and data.hunger or Items[itemName].hunger or nil
    local thirst = data and data.thirst or Items[itemName].thirst or nil
    ExecuteCommand("e c")
    removeItem(itemName, 1)
    if isStarted(ESXExport) then
        if hunger then
            TriggerServerEvent(getScript()..":server:setNeed", "hunger", hunger * 10000)
        end
        if thirst then
            TriggerServerEvent(getScript()..":server:setNeed", "thirst", thirst * 10000)
        end
    else
        if hunger then
            TriggerServerEvent(getScript()..":server:setNeed", "hunger", Core.Functions.GetPlayerData().metadata["hunger"] + hunger)
        end
        if thirst then
            TriggerServerEvent(getScript()..":server:setNeed", "thirst", Core.Functions.GetPlayerData().metadata["thirst"] + thirst)
        end
    end
    if type == "alcohol" then alcoholCount += 1
        if alcoholCount > 1 and alcoholCount < 4 then
            TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
        elseif alcoholCount >= 4 then
            TriggerEvent("evidence:client:SetStatus", "heavyalcohol", 200)
            AlienEffect()
        end
    end
    getRandomReward(itemName) -- check if a reward item should be given
end

--- Checks if a player has a specific job and grade.
---
--- This function verifies whether the player has the specified job and, if a grade is provided,
--- whether the player's grade meets the required level. It supports multiple inventory systems.
---
--- @param job string The name of the job or gang to check.
--- @param source number|nil Optional. The server ID of the player to check. If `nil`, checks the current player.
--- @param grade number|nil Optional. The minimum grade level required.
---
--- @return boolean, boolean Returns `true` and `duty status` if the player has the job (and grade if specified), otherwise `false`.
---
--- @usage
--- ```lua
--- -- Check if the player has the 'police' job and is on duty
--- local hasPoliceJob, isOnDuty = hasJob("police")
--- if hasPoliceJob and isOnDuty then
---     -- Grant access to police-specific features
--- end
---
--- -- Check if a specific player has the 'gang_leader' job with at least grade 2
--- local hasGangLeaderJob, _ = hasJob("gang_leader", playerId, 2)
--- if hasGangLeaderJob then
---     -- Allow gang leader actions
--- end
--- ```
function hasJob(job, source, grade) local hasJob, duty = false, true
    if source then
        local src = tonumber(source)
        if not src then print(tostring(source).." is not a valid player source") end
        if isStarted(ESXExport) then
            local info = ESX.GetPlayerFromId(src).job
            while not info do
                info = ESX.GetPlayerData(src).job
                Wait(100)
            end
            if info.name == job then hasJob = true end

        elseif isStarted(OXCoreExport) then
            local chunk = assert(load(LoadResourceFile('ox_core', ('imports/%s.lua'):format('server')), ('@@ox_core/%s'):format(file)))
            chunk()
            local player = Ox.GetPlayer(tonumber(src))
            for k, v in pairs(player.getGroups()) do
                if k == job then hasJob = true end
            end

        elseif isStarted(QBXExport) then
            local jobinfo = exports[QBXExport]:GetPlayer(src).PlayerData.job
            if jobinfo.name == job then hasJob = true
                duty = exports[QBXExport]:GetPlayer(src).PlayerData.job.onduty
                if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
            end
            local ganginfo = exports[QBXExport]:GetPlayer(src).PlayerData.gang
            if ganginfo.name == job then hasJob = true
                if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
            end

        elseif isStarted(QBExport) and not isStarted(QBXExport) then
            if Core.Functions.GetPlayer then -- support older qb-core functions
                local player = Core.Functions.GetPlayer(src)
                if not player then print("Player not found for src: "..src) end
                local jobinfo = player.PlayerData.job
                if jobinfo.name == job then hasJob = true
                    duty = Core.Functions.GetPlayer(src).PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
                end
                local ganginfo = Core.Functions.GetPlayer(src).PlayerData.gang
                if ganginfo.name == job then hasJob = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
                end
            else -- support newer qb-core exports
                local jobinfo = exports[QBExport]:GetPlayer(src).PlayerData.job
                if jobinfo.name == job then hasJob = true
                    duty = exports[QBExport]:GetPlayer(src).PlayerData.job.onduty
                    if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
                end
                local ganginfo = exports[QBExport]:GetPlayer(src).PlayerData.gang
                if ganginfo.name == job then hasJob = true
                    if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
                end
            end
        else
            print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3exports^1.^2lua^7")
        end
    else
        if isStarted(ESXExport) then
            while not ESX do Wait(10) end
            local info = ESX.GetPlayerData().job
            while not info do
                info = ESX.GetPlayerData().job
                Wait(100)
            end
            if info.name == job then hasJob = true end

        elseif isStarted(OXCoreExport) then
            for k, v in pairs(exports[OXCoreExport]:GetPlayerData().groups) do
                if k == job then hasJob = true end break
            end

        elseif isStarted(QBXExport) then
            local jobinfo = QBX.PlayerData.job
            if jobinfo.name == job then hasJob = true
                duty = QBX.PlayerData.job.onduty
                if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
            end
            local ganginfo = QBX.PlayerData.gang
            if ganginfo.name == job then hasJob = true
                if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
            end

        elseif isStarted(QBExport) and not isStarted(QBXExport) then
            local info = nil
            Core.Functions.GetPlayerData(function(PlayerData)
                info = PlayerData
            end)
            local jobinfo = info.job
            if jobinfo.name == job then hasJob = true
                duty = jobinfo.onduty
                if grade and not (grade <= jobinfo.grade.level) then hasJob = false end
            end
            local ganginfo = info.gang
            if ganginfo.name == job then
                hasJob = true
                if grade and not (grade <= ganginfo.grade.level) then hasJob = false end
            end

        else
            print("^4ERROR^7: ^2No Core detected for hasJob() ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
    return hasJob, duty
end

--- Retrieves basic information about a player.
---
--- This function gathers the player's name, cash balance, and bank balance
--- based on the active inventory system. It can be called server-side or client-side.
---
---@param source number|nil Optional. The server ID of the player. If `nil`, retrieves info for the current player.
---
---@return table table A table containing the player's `name`, `cash`, and `bank` balances.
---
---@usage
--- ```lua
--- -- Get information for a specific player
--- local playerInfo = getPlayer(playerId)
--- print(playerInfo.name, playerInfo.cash, playerInfo.bank)
---
--- -- Get information for the current player (client-side)
--- local myInfo = getPlayer()
--- print(myInfo.name, myInfo.cash, myInfo.bank)
--- ```
function getPlayer(source)
    local Player = {}
    debugPrint("^6Bridge^7: ^2Getting ^3Player^2 info^7")
    if source then -- If called from server
        local src = tonumber(source)
        if isStarted(ESXExport) then
            local info = ESX.GetPlayerFromId(src)
            Player = {
                name = info.getName(),
                cash = info.getMoney(),
                bank = info.getAccount("bank").money,
            }

        elseif isStarted(OXCoreExport) then
            local file = ('imports/%s.lua'):format('server')
            local import = LoadResourceFile('ox_core', file)
            local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
            chunk()
            local player = Ox.GetPlayer(tonumber(src))
            Player = {
                name = ('%s %s'):format(player.firstName, player.lastName),
                cash = exports[OXInv]:Search(src, 'count', "money"),
                bank = 0,
            }

        elseif isStarted(QBXExport) then
            local info = exports[QBXExport]:GetPlayer(src)
            Player = {
                name = info.PlayerData.charinfo.firstname.." "..info.PlayerData.charinfo.lastname,
                cash = exports[OXInv]:Search(src, 'count', "money"),
                bank = info.Functions.GetMoney("bank"),
            }

        elseif isStarted(QBExport) and not isStarted(QBXExport) then
            if Core.Functions.GetPlayer ~= nil then -- support older qb-core functions
                local info = Core.Functions.GetPlayer(src).PlayerData
                Player = {
                    firstname = info.charinfo.firstname,
                    lastname = info.charinfo.lastname,
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                    source = info.source,
                    job = info.job.name,
                    jobBoss = info.job.isboss,
                    gang = info.gang.name,
                    gangBoss = info.gang.isboss,
                    onDuty = info.job.onduty,
                    account = info.charinfo.account,
                    citizenId = info.citizenid,
                }

            else
                local info = exports[QBExport]:GetPlayer(src).PlayerData -- this was added to new core then removed?
                Player = {
                    firstname = info.charinfo.firstname,
                    lastname = info.charinfo.lastname,
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                    source = info.source,
                    job = info.job.name,
                    jobBoss = info.job.isboss,
                    gang = info.gang.name,
                    gangBoss = info.gang.isboss,
                    onDuty = info.job.onduty,
                    account = info.charinfo.account,
                    citizenId = info.citizenid,
                }
            end

        else
            print("^4ERROR^7: ^2No Core detected for getPlayer() ^7- ^2Check ^3exports^1.^2lua^7")
        end
    else
        if isStarted(ESXExport) and ESX ~= nil then
            local info = ESX.GetPlayerData()
            local cash, bank = 0, 0
            for k, v in pairs(ESX.GetPlayerData().accounts) do
                if v.name == "money" then cash = v.money end
                if v.name == "bank" then bank = v.money end
            end
            Player = {
                name = ('%s %s'):format(info.firstName, info.lastName),
                cash = cash,
                bank = bank,
            }
        elseif isStarted(OXCoreExport) then
            local info = exports[OXCoreExport]:GetPlayerData()
            Player = {
                name = info.firstName.." "..info.lastName,
                cash = exports[OXInv]:Search('count', "money"),
                bank = 0,
            }
        elseif isStarted(QBXExport) then
            local info = exports[QBXExport]:GetPlayerData()
            Player = {
                firstname = info.charinfo.firstname,
                lastname = info.charinfo.lastname,
                name = info.charinfo.firstname.." "..info.charinfo.lastname,
                cash = info.money["cash"],
                bank = info.money["bank"],
                source = info.source,
                job = info.job.name,
                jobBoss = info.job.isboss,
                gang = info.gang.name,
                gangBoss = info.gang.isboss,
                onDuty = info.job.onduty,
                account = info.charinfo.account,
                citizenId = info.citizenid,
            }
        elseif isStarted(QBExport) and not isStarted(QBXExport) then
            local info = nil
            Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
            Player = {
                firstname = info.charinfo.firstname,
                lastname = info.charinfo.lastname,
                name = info.charinfo.firstname.." "..info.charinfo.lastname,
                cash = info.money["cash"],
                bank = info.money["bank"],
                source = info.source,
                job = info.job.name,
                jobBoss = info.job.isboss,
                gang = info.gang.name,
                gangBoss = info.gang.isboss,
                onDuty = info.job.onduty,
                account = info.charinfo.account,
                citizenId = info.citizenid,
            }
        else
            print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
    return Player
end

function GetPlayersFromCoords(coords, radius)
    local players = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            if #(coords - playerCoords) <= radius then
                players[#players+1] = playerId
            end
        end
    end
    return players
end