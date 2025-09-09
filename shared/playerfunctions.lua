--[[
    Player Utility & Server Event Handlers Module
    ------------------------------------------------
    This module provides utility functions for:
      • Locking/unlocking the player's inventory.
      • Instantly turning or gradually turning the player to face a target.
      • Handling player needs (thirst and hunger) via server events.
      • Charging/funding players (money removal/addition).
      • Processing item consumption and applying effects.
      • Checking player job/gang roles and retrieving player information.
      • Getting active players near a coordinate.
]]

local hungerThirstFunc = {
    {   framework = QBXExport,
        setThirst =
            function(src, thirst)
                local Player = Core.Functions.GetPlayer(src)
                Player.Functions.SetMetaData('thirst', thirst)
                TriggerClientEvent("hud:client:UpdateNeeds", src, Player.PlayerData.metadata.hunger, thirst)
            end,
        setHunger =
            function(src, hunger)
                local Player = Core.Functions.GetPlayer(src)
                Player.Functions.SetMetaData('hunger', hunger)
                TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.thirst)
            end,
    },

    {   framework = QBExport,
        setThirst =
            function(src, thirst)
                local Player = Core.Functions.GetPlayer(src)
                Player.Functions.SetMetaData('thirst', thirst)
                TriggerClientEvent("hud:client:UpdateNeeds", src, Player.PlayerData.metadata.hunger, thirst)
            end,
        setHunger =
            function(src, hunger)
                local Player = Core.Functions.GetPlayer(src)
                Player.Functions.SetMetaData('hunger', hunger)
                TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.thirst)
            end,
    },

    {   framework = RSGExport,
        setThirst =
            function(src, thirst)
                local Player = Core.Functions.GetPlayer(src)
                Player.Functions.SetMetaData('thirst', thirst)
                TriggerClientEvent("hud:client:UpdateNeeds", src, Player.PlayerData.metadata.hunger, thirst)
            end,
        setHunger =
            function(src, hunger)
                local Player = Core.Functions.GetPlayer(src)
                Player.Functions.SetMetaData('hunger', hunger)
                TriggerClientEvent("hud:client:UpdateNeeds", src, hunger, Player.PlayerData.metadata.thirst)
            end,
    },

    {   framework = ESXExport,
        setThirst =
            function(src, thirst)
                TriggerClientEvent('esx_status:add', src, 'thirst', thirst)
            end,
        setHunger =
            function(src, hunger)
                TriggerClientEvent('esx_status:add', src, 'hunger', hunger)
            end,
    },
}


-------------------------------------------------------------
-- Server Event Handlers for Needs
-------------------------------------------------------------

--- Sets the player's thirst level.
---
--- @param src number The player's server ID.
--- @param thirst number The new thirst level.
---
--- @usage
--- ```lua
--- setThirst(playerId, 80)
--- ```
function setThirst(src, thirst)
    for i = 1, #hungerThirstFunc do
        local framework = hungerThirstFunc[i]
        if isStarted(framework.framework) then
            debugPrint("^4Debug^7: ^2Adding ^3"..framework.framework.." ^2thirst^7: ^3"..thirst.." ^2to player^7: ^3"..src.."^7")
            framework.setThirst(src, thirst)
            return
        end
    end
end

--- Sets the player's hunger level.
---
--- @param src number The player's server ID.
--- @param hunger number The new hunger level.
---
--- @usage
--- ```lua
--- setHunger(playerId, 60)
--- ```
function setHunger(src, hunger)
    for i = 1, #hungerThirstFunc do
        local framework = hungerThirstFunc[i]
        if isStarted(framework.framework) then
            debugPrint("^4Debug^7: ^2Adding ^3"..framework.framework.." ^2hunger^7: ^3"..hunger.." ^2to player^7: ^3"..src.."^7")
            framework.setHunger(src, hunger)
            return
        end
    end
end

--- Server event handler for urinal usage.
--- Decreases player's thirst by a random amount.
RegisterNetEvent(getScript()..":server:Urinal", function()
    local src = source
    local Player = getPlayer(src)
    local thirstamt = math.random(10, 30)
    local thirst = Player.thirst - thirstamt
    setThirst(src, getPlayer(src).thirst - thirst)
end)

--- Server event handler for setting player needs (thirst or hunger).
---
--- @event
--- @param type string "thirst" or "hunger".
--- @param amount number New value to set.
RegisterNetEvent(getScript()..":server:setNeed", function(needType, amount)
    local src = source
    if needType == "thirst" then
        setThirst(src, amount)
    elseif needType == "hunger" then
        setHunger(src, amount)
    end
end)

-------------------------------------------------------------
-- Economy Event Handlers
-------------------------------------------------------------

local billPlayerFunc = {
    jim =
        function(data)
            TriggerEvent("jim-payments:client:Charge", {
                job = data.job,
                gang = data.gang,
                coords = data.coords.xyz,
                img = data.img
            })
        end,
    okok =
        function(data)
            TriggerEvent("okokBilling:ToggleCreateInvoice")
        end,
}

--- BillPlayer
function billPlayer(data)
    if Config.System.Billing and billPlayerFunc[Config.System.Billing] then
        billPlayerFunc[Config.System.Billing](data)
    else
        debugPrint("^1Error^7: ^1No billing script detected")
    end
end

-- Money Handlers

local moneyFunc = {
    {   framework = OXInv,
        chargePlayer =
            function(src, amount, moneyType)
                return exports[OXInv]:RemoveItem(src, "money", amount)
            end,
        fundPlayer =
            function(src, amount, moneyType)
                return exports[OXInv]:AddItem(src, "money", amount)
            end,
    },

    {   framework = QBXExport,
        chargePlayer =
            function(src, amount, moneyType)
                return Core.Functions.GetPlayer(src).Functions.RemoveMoney(moneyType or "cash", amount)
            end,
        fundPlayer =
            function(src, amount, moneyType)
                return Core.Functions.GetPlayer(src).Functions.AddMoney(moneyType or "cash", amount)
            end,
    },

    {   framework = QBExport,
        chargePlayer =
            function(src, amount, moneyType)
                return Core.Functions.GetPlayer(src).Functions.RemoveMoney(moneyType or "cash", amount)
            end,
        fundPlayer =
            function(src, amount, moneyType)
                return Core.Functions.GetPlayer(src).Functions.AddMoney(moneyType or "cash", amount)
            end,
    },

    {   framework = RSGExport,
        chargePlayer =
            function(src, amount, moneyType)
                return Core.Functions.GetPlayer(src).Functions.RemoveMoney(moneyType or "cash", amount)
            end,
        fundPlayer =
            function(src, amount, moneyType)
                return Core.Functions.GetPlayer(src).Functions.AddMoney(moneyType or "cash", amount)
            end,
    },

    {   framework = ESXExport,
        chargePlayer =
            function(src, amount, moneyType)
                return ESX.GetPlayerFromId(src).removeMoney(amount, "")
            end,
        fundPlayer =
            function(src, amount, moneyType)
                return ESX.GetPlayerFromId(src).addMoney(amount, "")
            end,
    },
}

--- Charges a player by removing money from their account.
---
--- @param cost number The amount to charge.
--- @param type string "cash" or "bank".
--- @param newsrc number|nil Optional player ID; defaults to event source.
---
--- @usage
--- ```lua
--- chargePlayer(100, "cash", playerId)
--- ```
---
function chargePlayer(cost, moneyType, newsrc)
    local is_success = false
    local src = newsrc or source

    if cost <= 0 then
        debugPrint("^1Error^7: ^7SRC: ^3"..src.." ^2Tried to charge a zero or minus value^7", cost)
        return
    end

    for i = 1, #moneyFunc do
        local framework = moneyFunc[i]
        if framework.framework == OXInv and moneyType == "bank" then goto skip end
        if isStarted(framework.framework) then
            debugPrint("^6Bridge^7: ^2Charging ^3"..framework.framework.." ^2Player^7: '^6"..cost.."^7'", moneyType)
            is_success = framework.chargePlayer(src, cost, moneyType)
            break
        end
        ::skip::
    end
    return is_success
end

RegisterNetEvent(getScript()..":server:ChargePlayer", function(cost, moneyType, newsrc)
	if GetInvokingResource() and GetInvokingResource() ~= getScript() and GetInvokingResource() ~= "qb-core" then
        print(GetInvokingResource())
        print("^1Error^7: ^1Possible exploit^7, ^1vital function was called from an external resource^7")
        return
    end
    chargePlayer(cost, moneyType, newsrc)
end)

--- Funds a player by adding money to their account.
---
--- @param fund number The amount to add.
--- @param type string "cash" or "bank".
--- @param newsrc number|nil Optional player ID; defaults to event source.
---
--- @usage
--- ```lua
--- fundPlayer(150, "cash", playerId)
--- ```
function fundPlayer(fund, moneyType, newsrc)
    local is_success = false
    local src = newsrc or source

    if fund <= 0 then
        debugPrint("^1Error^7: ^7SRC: ^3"..src.." ^2Tried to fund a zero or minus value^7", fund)
        return
    end

    for i = 1, #moneyFunc do
        local framework = moneyFunc[i]
        if framework.framework == OXInv and moneyType == "bank" then goto skip end
        if isStarted(framework.framework) then
            debugPrint("^6Bridge^7: ^2Funding ^3"..framework.framework.." ^2Player^7: '^6"..fund.."^7'", moneyType)
            is_success = framework.fundPlayer(src, fund, moneyType)
            break
        end
        ::skip::
    end

    return is_success
end

-------------------------------------------------------------
-- Item Consumption & Effects
-------------------------------------------------------------

--- Handles successful consumption of an item.
---
--- Plays a consumption animation, removes the item, updates player needs, handles alcohol effects,
--- and checks for random rewards.
---
--- @param itemName string The name of the consumed item.
--- @param type string The category of the item (e.g., "alcohol").
--- @param data table Additional data (e.g., hunger and thirst values).
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
    local hunger = data and data.hunger or Items[itemName].hunger
    local thirst = data and data.thirst or Items[itemName].thirst

    ExecuteCommand("e c")
    removeItem(itemName, 1)

    if isStarted(ESXExport) then
        if hunger then
            TriggerServerEvent(getScript()..":server:setNeed", "hunger", tonumber(hunger) * 10000)
        end
        if thirst then
            TriggerServerEvent(getScript()..":server:setNeed", "thirst", tonumber(thirst) * 10000)
        end
    else
        if hunger then
            TriggerServerEvent(getScript()..":server:setNeed", "hunger", Core.Functions.GetPlayerData().metadata["hunger"] + tonumber(hunger))
        end
        if thirst then
            TriggerServerEvent(getScript()..":server:setNeed", "thirst", Core.Functions.GetPlayerData().metadata["thirst"] + tonumber(thirst))
        end
    end

    if type == "alcohol" then
        alcoholCount = (alcoholCount or 0) + 1
        if alcoholCount > 1 and alcoholCount < 4 then
            TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
        elseif alcoholCount >= 4 then
            TriggerEvent("evidence:client:SetStatus", "heavyalcohol", 200)
            AlienEffect()
        end
    end

    if Config.Reward then
        getRandomReward(itemName)
    end
end

-------------------------------------------------------------
-- Player Job & Information Utilities
-------------------------------------------------------------

local hasGroupFunc = {
    {   framework = QBXExport,
        hasGroup =
            function(group, grade, src)
                local hasJobFlag, duty = false, true
                local playerInfo = GetPlayer(src)
                local jobinfo = playerInfo.job or playerInfo.PlayerData.job
                if jobinfo.name == group then
                    hasJobFlag = true
                    duty = jobinfo.onduty
                    if grade and not (grade <= jobinfo.grade.level) then
                        hasJobFlag = false
                    end
                end
                local ganginfo = playerInfo.gang or playerInfo.PlayerData.gang
                if ganginfo.name == group then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then
                        hasJobFlag = false
                    end
                end
                return hasJobFlag, duty
            end,
    },

    {   framework = QBExport,
        hasGroup =
            function(group, grade, src)
                local hasJobFlag, duty = false, true
                local playerInfo = GetPlayer(src)
                local jobinfo = playerInfo.job or playerInfo.PlayerData.job
                if jobinfo.name == group then
                    hasJobFlag = true
                    duty = jobinfo.onduty
                    if grade and not (grade <= jobinfo.grade.level) then
                        hasJobFlag = false
                    end
                end
                local ganginfo = playerInfo.gang or playerInfo.PlayerData.gang
                if ganginfo.name == group then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then
                        hasJobFlag = false
                    end
                end
                return hasJobFlag, duty
            end,
    },

    {   framework = OXCoreExport,
        hasGroup =
            function(group, grade, src)
                local hasJobFlag, duty = false, true
                if src then
                    local chunk = assert(load(LoadResourceFile('ox_core', ('imports/%s.lua'):format('server')), ('@@ox_core/%s'):format(file)))
                    chunk()
                    local player = Ox.GetPlayer(src)
                    for k, v in pairs(player.getGroups()) do
                        if k == group then hasJobFlag = true end
                    end
                end
                local info = OxPlayer.getGroups()
                for k, v in pairs(info) do
                    if k == group then hasJobFlag = true break end
                end
                return hasJobFlag, duty
            end,
    },

    {   framework = OXCoreExport,
        hasGroup =
            function(group, grade, src)
                local hasJobFlag, duty = false, true
                if src then
                    local chunk = assert(load(LoadResourceFile('ox_core', ('imports/%s.lua'):format('server')), ('@@ox_core/%s'):format(file)))
                    chunk()
                    local player = Ox.GetPlayer(src)
                    for k, v in pairs(player.getGroups()) do
                        if k == group then hasJobFlag = true end
                    end
                end
                local info = OxPlayer.getGroups()
                for k, v in pairs(info) do
                    if k == group then hasJobFlag = true break end
                end
                return hasJobFlag, duty
            end,
    },

    {   framework = ESXExport,
        hasGroup =
            function(group, grade, src)
                local hasJobFlag, duty = false, true

                local playerInfo = GetPlayer(src)
                local info = playerInfo.job
                while not info do
                    info = GetPlayer(src).job
                    Wait(100)
                end
                if info.name == group then
                    hasJobFlag = true
                end

                return hasJobFlag, duty
            end,
    },

    {   framework = RSGExport,
        hasGroup =
            function(group, grade, src)
                local hasJobFlag, duty = false, true
                local playerInfo = GetPlayer(src)
                local jobinfo = playerInfo.job or playerInfo.PlayerData.job
                if jobinfo.name == group then
                    hasJobFlag = true
                    duty = jobinfo.onduty
                    if grade and not (grade <= jobinfo.grade.level) then
                        hasJobFlag = false
                    end
                end
                local ganginfo = playerInfo.gang or playerInfo.PlayerData.gang
                if ganginfo.name == group then
                    hasJobFlag = true
                    if grade and not (grade <= ganginfo.grade.level) then
                        hasJobFlag = false
                    end
                end
                return hasJobFlag, duty
            end,
    },
}


--- Checks if a player has a specific job or gang (and optionally meets a minimum grade).
---
--- @param job string The job or gang name to check.
--- @param source number|nil Optional player source; if nil, checks current player.
--- @param grade number|nil Optional minimum grade level.
--- @return boolean, boolean boolean Returns true and duty status if the check passes; false otherwise.
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
function hasJob(job, source, grade)
    local src = source
    local hasJobFlag, duty = false, true

    for i = 1, #hasGroupFunc do
        local framework = hasGroupFunc[i]
        if isStarted(framework.framework) then
            hasJobFlag, duty = framework.hasGroup(job, grade, src)
            return hasJobFlag, duty
        end
    end
    print("^4ERROR^7: ^2No Core detected for hasJob ^7- ^2Check ^3starter^1.^2lua^7")
end

----------------------------------
---
local getPlayerFunc = {
    {   framework = ESXExport,
        serverSide =
            function(src)
                local Player = {}
                local info = ESX.GetPlayerFromId(src)
                if not info then return {} end
                Player = {
                    name = info.getName(),
                    cash = info.getMoney(),
                    bank = info.getAccount("bank").money,

                    firstname = info.variables.firstName,
                    lastname = info.variables.lastName,

                    source = info.source,
                    job = info.job.name,
                    --jobBoss = info.job.isboss,
                    --gang = info.gang.name,
                    --gangBoss = info.gang.isboss,
                    onDuty = info.job.onDuty,
                    --account = info.charinfo.account,
                    citizenId = info.identifier,
                }
                return Player
            end,

        clientSide =
            function()
                local Player = {}
                local info = ESX.GetPlayerData()
                if not info.firstName then return {} end

                local cash, bank = 0, 0
                for _, v in pairs(info.accounts) do
                    if v.name == "money" then cash = v.money end
                    if v.name == "bank" then bank = v.money end
                end
                Player = {
                    firstname = info.firstName,
                    lastname = info.lastName,
                    name = info.firstName.." "..info.lastName,
                    cash = cash,
                    bank = bank,
                    source = GetPlayerServerId(PlayerId()),
                    job = info.job.name,
                    --jobBoss = info.job.isboss,
                    --gang = info.gang.name,
                    --gangBoss = info.gang.isboss,
                    onDuty = info.job.onDuty,
                    --account = info.charinfo.account,
                    citizenId = info.identifier,
                    isDead = IsEntityDead(PlayerPedId()),
                    isDown = IsPedDeadOrDying(PlayerPedId(), true)
                }
                return Player
            end,
    },

    {   framework = OXCoreExport,
        serverSide =
            function(src)
                local Player = {}
                local file = ('imports/%s.lua'):format('server')
                local import = LoadResourceFile('ox_core', file)
                local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
                chunk()
                local player = Ox.GetPlayer(src)
                if not player then return {} end
                Player = {
                    firstname = player.firstName,
                    lastname = player.lastName,
                    name = ('%s %s'):format(player.firstName, player.lastName),
                    cash = exports[OXInv]:Search(src, 'count', "money"),
                    bank = 0,
                    source = src,
                    --job = OxPlayer.getGroups(),
                    --jobBoss = info.job.isboss,
                    --gang = OxPlayer.getGroups(),
                    --gangBoss = info.gang.isboss,
                    --onDuty = info.job.onduty,
                    --account = info.charinfo.account,
                    citizenId = player.stateId,
                }
                return Player
            end,

        clientSide =
            function()
                local Player = {}
                if not OxPlayer.userId then return {} end
                Player = {
                    firstname = OxPlayer.get("firstName"),
                    lastname = OxPlayer.get("lastName"),
                    name = OxPlayer.get("firstName").." "..OxPlayer.get("lastName"),
                    cash = exports[OXInv]:Search('count', "money"),
                    bank = 0,
                    source = GetPlayerServerId(PlayerId()),
                    job = OxPlayer.getGroups(),
                    --jobBoss = info.job.isboss,
                    gang = OxPlayer.getGroups(),
                    --gangBoss = info.gang.isboss,
                    --onDuty = info.job.onduty,
                    --account = info.charinfo.account,
                    citizenId = OxPlayer.userId,
                    isDead = IsEntityDead(PlayerPedId()),
                    isDown = IsPedDeadOrDying(PlayerPedId(), true)
                }
                return Player
            end,
    },

    {   framework = QBXExport,
        serverSide =
            function(src)
                local Player = {}
                local info = exports[QBXExport]:GetPlayer(src)
                if not info then return {} end
                Player = {
                    firstname = info.PlayerData.charinfo.firstname,
                    lastname = info.PlayerData.charinfo.lastname,
                    name = info.PlayerData.charinfo.firstname.." "..info.PlayerData.charinfo.lastname,
                    cash = exports[OXInv]:Search(src, 'count', "money"),
                    bank = info.Functions.GetMoney("bank"),
                    source = info.PlayerData.source,
                    job = info.PlayerData.job.name,
                    jobBoss = info.PlayerData.job.isboss,
                    jobInfo = info.PlayerData.job,
                    gang = info.PlayerData.gang.name,
                    gangInfo = info.PlayerData.gang,
                    gangBoss = info.PlayerData.gang.isboss,
                    onDuty = info.PlayerData.job.onduty,
                    account = info.PlayerData.charinfo.account,
                    citizenId = info.PlayerData.citizenid,
                    isDead = info.PlayerData.metadata["isdead"],
                    isDown = info.PlayerData.metadata["inlaststand"],
                    charInfo = info.charinfo,
                }
                return Player
            end,

        clientSide =
            function()
                local Player = {}
                local info = exports[QBXExport]:GetPlayerData()
                if not info.charinfo then return {} end
                Player = {
                    firstname = info.charinfo.firstname,
                    lastname = info.charinfo.lastname,
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                    source = info.source,
                    job = info.job.name,
                    jobBoss = info.job.isboss,
                    jobInfo = info.job,
                    gang = info.gang.name,
                    gangBoss = info.gang.isboss,
                    gangInfo = info.gang,
                    onDuty = info.job.onduty,
                    account = info.charinfo.account,
                    citizenId = info.citizenid,
                    isDead = info.metadata["isdead"],
                    isDown = info.metadata["inlaststand"],
                    charInfo = info.charinfo,
                }
                return Player
            end,
    },

    {   framework = QBExport,
        serverSide =
            function(src)
                local Player = {}
                if Core.Functions.GetPlayer(src) then
                    local info = Core.Functions.GetPlayer(src).PlayerData
                    if not info then return {} end
                    Player = {
                        firstname = info.charinfo.firstname,
                        lastname = info.charinfo.lastname,
                        name = info.charinfo.firstname.." "..info.charinfo.lastname,
                        cash = info.money["cash"],
                        bank = info.money["bank"],
                        source = info.source,
                        job = info.job.name,
                        jobBoss = info.job.isboss,
                        jobInfo = info.job,
                        gang = info.gang.name,
                        gangBoss = info.gang.isboss,
                        gangInfo = info.gang,
                        onDuty = info.job.onduty,
                        account = info.charinfo.account,
                        citizenId = info.citizenid,
                        isDead = info.metadata["isdead"],
                        isDown = info.metadata["inlaststand"],
                        charInfo = info.charinfo,
                    }
                end
                return Player
            end,

        clientSide =
            function()
                local Player = {}
                local info = nil
                Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
                if not info.charinfo then return {} end

                Player = {
                    firstname = info.charinfo.firstname,
                    lastname = info.charinfo.lastname,
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                    source = info.source,
                    job = info.job.name,
                    jobBoss = info.job.isboss,
                    jobInfo = info.job,
                    gang = info.gang.name,
                    gangBoss = info.gang.isboss,
                    gangInfo = info.gang,
                    onDuty = info.job.onduty,
                    account = info.charinfo.account,
                    citizenId = info.citizenid,
                    isDead = info.metadata["isdead"],
                    isDown = info.metadata["inlaststand"],
                    charInfo = info.charinfo,
                }
                return Player
            end,
    },

    {   framework = RSGExport,
        serverSide =
            function(src)
                local Player = {}
                if Core.Functions.GetPlayer(src) then
                    local info = Core.Functions.GetPlayer(src).PlayerData
                    if not info then return {} end
                    Player = {
                        firstname = info.charinfo.firstname,
                        lastname = info.charinfo.lastname,
                        name = info.charinfo.firstname.." "..info.charinfo.lastname,
                        cash = info.money["cash"],
                        bank = info.money["bank"],
                        source = info.source,
                        job = info.job.name,
                        jobBoss = info.job.isboss,
                        jobInfo = info.job,
                        gang = info.gang.name,
                        gangBoss = info.gang.isboss,
                        gangInfo = info.gang,
                        onDuty = info.job.onduty,
                        account = info.charinfo.account,
                        citizenId = info.citizenid,
                        isDead = info.metadata["isdead"],
                        isDown = info.metadata["inlaststand"],
                        charInfo = info.charinfo,
                    }
                end
                return Player
            end,

        clientSide =
            function()
                local Player = {}
                local info = nil
                Core.Functions.GetPlayerData(function(PlayerData) info = PlayerData end)
                if not info.charinfo then return {} end

                Player = {
                    firstname = info.charinfo.firstname,
                    lastname = info.charinfo.lastname,
                    name = info.charinfo.firstname.." "..info.charinfo.lastname,
                    cash = info.money["cash"],
                    bank = info.money["bank"],
                    source = info.source,
                    job = info.job.name,
                    jobBoss = info.job.isboss,
                    jobInfo = info.job,
                    gang = info.gang.name,
                    gangBoss = info.gang.isboss,
                    gangInfo = info.gang,
                    onDuty = info.job.onduty,
                    account = info.charinfo.account,
                    citizenId = info.citizenid,
                    isDead = info.metadata["isdead"],
                    isDown = info.metadata["inlaststand"],
                    charInfo = info.charinfo,
                }
                return Player
            end,
    },
}

--- Retrieves basic player information (name, cash, bank, job, etc.) based on the active core/inventory system.
---
--- Can be called server-side (passing a player source) or client-side (for current player).
---
--- @param source number|nil Optional player server ID.
--- @return table A table containing player details.
---
--- @usage
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
    --debugPrint("^6Bridge^7: ^2Getting ^3Player^2 info^7")

    if source then

        for i = 1, #getPlayerFunc do
            local framework = getPlayerFunc[i]
            if isStarted(framework.framework) then
                Player = framework.serverSide(source)
                break
            end
        end

    else

        for i = 1, #getPlayerFunc do
            local framework = getPlayerFunc[i]
            if isStarted(framework.framework) then
                Player = framework.clientSide()
                break
            end
        end

    end
    return Player
end

--- Retrieves all active players within a given radius from the specified coordinates.
---
--- @param coords vector3 The reference coordinates.
--- @param radius number The radius within which to find players.
--- @return table table An array of player IDs.
---
--- @usage
--- ```lua
--- local nearbyPlayers = GetPlayersFromCoords(vector3(100, 200, 30), 20)
--- ```
function GetPlayersFromCoords(coords, radius)
    local players = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local playerCoords = GetEntityCoords(ped)
            if #(coords - playerCoords) <= radius then
                players[#players + 1] = playerId
            end
        end
    end
    return players
end

-------------------------------------------------------------
-- Clothing Script Selection
-------------------------------------------------------------

local wardrobeFunc = {
    {   name = "qb-clothing",
        openWardrobe = function()
            TriggerEvent("qb-clothing:client:OpenMenu")
        end,
    },
    {   name = "esx_skin",
        openWardrobe = function()
            TriggerEvent("esx_skin:openSaveableMenu",
                function()
                    finished = true
                end, function()
                    finished = true
            end)
        end,
    },
    {   name = "illenium-appearance",
        openWardrobe = function()
            exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                if appearance then
                    TriggerServerEvent("illenium-appearance:server:saveAppearance", appearance)
                end
            end, {
                components = true, componentConfig = { masks = true, upperBody = true, lowerBody = true, bags = true, shoes = true, scarfAndChains = true, bodyArmor = true, shirts = true, decals = true, jackets = true },
                props = true, propConfig = { hats = true, glasses = true, ear = true, watches = true, bracelets = true },
                enableExit = true,
            })
        end,
    },
}

--- Opens the clothing customization menu

function openClothing()
    for i = 1, #wardrobeFunc do
        local script = wardrobeFunc[i]
        if isStarted(script.name) then
            script.openWardrobe()
            break
        end
    end
end