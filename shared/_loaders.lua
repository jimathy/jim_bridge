--- Executes a function when the player character is loaded into the game.
---
--- This function sets up event listeners for player loading based on the game framework detected (e.g., QB, ESX, OX).
---
--- If `onStart` is `true`, it will also attempt to execute the function on resource start after ensuring the player is logged in. (Helpful for debugging)
---
--- @param func function The function to execute when the player is loaded.
--- @param onStart boolean (optional) If `true`, the function will also execute on resource start. Default is `false`.
---
--- @usage
--- ```lua
--- onPlayerLoaded(function()
---     -- Your code here
--- end, true)
--- ```
function onPlayerLoaded(func, onStart)
    local onPlayerName = ""
    local loaded = false
    if onStart then
        onResourceStart(function()
            if not LocalPlayer.state.isLoggedIn then
                Wait(3000)
                if not LocalPlayer.state.isLoggedIn then -- If the player is not logged in after waiting, skip execution
                    return
                end
            end
            loaded = true -- Mark as already loaded
            debugPrint("^6Bridge^7: ^2Loading ^3onResourceStart^7() ^2through ^3onPlayerLoaded^7()")
            Wait(2000)
            func()
        end, true)
    end
    if not loaded then
        local tempFunc = function()
            debugPrint("^6Bridge^7: ^2Executing ^3onPlayerLoaded^7()")
            func()
        end
        if isStarted(QBExport) or isStarted(QBXExport) then onPlayerName = QBExport
            AddEventHandler('QBCore:Client:OnPlayerLoaded', tempFunc)
        elseif isStarted(ESXExport) then onPlayerName = ESXExport
            AddEventHandler('esx:playerLoaded', tempFunc)
        elseif isStarted(OXCoreExport) then onPlayerName = OXCoreExport
            AddEventHandler('ox:playerLoaded', tempFunc)
        end
        if onPlayerName ~= "" then
            debugPrint("^6Bridge^7: ^2Registering ^3onPlayerLoaded^2 with ^7"..onPlayerName)
        else
            print("^4ERROR^7: ^2No Core detected for onPlayerLoaded ^7- ^2Check ^3exports^1.^2lua^7")
        end
    end
end

--trying to add unload functions for when players switch ped
function onPlayerUnload(func)
    AddEventHandler('QBCore:Client:OnPlayerUnload', function()
        func()
    end)
    AddEventHandler('ox:playerLogout', function()
        func()
    end)
end


--- Executes a function when the resource starts.
---
--- This function wraps the `onResourceStart` event, allowing you to execute code when the resource starts.
---
--- @param func function The function to execute on resource start.
--- @param thisScript boolean (optional) If `true`, only runs the function when this resource starts. Default is `true`.
---
--- @usage
--- ```lua
--- onResourceStart(function()
---     -- Your code here
--- end, true)
--- ```
function onResourceStart(func, thisScript)
    debugPrint("^6Bridge^7: ^2Registering ^3onResourceStart^2")
    AddEventHandler('onResourceStart', function(resourceName)
        if getScript() == resourceName and (thisScript or true) then
            func()
        end
    end)
end

--- Executes a function when the resource stops.
---
--- This function wraps the `onResourceStop` event, allowing you to execute code when the resource stops.
---
--- @param func function The function to execute on resource stop.
--- @param thisScript boolean (optional) If `true`, only runs the function when this resource stops. Default is `true`.
---
--- @usage
--- ```lua
--- onResourceStop(function()
---     -- Cleanup code here
--- end, true)
--- ```
function onResourceStop(func, thisScript)
    debugPrint("^6Bridge^7: ^2Registering ^3onResourceStop^2")
    AddEventHandler('onResourceStop', function(resourceName)
        if getScript() == resourceName and (thisScript or true) then
            func()
        end
    end)
end

--- Waits until the player is logged in before continuing execution.
---
--- This function blocks execution until `LocalPlayer.state.isLoggedIn` is `true`.
---
---@usage
--- ```lua
--- waitForLogin()
--- ```
function waitForLogin()
    while not LocalPlayer.state.isLoggedIn do
        debugPrint("Waiting")
        Wait(100)
    end
end