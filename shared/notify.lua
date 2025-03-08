--[[
    Notifications Module
    ----------------------
    This module provides a unified interface for displaying notifications using various
    notification systems. The active system is determined by the Config.System.Notify setting.

    Supported systems include:
      • okok
      • qb
      • ox
      • gta (default)
      • esx
]]

--- Displays notifications to the player using the configured notification system.
---
--- Supports multiple notification systems based on Config.System.Notify. Can be triggered from both
--- client and server contexts.
---
--- @param title string|nil The notification title (optional for some systems).
--- @param message string The main message content.
--- @param type string The notification type ("success", "error", "info").
--- @param src number|nil Optional server ID; if provided, the notification is sent to that player.
---
--- @usage
--- ```lua
--- -- Client-side usage without specifying a player (shows to the current player)
--- triggerNotify("Success", "You have completed the task!", "success")
---
--- -- Server-side usage specifying a player by their server ID
--- triggerNotify("Alert", "You have been warned for misconduct.", "error", playerId)
--- ```
function triggerNotify(title, message, type, src)
    if Config.System.Notify == "okok" then
        if not src then
            TriggerEvent('okokNotify:Alert', title, message, 6000, type)
        else
            TriggerClientEvent('okokNotify:Alert', src, title, message, 6000, type)
        end
    elseif Config.System.Notify == "qb" then
        if not src then
            TriggerEvent("QBCore:Notify", message, type)
        else
            TriggerClientEvent("QBCore:Notify", src, message, type)
        end
    elseif Config.System.Notify == "ox" then
        if not src then
            TriggerEvent('ox_lib:notify', { title = title, description = message, type = type or "success" })
        else
            TriggerClientEvent('ox_lib:notify', src, { title = title, description = message, type = type or "success" })
        end
    elseif Config.System.Notify == "gta" then
        if not src then
            TriggerEvent(getScript()..":DisplayGTANotify", title, message)
        else
            TriggerClientEvent(getScript()..":DisplayGTANotify", src, title, message)
        end
    elseif Config.System.Notify == "esx" then
        if not src then
            exports["esx_notify"]:Notify(type, 4000, message)
        else
            TriggerClientEvent(getScript()..":DisplayESXNotify", src, type, message)
        end
    end
end

-------------------------------------------------------------
-- ESX Notifications
-------------------------------------------------------------

--- Registers a server-side event to display ESX notifications to clients.
---
--- Listens for DisplayESXNotify events and triggers the ESX notification on the client.
---
--- @param type string The notification type.
--- @param title string The notification title.
--- @param text string The notification message.
---
--- @usage
--- ```lua
--- TriggerClientEvent(getScript()..":DisplayESXNotify", playerId, "success", "New achievement unlocked!")
--- ```
RegisterNetEvent(getScript()..":DisplayESXNotify", function(type, text)
    exports["esx_notify"]:Notify(type, 4000, text)
end)

-------------------------------------------------------------
-- GTA-style Notifications
-------------------------------------------------------------

--- Displays GTA-style text notifications using native GTA functions.
---
--- Selects an appropriate icon based on the current script (if applicable) and renders the notification.
---
--- @param title string The notification title/identifier (used to select an icon).
--- @param text string The notification message.
---
--- @usage
--- ```lua
--- TriggerEvent(getScript()..":DisplayGTANotify", "taxiname", "Taxi service has arrived.")
--- ```
RegisterNetEvent(getScript()..":DisplayGTANotify", function(title, text)
    local iconTable = {}
    if getScript() == "jim-npcservice" then
        iconTable = {
            [Loc[Config.Lan].notify["taxiname"]] = "CHAR_TAXI",
            [Loc[Config.Lan].notify["limoname"]] = "CHAR_CASINO",
            [Loc[Config.Lan].notify["ambiname"]] = "CHAR_CALL911",
            [Loc[Config.Lan].notify["pilotname"]] = "CHAR_DEFAULT",
            [Loc[Config.Lan].notify["planename"]] = "CHAR_BOATSITE2",
            [Loc[Config.Lan].notify["heliname"]] = "CHAR_BOATSITE2",
        }
    end

    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringKeyboardDisplay(text)
    EndTextCommandThefeedPostMessagetext(
        iconTable[title] or "CHAR_DEFAULT",
        iconTable[title] or "CHAR_DEFAULT",
        true, 1, title, nil, text
    )
    EndTextCommandThefeedPostTicker(true, false)
end)