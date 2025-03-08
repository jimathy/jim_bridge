--[[
    Society Banking Module
    ------------------------
    This module provides functions to interact with society bank accounts across
    different banking systems. Supported systems include:
      • qb-banking
      • esx_society *testing*
      • Renewed-Banking
      • fd_banking
      • okokBanking
]]

--- Retrieves the current balance of a society's bank account.
--- @param society string The identifier of the society.
--- @return number number The current account balance.
--- @usage
--- ```lua
--- local balance = getSocietyAccount("police")
--- print("Police account balance: $"..balance)
--- ```
function getSocietyAccount(society)
    local bankScript, amount = "", 0
    if society == nil or society == "none" then return amount end

    if isStarted("qb-banking") then
        bankScript = "qb-banking"
        if not exports["qb-banking"]:GetAccount(society) then
            if Jobs[society] then
                print("^6Bridge^7: ^2Making new bank account in ^7'^3qb-banking^7' ^2for ^7'^3"..society.."^7'")
                exports["qb-banking"]:CreateJobAccount(society, 0)
                Wait(150)
            elseif Gangs[society] then
                print("^6Bridge^7: ^2Making new bank account in ^7'^3qb-banking^7' ^2for ^7'^3"..society.."^7'")
                exports["qb-banking"]:CreateGangAccount(society, 0)
                Wait(150)
            end
        end
        amount = exports["qb-banking"]:GetAccountBalance(society)

    --elseif isStarted("esx_society") then
    --    bankScript = "esx_society"
    --    -- Since esx_society does not have a native client export for retrieving money,
    --    -- we use a server callback to get the final amount.
    --    amount = triggerCallback(getScript()..":getESXSocietyAccount", society) or 0

    elseif isStarted("Renewed-Banking") then
        bankScript = "Renewed-Banking"
        amount = exports["Renewed-Banking"]:getAccountMoney(society)

    elseif isStarted("fd_banking") then
        bankScript = "fd_banking"
        amount = exports["fd_banking"]:GetAccount(society)

    elseif isStarted("okokBanking") then
        bankScript = "okokBanking"
        amount = exports['okokBanking']:GetAccount(society)
    end

    if bankScript == "" then
        print("^1Error^7: ^3GetSocietyAccount^7: ^2No supported banking script found")
    else
        debugPrint("^6Bridge^7: ^3"..bankScript.."^7: ^2Retrieved account ^7'^6"..society.."^7' ($"..amount..")")
    end

    return amount
end

--- Deducts funds from a society's bank account.
--- @param society string The identifier of the society.
--- @param amount number The amount of money to remove.
--- @usage
--- ```lua
--- chargeSociety("police", 1000)
--- ```
function chargeSociety(society, amount)
    local bankScript, newAmount = "", 0

    if isStarted("qb-banking") then
        bankScript = "qb-banking"
		if not exports["qb-banking"]:GetAccount(society) then
            if Jobs[society] then
                print("^6Bridge^7: ^2Making new bank account in ^7'^3qb-banking^7' ^2for ^7'^3"..society.."^7'")
                exports["qb-banking"]:CreateJobAccount(society, 0) Wait(150) -- make new account if return "null"
            elseif Gangs[society] then
                print("^6Bridge^7: ^2Making new bank account in ^7'^3qb-banking^7' ^2for ^7'^3"..society.."^7'")
                exports["qb-banking"]:CreateGangAccount(society, 0) Wait(150) -- make new account if return "null"
            end
		end
        exports["qb-banking"]:RemoveMoney(society, amount)
    --elseif isStarted("esx_society") then
    --    bankScript = "esx_society"
    --    TriggerEvent("esx_society:withdrawMoney", society, amount)

    elseif isStarted("Renewed-Banking") then
        bankScript = "Renewed-Banking"
        exports['Renewed-Banking']:removeAccountMoney(society, amount)

    elseif isStarted("fd_banking") then
        bankScript = "fd_banking"
        exports["fd_banking"]:RemoveMoney(society, amount)


    elseif isStarted("okokBanking") then
        bankScript = "okokBanking"
        exports['okokBanking']:RemoveMoney(society, amount)

    end

    if bankScript == "" then
        print("^1Error^7: ^3ChargeSociety^7: ^2No supported banking script found")
    else
        newAmount = getSocietyAccount(society)
        debugPrint("^6Bridge^7: ^3"..bankScript.."^7: ^2Removing $"..amount.." from account '^6"..society.."^7' ($"..newAmount..")")
    end
end

--- Adds funds to a society's bank account.
--- @param society string The identifier of the society.
--- @param amount number The amount of money to add.
--- @usage
--- ```lua
--- fundSociety("police", 500)
--- ```
function fundSociety(society, amount)
    local bankScript, newAmount = "", 0


    if isStarted("qb-banking") then
        bankScript = "qb-banking"
        if not exports["qb-banking"]:GetAccount(society) then
            if Jobs[society] then
                print("^6Bridge^7: ^2Making new bank account in ^7'^3qb-banking^7' ^2for ^7'^3"..society.."^7'")
                exports["qb-banking"]:CreateJobAccount(society, 0)
                Wait(150)
            elseif Gangs[society] then
                print("^6Bridge^7: ^2Making new bank account in ^7'^3qb-banking^7' ^2for ^7'^3"..society.."^7'")
                exports["qb-banking"]:CreateGangAccount(society, 0)
                Wait(150)
            end
        end
        exports["qb-banking"]:AddMoney(society, amount)

    --elseif isStarted("esx_society") then
    --    bankScript = "esx_society"
    --    -- Use the esx_society event to deposit money.
    --    TriggerServerEvent('esx_society:depositMoney', society, amount)
    --    -- Use callback to return the updated balance.
    --    newAmount = triggerCallback(getScript()..":getESXSocietyAccount", society) or 0

    elseif isStarted("Renewed-Banking") then
            bankScript = "Renewed-Banking"
            exports['Renewed-Banking']:addAccountMoney(society, amount)
            newAmount = exports["Renewed-Banking"]:getAccountMoney(society)
    elseif isStarted("fd_banking") then
        bankScript = "fd_banking"
        exports["fd_banking"]:AddMoney(society, amount)

    elseif isStarted("okokBanking") then
        bankScript = "okokBanking"
        exports['okokBanking']:AddMoney(society, amount)

    end

    if bankScript == "" then
        print("^1Error^7: ^3FundSociety^7: ^2No supported banking script found")
    else
        newAmount = getSocietyAccount(society)
        debugPrint("^6Bridge^7: ^3"..bankScript.."^7: ^2Adding ^7$"..amount.." ^2to account ^7'^6"..society.."^7' ($"..newAmount..")")
    end
end


-- other
if isStarted("esx_society") then
    createCallback(getScript()..":getESXSocietyAccount", function(source, society)
        -- Example query – adjust table/field names to match your esx_society implementation.
        local result = MySQL.scalar.await('SELECT money FROM society_money WHERE society = ?', { society })
        return result or 0
    end)
end