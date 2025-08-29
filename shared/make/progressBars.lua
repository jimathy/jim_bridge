local inProgress = false
local storedPID = nil


local progressFunc = {
    ox = {
        start = function(data)
            local options = {
                duration = debugMode and 1000 or data.time,
                label = data.label,
                position = data.position or "bottom",
                useWhileDead = data.dead or false,
                canCancel = data.cancel or true,
                anim = {
                    dict = data.dict,
                    clip = data.anim,
                    flag = (data.flag == 8 and 32 or data.flag) or nil,
                    scenario = data.task
                },
                disable = {
                    combat = data.combat or true,
                    move = data.disableMovement or false,
                    car = data.disableMovement or false,
                    mouse = data.mouse or false
                },
            }
            if data.prop and data.prop.model then
                options.prop = {
                    model = data.prop.model,
                    pos = data.prop.pos or vec3(0, 0, 0),
                    rot = data.prop.rot or vec3(0, 0, 0),
                    bone = data.prop.bone or 0
                }
            end
            if data.propTwo and data.propTwo.model then
                options.propTwo = {
                    model = data.propTwo.model,
                    pos = data.propTwo.pos or vec3(0, 0, 0),
                    rot = data.propTwo.rot or vec3(0, 0, 0),
                    bone = data.propTwo.bone or 0
                }
            end
            if data.progressType == "circle" then
                if exports[OXLibExport]:progressCircle(options) then
                    return true
                else
                    return false
                end
            end
            if not data.progressType or data.progressType == "bar" then
                if exports[OXLibExport]:progressBar(options) then
                    return true
                else
                    return false
                end
            end
        end,
        stop = function()
            exports[OXLibExport]:cancelProgress()
        end,
    },

    qb = {
        start = function(data)
            Core.Functions.Progressbar("progbar",
                data.label,
                debugMode and 1000 or data.time,
                data.dead or false,
                data.cancel or true,
                {
                    disableMovement = data.disableMovement or false,
                    disableCarMovement = data.disableMovement or false,
                    disableMouse = data.disableMouse or false,
                    disableCombat = data.disableCombat or true,
                },
                {
                    animDict = data.dict,
                    anim = data.anim,
                    flags = data.flag or 32,
                    task = data.task
                },
                {}, {},
                function()
                    return true
                end, function()
                    return false
                end, data.icon)
            end,
        stop = function()
            TriggerEvent("progressbar:client:cancel")
        end,
    },

    qs = {
        start = function(data)
            if exports['qs-interface']:ProgressBar({
                duration = debugMode and 1000 or data.time,
                label = data.label,
                position = 'bottom',
                useWhileDead = data.dead or false,
                canCancel = data.cancel or true,
                disable = data.disableMovement or false,
                anim = {
                    dict = data.dict,
                    clip = data.anim,
                    flag = data.flag or 32
                },
                prop = nil
            })  then
                return true
            else
                return false
            end
        end,
        stop = function()
            --??
            TriggerEvent("progressbar:client:cancel")
        end,
    },

    esx = {
        start = function(data)
            ESX.Progressbar(data.label, debugMode and 1000 or data.time, {
                FreezePlayer = true,
                animation = {
                    type = data.anim,
                    dict = data.dict,
                    scenario = data.task,
                },
                onFinish = function()
                    return true
                end,
                onCancel = function()
                    return false
                end
            })
        end,
        stop = function()
            ESX.CancelProgressbar()
        end,
    },

    lation = {
        start = function(data)
            if exports.lation_ui:progressBar({
                label = data.label,
                description = nil,
                duration = debugMode and 1000 or data.time,
                icon = data.icon,
                useWhileDead = data.dead or false,
                disable = {
                    combat = data.combat or true,
                    move = data.disableMovement or false,
                    car = data.disableMovement or false,
                },
                anim = {
                    dict = data.dict,
                    clip = data.anim,
                    flag = data.flag
                },
                prop = {
                    model = data.prop and data.prop.model,
                    pos = data.prop and (data.prop.pos or vec3(0, 0, 0)),
                    rot = data.prop and (data.prop.rot or vec3(0, 0, 0)),
                    bone = data.prop and (data.prop.bone or 0)
                }
            }) then
                return true
            else
                return false
            end
        end,
        stop = function()
            exports.lation_ui:cancelProgress()
        end,
    },

    red = {
        start = function(data)
            if exports.jim_bridge:redProgressBar({
                label = data.label,
                time = debugMode and 1000 or data.time,
                dict = data.dict,
                anim = data.anim,
                flag = data.flag or 32,
                task = data.task,
                disableMovement = data.disableMovement or false,
                cancel = data.cancel or true,
            }) then
                return true
            else
                return false
            end
        end,
        stop = function()
            exports.jim_bridge:stopProgressBar()
        end,
    },

    gta = {
        start = function(data)

            if exports.jim_bridge:gtaProgressBar({
                label = data.label,
                time = debugMode and 1000 or data.time,
                dict = data.dict,
                anim = data.anim,
                flag = data.flag or 32,
                task = data.task,
                disableMovement = data.disableMovement or false,
                cancel = data.cancel or true,
            }) then
                return true
            else
                return false
            end
        end,
        stop = function()
            exports.jim_bridge:stopProgressBar()
        end,
    },
}

--- Displays a progress bar using the configured progress bar system.
---
--- This function handles displaying a progress bar to the player using the specified progress bar system (e.g., ox, qb, esx, gta).
--- It supports shared progress bars between players, animations, camera effects, and more.
---
---@param data table A table containing the progress bar configuration.
--- - **label** (`string`): The text label to display on the progress bar.
--- - **time** (`number`): The duration of the progress bar in milliseconds.
--- - **dict** (`string`, optional): The animation dictionary to use.
--- - **anim** (`string`, optional): The animation name to play.
--- - **task** (`string`, optional): The task scenario to perform.
--- - **flag** (`number`, optional): The animation flag.
--- - **dead** (`boolean`, optional): Whether to allow the progress bar when the player is dead. Default is `false`.
--- - **cancel** (`boolean`, optional): Whether the progress bar can be canceled by the player. Default is `true`.
--- - **icon** (`string`, optional): The icon to display (for qb progress bar).
--- - **cam** (`number`, optional): The camera handle to use.
--- - **shared** (`table`, optional): Data for shared progress bars.
---   - **pid** (`number`): The player ID to share the progress bar with.
---   - **label** (`string`): The label to display on the shared progress bar.
---
--- @return boolean `true` if the progress bar completed successfully, or `false` if it was canceled.
---
---@usage
--- ```lua
--- local success = progressBar({
---     label = "Processing...",
---     time = 5000,
---     dict = "amb@world_human_hang_out_street@female_hold_arm@base",
---     anim = "base",
---     flag = 49,
---     cancel = true,
--- })
--- ```
function progressBar(data)
    local ped = PlayerPedId()
    if data.shared then
        debugPrint("^6Bridge^7: ^6Sharing progressBar to player^7: ^6"..data.shared.pid.."^7")
        storedPID = data.shared.pid
        TriggerServerEvent(getScript()..":server:sharedProg:Start", data)
    end
    local result = nil
    if data.cam then startTempCam(data.cam) end

    if progressFunc[Config.System.ProgressBar].start(data) then
        result = true
    else
        result = false
    end

    while result == nil do
        Wait(10)
    end
    debugPrint("^5Debug^7: ^2ProgressBar result^7: ^3"..tostring(result).."^7")

    -- Cleanup
    FreezeEntityPosition(ped, false)
    lockInv(false)
    if data.cam then
        stopTempCam(data.cam)
    end
    if result == false and data.shared then
        debugPrint("^6Bridge^7: ^2Sending cancel to ^6"..storedPID.."^7")
        TriggerServerEvent(getScript().."server:sharedProg:cancel", storedPID)
    end
    storedPID = nil
    if result == false then
        currentToken = nil
        TriggerServerEvent(getScript()..":clearAuthToken")
    end
    if result == true and data.request then
        TriggerServerEvent(getScript()..":clearAuthToken")
        currentToken = triggerCallback(AuthEvent)
    end
    return result
end

--- Stops the current progress bar.
---
--- This function cancels the progress bar based on the configured progress bar system, handling any necessary cleanup.
function stopProgressBar()
    progressFunc[Config.System.ProgressBar].stop()
end

-- System to handle sending/sharing progress bars between players --
-- For example, healing someone --


--- Server event handler for starting a shared progress bar.
--- This event is triggered when a player wants to start a progress bar on another player.
--- It adjusts the data to prevent loops and sends the data to the target client.
RegisterNetEvent(getScript()..":server:sharedProg:Start", function(data)
    local pid = data.shared.pid     -- Get player ID from the client
    data.label = data.shared.label  -- Set progress bar label to the shared label
    data.cancel = false             -- Make it so it can't be canceled
    data.dead = true                -- Allow progress bar even if player is dead
    data.shared = nil               -- Remove shared info to prevent loops
    data.anim = nil                 -- Remove animation so players don't share it
    debugPrint("^6Bridge^7: ^6"..source.." ^2is sending shared progressBar to player^7, ^6"..pid.."^7")
    TriggerClientEvent(getScript()..":client:sharedProg:Start", pid, data)
end)

--- Client event handler for starting a shared progress bar.
--- This event is triggered when the server wants the client to start a shared progress bar.
RegisterNetEvent(getScript()..":client:sharedProg:Start", function(data)
    debugPrint("^6Bridge^7: ^2You have been sent a progressBar^7")
    progressBar(data)
end)

--- Server event handler for canceling a shared progress bar.
--- This event is triggered when a progress bar is canceled and the server needs to notify the other player.
RegisterNetEvent(getScript()..":server:sharedProg:Cancel", function(pid)
    debugPrint("^6Bridge^7: ^2Sending cancel progressBar to ^6"..pid.."^7")
    TriggerClientEvent(getScript()..":client:sharedProg:Cancel", pid)
end)

--- Client event handler for canceling a shared progress bar.
--- This event is triggered when the server wants the client to cancel a shared progress bar.
RegisterNetEvent(getScript()..":client:sharedProg:Cancel", function()
    debugPrint("^6Bridge^7: ^2Receiving cancel progressBar^7")
    stopProgressBar()
end)