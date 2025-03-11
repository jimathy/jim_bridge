--[[
    Player & Resource Event Utility Functions
    -------------------------------------------
    This module provides functions to:
      • Execute code when the player character is loaded or unloaded.
      • Execute code on resource start and stop.
      • Wait for the player to be logged in before proceeding.
]]

-------------------------------------------------------------
-- Player Loaded and Unloaded Events
-------------------------------------------------------------

--- Executes a function when the player character is loaded.
--- If onStart is true, the function will also run on resource start (after ensuring the player is logged in).
---
--- @param func function The function to execute when the player is loaded.
--- @param onStart boolean (optional) If true, also execute on resource start. Default is false.
--- @usage
--- ```lua
--- onPlayerLoaded(function()
---     print("Player logged in")
---     -- Your initialization code here.
--- end, true)
--- ```
function onPlayerLoaded(func, onStart)
    local onPlayerFramework = ""
    local loaded = false

    if onStart then
        onResourceStart(function()
            if not waitForLogin() then return end

            loaded = true
            debugPrint("^6Bridge^7: ^3onResourceStart^7()^2 executed through ^3onPlayerLoaded^7()")
            Wait(2000)
            func()
        end, true)
    end

    if not loaded then
        local tempFunc = function()
            debugPrint("^6Bridge^7: ^2Executing onPlayerLoaded")
            func()
        end

        if isStarted(QBExport) or isStarted(QBXExport) then
            onPlayerFramework = QBExport
            AddEventHandler('QBCore:Client:OnPlayerLoaded', tempFunc)
        elseif isStarted(ESXExport) then
            onPlayerFramework = ESXExport
            AddEventHandler('esx:playerLoaded', tempFunc)
        elseif isStarted(OXCoreExport) then
            onPlayerFramework = OXCoreExport
            AddEventHandler('ox:playerLoaded', tempFunc)
        end

        if onPlayerFramework ~= "" then
            debugPrint("^6Bridge^7: ^2Registering ^3onPlayerLoaded^7()^2 with ^3" .. onPlayerFramework.."^7")
        else
            print("^4ERROR^7: No supported core detected for onPlayerLoaded - Check starter.lua")
        end
    end
end

--- Executes a function when the player character is unloaded.
--- @param func function The function to execute when the player unloads.
--- @usage
--- ```lua
--- onPlayerUnload(function()
---     print("Player has logged out of their character")
---     -- Your cleanup code here.
--- end)
--- ```
function onPlayerUnload(func)
    AddEventHandler('QBCore:Client:OnPlayerUnload', function() func() end)
    AddEventHandler('ox:playerLogout', function() func() end)

    --AddEventHandler('esx:playerLogout', function() func() end)
    -- ^ Only server side for now, need a way to send it to client if not already available
end

-------------------------------------------------------------
-- Resource Start and Stop Events
-------------------------------------------------------------

--- Executes a function when the resource starts.
--- @param func function The function to execute.
--- @param thisScript boolean (optional) If true, only runs when this resource starts (default true).
--- @usage
--- ```lua
--- onResourceStart(function()
---     print("Script ensured")
---     -- Initialization code on resource start.
--- end, true)
--- ```
function onResourceStart(func, thisScript)
    debugPrint("^6Bridge^7: Registering ^3onResourceStart^7()")
    AddEventHandler('onResourceStart', function(resourceName)
        if getScript() == resourceName and (thisScript or true) then
            func()
        end
    end)
end

--- Executes a function when the resource stops.
--- @param func function The function to execute.
--- @param thisScript boolean (optional) If true, only runs when this resource stops (default true).
--- @usage
--- ```lua
--- onResourceStop(function()
---     -- Cleanup code here.
--- end, true)
--- ```
function onResourceStop(func, thisScript)
    debugPrint("^6Bridge^7: ^2Registering ^3onResourceStop^7()")
    AddEventHandler('onResourceStop', function(resourceName)
        if getScript() == resourceName and (thisScript or true) then
            func()
        end
    end)
end

-------------------------------------------------------------
-- Wait for Login
-------------------------------------------------------------

--- Blocks execution until the player is logged in.
--- @usage
--- waitForLogin()
function waitForLogin()
    local timeout = 10000  -- 10 seconds in milliseconds
    local startTime = GetGameTimer()
    local loggedIn = false

    if isStarted(ESXExport) then
        debugPrint("^6Bridge^7: ^3ESX waitForLogin^7() ^2running^7")
        while (GetGameTimer() - startTime) < timeout do
            local playerData = ESX.GetPlayerData()
            if playerData and playerData.job then
                loggedIn = true
                break
            end
            Wait(100)
        end
    elseif isStarted(OXCoreExport) then
        if OxPlayer["stateId"] then
            loggedIn = true
        end
        while not OxPlayer["stateId"] do
            Wait(1000)
            debugPrint("Waiting for stateId to class as logged in")
            if OxPlayer.get["stateId"] then
                loggedIn = true
                break
            end
        end
    else
        -- For other frameworks, use LocalPlayer.state.isLoggedIn.
        while not LocalPlayer.state.isLoggedIn and (GetGameTimer() - startTime) < timeout do
            Wait(100)
        end
        loggedIn = LocalPlayer.state.isLoggedIn
    end

    if not loggedIn then
        print("^4Error^7: ^2Timeout reached while waiting for player login^7.")
        return false
    else
        debugPrint("^6Bridge^7: ^2Player Login Detected^7.")
        return true
    end
end


--local OxPlayer = Ox.GetPlayer()
--jsonPrint(OxPlayer)

