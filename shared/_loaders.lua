--[[
    Player & Resource Event Utility Functions
    -------------------------------------------
    This module provides functions to:
      • Execute code when the player character is loaded or unloaded.
      • Execute code on resource start and stop.
      • Wait for the player to be logged in before proceeding.
]]

local onLoadLast = {} -- keyed by tostring(func)

local function _debouncedRun(func)
    local key  = tostring(func)
    local now  = GetGameTimer()
    local last = onLoadLast[key] or -1e12

    if (now - last) < 5000 then
        debugPrint(("^6Bridge^7 ^3onPlayerLoaded^7 skipped — cooldown %dms remaining"):format(5000 - (now - last)))
        return
    end

    onLoadLast[key] = now
    CreateThread(function()
        Wait(2000) -- keep your small delay
        debugPrint("^6Bridge^7: ^2Executing onPlayerLoaded callback")
        func()
    end)
end

local frameworkLoadFunc = {
    {   framework = Exports.QBXExport,
        onPlayerLoaded =
            function(func)
                RegisterNetEvent('QBCore:Client:OnPlayerLoaded', func)
            end,
        onPlayerUnload =
            function(func)
                RegisterNetEvent('QBCore:Client:OnPlayerUnload', func)
            end,
        waitforLogin =
            function(timeout)
                local startTime = GetGameTimer()
                while not LocalPlayer.state.isLoggedIn and (GetGameTimer() - startTime) < timeout do
                    Wait(100)
                end
                return LocalPlayer.state.isLoggedIn
            end,
    },

    {   framework = Exports.QBExport,
        onPlayerLoaded =
            function(func)
                RegisterNetEvent('QBCore:Client:OnPlayerLoaded', func)
            end,
        onPlayerUnload =
            function(func)
                RegisterNetEvent('QBCore:Client:OnPlayerUnload', func)
            end,
        waitforLogin =
            function(timeout)
                local startTime = GetGameTimer()
                while not LocalPlayer.state.isLoggedIn and (GetGameTimer() - startTime) < timeout do
                    Wait(100)
                end
                return LocalPlayer.state.isLoggedIn
            end,
    },

    {   framework = Exports.ESXExport,
        onPlayerLoaded =
            function(func)
                RegisterNetEvent("esx:playerLoaded", function()
                    -- make sure shared has loaded (because sql)
                    if waitForSharedLoad() then func() end
                end)
            end,
        onPlayerUnload =
            function(func)
                RegisterNetEvent("esx:onPlayerLogout", func)
            end,
        waitforLogin =
            function(timeout)
                local startTime = GetGameTimer()
                while (GetGameTimer() - startTime) < timeout do
                    local playerData = ESX.GetPlayerData()
                    if playerData and playerData.job then
                        return true
                    end
                    Wait(100)
                end
            end,
    },

    {   framework = Exports.OXCoreExport,
        onPlayerLoaded =
            function(func)
                RegisterNetEvent('ox:playerLoaded', func)
            end,
        onPlayerUnload =
            function(func)
                RegisterNetEvent('ox:playerLogout', func)
            end,
        waitforLogin =
            function(timeout)
                if OxPlayer["stateId"] then
                    return true
                end
                while not OxPlayer["stateId"] do
                    Wait(1000)
                    if OxPlayer.get["stateId"] then
                        return true
                    end
                end
            end,
    },

    {   framework = Exports.RSGExport,
        onPlayerLoaded =
            function(func)
                RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', func)
            end,
        onPlayerUnload =
            function(func)
                RegisterNetEvent('RSGCore:Client:OnPlayerUnload', func)
            end,
        waitforLogin =
            function(timeout)
                local startTime = GetGameTimer()
                while not LocalPlayer.state.isLoggedIn and (GetGameTimer() - startTime) < timeout do
                    Wait(100)
                end
                return LocalPlayer.state.isLoggedIn
            end,
    },

    {   framework = Exports.VorpExport,
        onPlayerLoaded =
            function(func)
                RegisterNetEvent('vorp_core:Client:OnPlayerSpawned', func)
            end,
        onPlayerUnload =
            function(func)
                --??
            end,
        waitforLogin =
            function(timeout)
                local startTime = GetGameTimer()
                while not LocalPlayer.state.IsInSession and (GetGameTimer() - startTime) < timeout do
                    Wait(100)
                end
                return LocalPlayer.state.IsInSession
            end,
    },
}

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
    if onStart then
        onResourceStart(function()
            if not waitForLogin() then return end
            debugPrint("^6Bridge^7: ^3onResourceStart^7()^2 routed through ^3onPlayerLoaded^7()")
            _debouncedRun(func)
        end, true)
    end

    local handler = function()
        _debouncedRun(func)
    end

    for i = 1, #frameworkLoadFunc do
        local data = frameworkLoadFunc[i]
        jsonPrint(data)
        if isStarted(data.framework) then
            debugPrint("^6Bridge^7: ^2Registering ^3"..data.framework.." ^5onPlayerLoaded^7()")
            data.onPlayerLoaded(handler)
            return
        end
    end
    print("^1ERROR^7: ^1No supported core detected for onPlayerLoaded - Check starter.lua^7")
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
    for i = 1, #frameworkLoadFunc do
        local data = frameworkLoadFunc[i]
        if isStarted(data.framework) then
            debugPrint("^6Bridge^7: ^2Registering ^3"..data.framework.." ^5onPlayerUnload^7()")
            data.onPlayerUnload(func)
            return
        end
    end
    print("^1ERROR^7: ^1No supported core detected for onPlayerUnload - Check starter.lua^7")
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
local hasPrinted = false
function onResourceStart(func, thisScript)
    debugPrint("^6Bridge^7: ^2Registering ^3onResourceStart^7()")
    AddEventHandler('onResourceStart', function(resourceName)
        if getScript() == resourceName and (thisScript or true) then
            if waitForSharedLoad() then
                if not hasPrinted then
                    debugPrint("^6Bridge^7: ^2Shared Load Detected^7.")
                    hasPrinted = true
                end
                func(resourceName)
            end
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
            func(resourceName)
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
    for i = 1, #frameworkLoadFunc do
        local data = frameworkLoadFunc[i]
        if isStarted(data.framework) then
            debugPrint("^6Bridge^7: ^2Waiting for ^3"..data.framework.."^2 player login^7.")
            local result = data.waitforLogin(10000)
            if result == true then
                debugPrint("^6Bridge^7: ^3"..data.framework.."^2 Player Login Detected^7.")
            else
                print("^4Error^7: ^2Timeout reached while waiting for player login^7.")
            end
            return result
        end
    end
end

local messageShown = false
function waitForSharedLoad()
    local timeout = GetGameTimer() + 900000 -- 15 minutes max wait (had to up this from 2 minutes because of slow servers)
    local loop = 0

    while ((not Jobs or not next(Jobs)) or
        (not Items or not next(Items)) or
        (not Vehicles or not next(Vehicles))
    ) and (timeout and GetGameTimer() < timeout) do
        if loop >= 3 and not messageShown then
            if (not Jobs or not next(Jobs)) then
                print("^4Debug^7: ^2Waiting for ^7Jobs^2 to be loaded")
            end
            if (not Items or not next(Items)) then
                print("^4Debug^7: ^2Waiting for ^7Items^2 to be loaded")
            end
            if (not Vehicles or not next(Vehicles)) then
                print("^4Debug^7: ^2Waiting for ^7Vehicles^2 to be loaded")
            end
            messageShown = true
        end
        Wait(1000)

        loop += 1
    end

    if Jobs and Items and Vehicles then
        debugPrint("^6Bridge^7: ^2Jobs, Items, and Vehicles Loaded^7.")
        return true
    else
        print("^4Error^7: ^1Timeout reached while waiting for shared load^7.")
        return false
    end
end