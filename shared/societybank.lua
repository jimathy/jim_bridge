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
      • Tgiann-bank
]]

local societyFunc = {
    {   bankName = "qb-banking",
        getAccount =
            function(society)
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
                return exports["qb-banking"]:GetAccountBalance(society)
            end,
        chargeSociety =
            function(society, amount)
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
            end,
        fundSociety =
            function(society, amount)
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
            end,
    },

    {   bankName = "Renewed-Banking",
        getAccount =
            function(society)
                return exports["Renewed-Banking"]:getAccountMoney(society)
            end,
        chargeSociety =
            function(society, amount)
                exports['Renewed-Banking']:removeAccountMoney(society, amount)
            end,
        fundSociety =
            function(society, amount)
                exports['Renewed-Banking']:addAccountMoney(society, amount)
            end,
    },

    {   bankName = "fd_banking",
        getAccount =
            function(society)
                return exports["fd_banking"]:GetAccount(society)
            end,
        chargeSociety =
            function(society, amount)
                exports["fd_banking"]:RemoveMoney(society, amount)
            end,
        fundSociety =
            function(society, amount)
                exports["fd_banking"]:AddMoney(society, amount)
            end,
    },

    {   bankName = "okokBanking",
        getAccount =
            function(society)
                return exports['okokBanking']:GetAccount(society)
            end,
        chargeSociety =
            function(society, amount)
                exports['okokBanking']:RemoveMoney(society, amount)
            end,
        fundSociety =
            function(society, amount)
                exports['okokBanking']:AddMoney(society, amount)
            end,
    },

    {   bankName = "tgiann-bank",
        getAccount =
            function(society)
                if Jobs[society] then
                    return exports["tgiann-bank"]:GetJobAccountBalance(society)
                else
                    return exports["tgiann-bank"]:GetGangAccountBalance(society)
                end
            end,
        chargeSociety =
            function(society, amount)
                if Jobs[society] then
                    exports["tgiann-bank"]:RemoveJobMoney(society, amount)
                else
                    exports["tgiann-bank"]:RemoveGangMoney(society, amount)
                end
            end,
        fundSociety =
            function(society, amount)
                if Jobs[society] then
                    exports["tgiann-bank"]:AddJobMoney(society, amount)
                else
                    exports["tgiann-bank"]:AddGangMoney(society, amount)
                end
            end,
    },
}


--- Retrieves the current balance of a society's bank account.
--- @param society string The identifier of the society.
--- @return number number The current account balance.
--- @usage
--- ```lua
--- local balance = getSocietyAccount("police")
--- print("Police account balance: $"..balance)
--- ```
function getSocietyAccount(society)
    local amount = 0
    if society == nil or society == "none" then return amount end

    for i = 1, #societyFunc do
        local script = societyFunc[i]
        if isStarted(script.bankName) then
            local amount = script.getAccount(society)
            debugPrint("^6Bridge^7: ^3"..script.bankName.."^7: ^2Retrieved account ^7'^6"..society.."^7' ($"..tostring(amount)..")")
            return amount
        end
    end

    print("^1Error^7: ^3GetSocietyAccount^7: ^2No supported banking script found")

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

    for i = 1, #societyFunc do
        local script = societyFunc[i]
        if isStarted(script.bankName) then
            script.chargeSociety(society, amount)
            local newAmount = getSocietyAccount(society)
            debugPrint("^6Bridge^7: ^3"..script.bankName.."^7: ^2Removing $"..amount.." from account '^6"..society.."^7' ($"..tostring(newAmount)..")")
            return
        end
    end

    print("^1Error^7: ^3ChargeSociety^7: ^2No supported banking script found")
end

--- Adds funds to a society's bank account.
--- @param society string The identifier of the society.
--- @param amount number The amount of money to add.
--- @usage
--- ```lua
--- fundSociety("police", 500)
--- ```
function fundSociety(society, amount)

    for i = 1, #societyFunc do
        local script = societyFunc[i]
        if isStarted(script.bankName) then
            script.fundSociety(society, amount)
            local newAmount = getSocietyAccount(society)
            debugPrint("^6Bridge^7: ^3"..script.bankName.."^7: ^2Adding ^7$"..amount.." ^2to account ^7'^6"..society.."^7' ($"..tostring(newAmount)..")")
            return
        end
    end

    print("^1Error^7: ^3FundSociety^7: ^2No supported banking script found")
end


-- other
if isStarted("esx_society") then
    createCallback(getScript()..":getESXSocietyAccount", function(source, society)
        -- Example query – adjust table/field names to match your esx_society implementation.
        local result = MySQL.scalar.await('SELECT money FROM society_money WHERE society = ?', { society })
        return result or 0
    end)
end