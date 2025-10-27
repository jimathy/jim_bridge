-------------------------------------------------------------
-- Exploit Auth System
-------------------------------------------------------------

forceDisableExplotProtection = false -- dangerous, this allows exploits
AuthEvent = nil
currentToken = nil
if isServer() then

    local excludeRes = {
        [Exports.QBExport] = true,
        [Exports.ESXExport] = true,
        [Exports.VorpExport] = true,
    }

    local AuthEvent = getScript()..":"..keyGen()..keyGen()..keyGen()..keyGen()..":"..keyGen()..keyGen()..keyGen()..keyGen()
    validTokens = validTokens or {}

    createCallback(AuthEvent, function(source)
        local src = source
        local token = keyGen()..keyGen()..keyGen()..keyGen()  -- Use a secure random generator here
        local invokingRes = GetInvokingResource()

        debugPrint(invokingRes)
        if invokingRes and invokingRes ~= getScript() and not excludeRes[invokingRes] then
            debugPrint("^1Error^7: ^1Possible exploit^7, ^1vital function was called from an external resource^7")
            return  ""
        end
        debugPrint("^1Auth^7:^2 Player Source^7: "..src.." ^2requested new token^7:", token)
        validTokens[src] = token
        timeOutAuth(validTokens[src], src) -- Give script 10 seconds, then clear token
        return token
    end)

    function timeOutAuth(token, src)
        local token = token
        SetTimeout(10000, function()
            if token == validTokens[src] then
                print("^1--------------------------------------------^7")
                print("^7Clearing token for player ^1"..src.."^7", token)
                print("^7This shouldn't happen unless a token has been called by a player or script and it hasn't been used")
                print("^1--------------------------------------------^7")
            end
        end)
    end

    RegisterNetEvent(getScript()..":clearAuthToken", function()
        local src = source
        debugPrint("^1Auth^7: ^2Manually removing token for Player Source^7:", src, validTokens[src])
        validTokens[src] = nil
    end)

    receivedEvent = {}
    authCooldown = {}

    createCallback(getScript()..":callback:GetAuthEvent", function(source)
        local src = source
        local invokingRes = GetInvokingResource()

        if invokingRes and invokingRes ~= getScript() and not excludeRes[invokingRes] then
            debugPrint("^1Error^7: ^1Possible exploit^7, ^1vital callback was called from an external resource^7")
            return ""
        end

        if authCooldown[src] then
            debugPrint("^1Auth^7: ^3Cooldown active^7 for Player ^1"..src.."^7, ignoring additional auth request")
            return AuthEvent
        end

        debugPrint("^1Auth^7: ^2Player Source^7: "..src.." ^2requested ^3AuthEvent^7", AuthEvent)

        authCooldown[src] = true
        SetTimeout(60000, function() -- 1 minute cooldown
            authCooldown[src] = nil
        end)

        if not receivedEvent[src] then
            receivedEvent[src] = true
            return AuthEvent
        else
            print("^1Auth^7: ^1Player ^7"..src.." ^1tried to request auth token more than once^7")
            return ""
        end
    end)

    RegisterNetEvent(getScript()..":clearAuthEventRequest", function()
        local src = source
        debugPrint("^1Auth^7: ^2Manually clearing Auth Event for Player Source^7:", src, AuthEvent)
        receivedEvent[src] = nil
    end)

    -- Multiuse function to check if the generated client token is valid
    function checkToken(src, token, genType, name)
        if forceDisableExplotProtection == true then return true end

        if token == nil then
            debugPrint("^1Auth^7: ^1No token recieved^7")
            if genType == "stash" then
                dupeWarn(src, name, "^1Auth Error^7: ^3"..src.." ^1create a stash ^7"..name.." ^1without an auth token^7")
            elseif genType == "item" then
                dupeWarn(src, name, "^1Auth Error^7: ^3"..src.." ^1attempted to spawn an item ^7"..name.." ^1without an auth token^7")
            end
            return false
        else
            debugPrint("^1Auth^7: ^2Auth token received^7, ^2checking against server cache^7..")
            if token ~= validTokens[src] then
                debugPrint("^1Auth^7: ^1Tokens don't match! ^7", token, validTokens[src])
                if genType == "stash" then
                    dupeWarn(src, name, "^1Auth Error^7: ^3"..src.." ^1create a stash ^7"..name.." ^1with an incorrect auth token^7")
                elseif genType == "item" then
                    dupeWarn(src, name, "^1Auth Error^7: ^3"..src.." ^1attempted to spawn an item ^7"..name.." ^1with an incorrect auth token^7")
                end
                return false
            else
                debugPrint("^1Auth^7: ^2Client and Server Auth tokens match^7!", token, validTokens[src])
                validTokens[src] = nil
                return true
            end
        end
    end
else
    onPlayerLoaded(function()
        debugPrint("^1Auth^7: ^2Requesting ^3Auth Event^7")
        AuthEvent = triggerCallback(getScript()..":callback:GetAuthEvent")
    end, true)

    onPlayerUnload(function()
        debugPrint("^1Auth^7: ^2Clearing Auth Event^7")
        TriggerServerEvent(getScript()..":clearAuthEventRequest")
    end, true)
end

function distExploitCheck(table, src)
    if forceDisableExplotProtection == true then return true end
    if not table then
        print("^1Error^7: ^1This wasn^7'^1t reigstered correctly or this is an exploit attempt^1")
        return false
    end

    local maxDist = 10.0
    local nearestDist = 999999.0
    local nearestCoords = nil

    local ped = src and GetPlayerPed(src) or PlayerPedId()
    local srcCoords = GetEntityCoords(ped)

    for i = 1, #table do

        local dist2d = #(table[i].xy - srcCoords.xy)

        -- Track the nearestDist
        if dist2d < nearestDist then
            nearestDist = dist2d
            nearestCoords = table[i]
        end

        if dist2d <= maxDist then
            debugPrint("^1Found location^7: ^3"..nearestDist.." ^7away from player - "..formatCoord(nearestCoords))
            return true
        end
    end

    print(src and ("^1Src ^3"..src.." ") or "", "^1Tried to open a registered shop/stash from over the distance limit^7")
    print("^1Nearest Possible Location^7: ^3"..nearestDist.." ^7away from player - "..formatCoord(nearestCoords))
    return false

end