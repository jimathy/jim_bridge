
function chargeSociety(society, amount)
	local bankScript, newAmount = "", 0
    if isStarted("Renewed-Banking") then
        bankScript = "Renewed-Banking"
        exports['Renewed-Banking']:removeAccountMoney(society, amount)

    elseif isStarted("qb-banking") then
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
        debugPrint("^6Bridge^7: ^3"..bankScript.."^7: ^2Removing ^7$"..amount.." ^2from account ^7'^6"..society.."^7' ($"..newAmount..")")
    end
end

function fundSociety(society, amount)
    local bankScript, newAmount = "", 0
    if isStarted("Renewed-Banking") then
        bankScript = "Renewed-Banking"
        exports['Renewed-Banking']:addAccountMoney(society, amount)
        newAmount = exports["Renewed-Banking"]:getAccountMoney(society)

    elseif isStarted("qb-banking") then
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
        exports["qb-banking"]:AddMoney(society, amount)

    elseif isStarted("fd_banking") then
        bankScript = "fd_banking"
        exports.fd_banking:AddMoney(society, amount)

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

function getSocietyAccount(society)

    local bankScript, amount = "", 0
    if isStarted("Renewed-Banking") then
        bankScript = "Renewed-Banking"
        amount = exports["Renewed-Banking"]:getAccountMoney(society)

    elseif isStarted("qb-banking") then
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
        amount = exports["qb-banking"]:GetAccountBalance(society)

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