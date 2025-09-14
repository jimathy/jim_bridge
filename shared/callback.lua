local CALLBACK_RETRIES    = 0

-- Internal: await a callback with a timeout
local function awaitWithTimeout(registerFn, timeoutMs)
    local p = promise.new()
    local finished = false

    registerFn(function(result)
        if finished then return end
        finished = true
        p:resolve(result)
    end)

    -- timeout watchdog
    CreateThread(function()
        Wait(5000)
        if not finished then
            finished = true
            p:reject('timeout')
        end
    end)

    local ok, res = pcall(function() return Citizen.Await(p) end)
    if ok then return res, nil end
    return nil, res
end


--- Registers a callback function with the appropriate framework.
---
--- This function checks which framework is started (e.g., OX, QB, ESX) and registers the callback accordingly.
--- It adapts the callback function to match the expected signature for the framework.
---
---@param callbackName string The name of the callback to register.
---@param funct function The function to be called when the callback is triggered.
---
---@usage
--- ```lua
--- local table = { ["info"] = "HI" }
--- createCallback('myCallback', function(source, ...)
---     return table
--- end)
---
--- createCallback("callback:checkVehicleOwned", function(source, plate)
--- 	local result = isVehicleOwned(plate)
--- 	if result then
---         return true
---      else
---         return false
---     end
--- end)
--- ```
function createCallback(callbackName, funct)
    if isServer() then
        if isStarted(OXLibExport) then
            debugPrint("^6Bridge^7: ^2Registering ^4"..OXLibExport.." ^3Callback^7:", callbackName)
            lib.callback.register(callbackName, funct)
        else
            local adaptedFunction = function(source, cb, ...)
                local result = funct(source, ...)
                cb(result)
            end

            if isStarted(QBExport) then
                debugPrint("^6Bridge^7: ^2Registering ^4"..QBExport.." ^3Callback^7:", callbackName)
                Core = Core or exports[QBExport]:GetCoreObject()
                Core.Functions.CreateCallback(callbackName, adaptedFunction)
            elseif isStarted(VorpExport) then
                debugPrint("^6Bridge^7: ^2Registering ^4"..VorpExport.." ^3Callback^7:", callbackName)
                Core = Core or exports.vorp_core:GetCore()
                Core.Callback.Register(callbackName, adaptedFunction)
            elseif isStarted(ESXExport) then
                debugPrint("^6Bridge^7: ^2Registering ^4"..ESXExport.." ^3Callback^7:", callbackName)
                ESX.RegisterServerCallback(callbackName, adaptedFunction)
            else
                print("^1ERROR^7: ^1Can't find any supported framework to register callback with^7: "..callbackName)
            end
        end
    end
end

--- Triggers a server callback and returns the result.
---
--- This function triggers a server callback using the appropriate framework's method and awaits the result.
---
---@param callbackName string The name of the callback to trigger.
---@param ... any Additional arguments to pass to the callback.
---
---@return any any The result returned by the callback function.
---@return string string The error/success message returned by the callback function.
---
---@usage
--- ```lua
--- local result = triggerCallback('myCallback')
--- jsonPrint(result)
---
--- local result = triggerCallback("callback:checkVehicleOwned", plate)
--- print(result)
--- ```
function triggerCallback(callbackName, ...)
    debugPrint("^6Bridge^7: ^2Triggering ^3Callback^7:", callbackName)
    local args = {...}

    if isStarted(OXLibExport) then
        local ok, res = pcall(function()
            return lib.callback.await(callbackName, false, table.unpack(args))
        end)
        if ok then return res, "nil" end
        return nil, tostring(res)
    end

    local attempts = 0
    local lastErr

    repeat
        attempts = attempts + 1

        if isStarted(QBExport) then
            local res, err = awaitWithTimeout(function(cb)
                Core.Functions.TriggerCallback(callbackName, cb, table.unpack(args))
            end, 5000)
            if res ~= nil then return res, "nil" end
            lastErr = err
            debugPrint(("^6Bridge^7: ^3Callback^7 %s ^1failed^7 (QB) attempt %d: %s"):format(callbackName, attempts, tostring(err)))

        elseif isStarted(VorpExport) then
            local res, err = awaitWithTimeout(function(cb)
                Core.Callback.TriggerAwait(callbackName, cb, table.unpack(args))
            end, 5000)
            if res ~= nil then return res, "nil" end
            lastErr = err
            debugPrint(("^6Bridge^7: ^3Callback^7 %s ^1failed^7 (Vorp) attempt %d: %s"):format(callbackName, attempts, tostring(err)))

        elseif isStarted(ESXExport) then
            local res, err = awaitWithTimeout(function(cb)
                ESX.TriggerServerCallback(callbackName, cb, table.unpack(args))
            end, 5000)
            if res ~= nil then return res, "nil" end
            lastErr = err
            debugPrint(("^6Bridge^7: ^3Callback^7 %s ^1failed^7 (ESX) attempt %d: %s"):format(callbackName, attempts, tostring(err)))

        else
            print("^6Bridge^7: ^1ERROR^7: ^3Can't find any script to trigger callback with^7:", callbackName)
            return nil, "no_framework"
        end

        Wait(10)
    until attempts > (1 + CALLBACK_RETRIES)

    return nil, lastErr or "timeout"
end
